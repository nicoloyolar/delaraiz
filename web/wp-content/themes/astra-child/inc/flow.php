<?php
/**
 * Integración con Flow.cl (pasarela de pago chilena) para el cobro
 * automático recurrente de las membresías de /membresia/. Reemplaza el
 * formulario que antes solo mandaba un correo — ver PROYECTO.md sección 5.1
 * (fuera del repo) para el contexto completo de por qué Flow y el estado de
 * la cuenta.
 *
 * Todo el código que mueve dinero real vive en este archivo aparte, para que
 * sea fácil de auditar solo. Sigue el mismo estilo 100% procedural del resto
 * del tema (sin clases) y reutiliza los mismos patrones de
 * nonce/honeypot/admin-post que cdlr_handle_band_application() en
 * functions.php.
 *
 * No hay panel propio de socios en wp-admin a propósito: el dashboard de
 * Flow ya muestra clientes/plan/estado/próximo cobro, así que el CPT de
 * abajo es solo la mínima "libreta de direcciones" para relacionar un socio
 * con su customerId/subscriptionId de Flow — no tiene interfaz de admin.
 *
 * Flujo completo:
 * 1. /membresia/ (cdlr_flow_handle_subscribe) crea/reusa el cliente en Flow
 *    y pide el link para registrar la tarjeta (customer/register).
 * 2. El socio registra su tarjeta en la página hospedada de Flow y vuelve a
 *    /membresia-retorno/ (cdlr_flow_complete_signup_for_socio): ahí se
 *    confirma el registro y se crea la suscripción real (subscription/create)
 *    — recién ahí queda "activo". No se asume éxito solo por haber vuelto.
 * 3. Los cobros de los meses siguientes los hace Flow solo, y notifica el
 *    resultado al "urlCallback" configurado en cada Plan (dashboard de
 *    Flow) — eso es cdlr_flow_handle_webhook().
 * 4. Un cron diario reintenta los registros que quedaron "pendiente" por
 *    más de 48h (alguien que cerró la pestaña de Flow sin terminar).
 */

// Si no hay credenciales configuradas (p. ej. un clon local sin secretos),
// no se registra nada de lo de abajo — falla de forma visible, no en
// silencio, porque esto mueve dinero real.
if ( ! defined( 'CDLR_FLOW_API_KEY' ) || ! defined( 'CDLR_FLOW_SECRET_KEY' ) || ! defined( 'CDLR_FLOW_WEBHOOK_KEY' ) ) {
	add_action( 'admin_notices', function () {
		echo '<div class="notice notice-error"><p><strong>Flow.cl:</strong> faltan las constantes CDLR_FLOW_API_KEY / CDLR_FLOW_SECRET_KEY / CDLR_FLOW_WEBHOOK_KEY en wp-config.php. La membresía con cobro automático está desactivada hasta que se agreguen.</p></div>';
	} );
	return;
}

if ( ! defined( 'CDLR_FLOW_API_BASE' ) ) {
	define( 'CDLR_FLOW_API_BASE', 'https://www.flow.cl/api' );
}

/**
 * Los 3 planes del sitio. El "slug" de cada uno es EXACTAMENTE el "ID" que
 * hay que usarle al crear el Plan en el dashboard de Flow (Suscripciones >
 * Planes) — Flow no genera un planId propio, lo elige el comercio al crear
 * el plan, así que no hace falta guardar un mapeo en constantes aparte.
 */
function cdlr_flow_plans() {
	return [
		'amigo'       => [ 'label' => 'Amigo ($5.000/mes)', 'amount' => 5000 ],
		'colaborador' => [ 'label' => 'Colaborador ($10.000/mes)', 'amount' => 10000 ],
		'embajador'   => [ 'label' => 'Embajador ($15.000/mes)', 'amount' => 15000 ],
	];
}

/**
 * URL del webhook que hay que pegar en el campo "urlCallback" al crear cada
 * uno de los 3 planes en el dashboard de Flow — la misma para los 3.
 */
function cdlr_flow_webhook_url() {
	return add_query_arg( [
		'action' => 'cdlr_flow_webhook',
		'k'      => CDLR_FLOW_WEBHOOK_KEY,
	], admin_url( 'admin-post.php' ) );
}


/* ---------------------------------------------------------------------
 * Cliente HTTP + firma. Sin librerías nuevas: wp_remote_post/get de WP
 * core y hash_hmac() nativo de PHP alcanzan.
 * ------------------------------------------------------------------ */

/**
 * Firma de parámetros de Flow: se ordenan alfabéticamente por nombre
 * (excluyendo "s"), se concatenan como nombre+valor sin separadores, y se
 * les aplica HMAC-SHA256 con el secretKey del comercio.
 */
function cdlr_flow_sign( array $params ) {
	unset( $params['s'] );
	ksort( $params );

	$concat = '';
	foreach ( $params as $key => $value ) {
		$concat .= $key . $value;
	}

	return hash_hmac( 'sha256', $concat, CDLR_FLOW_SECRET_KEY );
}

/**
 * Llama a un recurso de la API de Flow ya firmado. Devuelve el body
 * decodificado (array) o un WP_Error si falló la red o Flow respondió con
 * un error.
 */
function cdlr_flow_request( $method, $path, array $params = [] ) {
	$params['apiKey'] = CDLR_FLOW_API_KEY;
	$params['s']      = cdlr_flow_sign( $params );

	$url  = trailingslashit( CDLR_FLOW_API_BASE ) . ltrim( $path, '/' );
	$args = [ 'timeout' => 20 ];

	if ( 'GET' === $method ) {
		$response = wp_remote_get( add_query_arg( $params, $url ), $args );
	} else {
		$args['body'] = $params;
		$response     = wp_remote_post( $url, $args );
	}

	if ( is_wp_error( $response ) ) {
		error_log( '[CDLR Flow] Error de red llamando a ' . $path . ': ' . $response->get_error_message() );
		return $response;
	}

	$code = wp_remote_retrieve_response_code( $response );
	$body = json_decode( wp_remote_retrieve_body( $response ), true );

	if ( $code >= 400 || ( is_array( $body ) && isset( $body['code'] ) ) ) {
		$message = ( is_array( $body ) && isset( $body['message'] ) ) ? $body['message'] : 'Error desconocido de Flow';
		error_log( sprintf( '[CDLR Flow] %s devolvió error (HTTP %d): %s — respuesta completa: %s', $path, $code, $message, wp_remote_retrieve_body( $response ) ) );
		return new WP_Error( 'cdlr_flow_api', $message, $body );
	}

	return $body;
}


/* ---------------------------------------------------------------------
 * CPT cdlr_socio — sin UI propia (ver nota al tope del archivo). Solo
 * relaciona un socio con sus IDs de Flow.
 * ------------------------------------------------------------------ */

add_action( 'init', function () {
	register_post_type( 'cdlr_socio', [
		'label'    => 'Socios (Flow)',
		'public'   => false,
		'show_ui'  => false,
		'supports' => [ 'title' ],
	] );
} );

function cdlr_flow_find_socio( $meta_key, $meta_value ) {
	if ( '' === (string) $meta_value ) {
		return null;
	}
	$posts = get_posts( [
		'post_type'      => 'cdlr_socio',
		'posts_per_page' => 1,
		'post_status'    => 'any',
		'meta_key'       => $meta_key,
		'meta_value'     => $meta_value,
	] );
	return $posts ? $posts[0] : null;
}

function cdlr_flow_find_socio_by_email( $email ) {
	return cdlr_flow_find_socio( '_cdlr_email', $email );
}


/* ---------------------------------------------------------------------
 * Paso 1: crear/reusar cliente en Flow y pedir el link para registrar la
 * tarjeta.
 * ------------------------------------------------------------------ */

/**
 * Busca un socio existente por email; si ya tiene customerId de Flow, lo
 * reusa (evita crear un cliente duplicado si alguien vuelve a postular con
 * el mismo correo). Si no existe, crea el cliente en Flow y el post
 * cdlr_socio correspondiente.
 *
 * @return array{post_id:int,customer_id:string}|WP_Error
 */
function cdlr_flow_get_or_create_customer( $name, $email ) {
	$existing    = cdlr_flow_find_socio_by_email( $email );
	$customer_id = $existing ? get_post_meta( $existing->ID, '_cdlr_flow_customer_id', true ) : '';

	if ( $existing && $customer_id ) {
		return [ 'post_id' => $existing->ID, 'customer_id' => $customer_id ];
	}

	$result = cdlr_flow_request( 'POST', 'customer/create', [
		'name'       => $name,
		'email'      => $email,
		'externalId' => 'cdlr-' . md5( $email ),
	] );

	if ( is_wp_error( $result ) || empty( $result['customerId'] ) ) {
		return is_wp_error( $result ) ? $result : new WP_Error( 'cdlr_flow_customer', 'Flow no devolvió un customerId.' );
	}

	$post_id = $existing ? $existing->ID : wp_insert_post( [
		'post_type'   => 'cdlr_socio',
		'post_title'  => $name,
		'post_status' => 'private',
	] );

	update_post_meta( $post_id, '_cdlr_email', $email );
	update_post_meta( $post_id, '_cdlr_flow_customer_id', $result['customerId'] );
	update_post_meta( $post_id, '_cdlr_status', 'pendiente' );

	return [ 'post_id' => $post_id, 'customer_id' => $result['customerId'] ];
}

/**
 * Handler de /membresia/: valida el formulario, crea/reusa el cliente en
 * Flow y redirige a la página de Flow para registrar la tarjeta. Mismo
 * esqueleto (nonce dedicado + honeypot + $fail) que
 * cdlr_handle_band_application() en functions.php.
 */
function cdlr_flow_handle_subscribe() {
	$fail = function ( $message ) {
		wp_safe_redirect( add_query_arg( 'cdlr_status', 'error', home_url( '/membresia/#postula' ) ) );
		exit;
	};

	// TEMPORAL (2026-08-04): logging de diagnóstico para la primera prueba
	// real del equipo directivo — se sacó un intento y dio error sin nada en
	// el log (los checks de abajo no logueaban nada antes). Quitar estas
	// líneas de error_log una vez confirmado el flujo completo.
	if ( ! isset( $_POST['cdlr_flow_nonce'] ) || ! wp_verify_nonce( $_POST['cdlr_flow_nonce'], 'cdlr_flow_subscribe' ) ) {
		error_log( '[CDLR Flow][debug] Falló el nonce. Recibido: ' . wp_json_encode( $_POST['cdlr_flow_nonce'] ?? null ) );
		$fail( 'No pudimos validar el formulario, intenta de nuevo.' );
		return;
	}

	// Honeypot: los bots suelen completar todos los campos, incluido este, que está oculto para personas.
	if ( ! empty( $_POST['cdlr_website'] ) ) {
		error_log( '[CDLR Flow][debug] Honeypot disparado. Valor: ' . wp_json_encode( $_POST['cdlr_website'] ) );
		$fail( 'No se pudo procesar la postulación.' );
		return;
	}

	$name      = isset( $_POST['cdlr_name'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_name'] ) ) : '';
	$email     = isset( $_POST['cdlr_email'] ) ? sanitize_email( wp_unslash( $_POST['cdlr_email'] ) ) : '';
	$plan_slug = isset( $_POST['cdlr_plan'] ) ? sanitize_key( wp_unslash( $_POST['cdlr_plan'] ) ) : '';
	$plans     = cdlr_flow_plans();

	if ( '' === $name || ! is_email( $email ) || ! isset( $plans[ $plan_slug ] ) ) {
		error_log( '[CDLR Flow][debug] Falló validación de campos. name=' . wp_json_encode( $name ) . ' email=' . wp_json_encode( $email ) . ' plan_slug=' . wp_json_encode( $plan_slug ) );
		$fail( 'Revisa tu nombre, tu email y el plan elegido.' );
		return;
	}

	$customer = cdlr_flow_get_or_create_customer( $name, $email );
	if ( is_wp_error( $customer ) ) {
		error_log( '[CDLR Flow][debug] Falló get_or_create_customer: ' . $customer->get_error_message() );
		$fail( 'No pudimos conectar con Flow, intenta de nuevo en unos minutos.' );
		return;
	}

	update_post_meta( $customer['post_id'], '_cdlr_plan', $plan_slug );

	// Token propio para identificar al socio en la página de retorno sin
	// exponer el post ID (evita enumeración trivial de estados ajenos).
	$return_token = wp_generate_password( 32, false );
	update_post_meta( $customer['post_id'], '_cdlr_return_token', $return_token );

	$register = cdlr_flow_request( 'POST', 'customer/register', [
		'customerId' => $customer['customer_id'],
		'url_return' => home_url( '/membresia-retorno/?rt=' . $return_token ),
	] );

	if ( is_wp_error( $register ) || empty( $register['url'] ) || empty( $register['token'] ) ) {
		error_log( '[CDLR Flow][debug] customer/register no devolvió url/token. Respuesta: ' . wp_json_encode( $register ) );
		$fail( 'No pudimos iniciar el pago con Flow, intenta de nuevo en unos minutos.' );
		return;
	}

	// Se guarda el token de registro de Flow para poder reconsultar el
	// estado más tarde si el socio nunca vuelve a /membresia-retorno/ (ver
	// cdlr_flow_reconcile_pending).
	update_post_meta( $customer['post_id'], '_cdlr_flow_register_token', $register['token'] );

	wp_redirect( $register['url'] . '?token=' . $register['token'] );
	exit;
}
add_action( 'admin_post_cdlr_flow_subscribe', 'cdlr_flow_handle_subscribe' );
add_action( 'admin_post_nopriv_cdlr_flow_subscribe', 'cdlr_flow_handle_subscribe' );


/* ---------------------------------------------------------------------
 * Paso 2: confirmar el registro de tarjeta y crear la suscripción real.
 * Se llama desde page-membresia-retorno.php (retorno del navegador) y
 * también desde el cron de reconciliación (si el socio nunca volvió).
 * ------------------------------------------------------------------ */

/**
 * Heurística para saber si customer/getRegisterStatus indica que la
 * tarjeta quedó registrada. La documentación pública de Flow no detalla el
 * nombre exacto del campo de estado para este endpoint en particular —
 * este es el único lugar a ajustar si la respuesta real trae otra forma
 * (se loguea la respuesta completa en cdlr_flow_complete_signup_for_socio
 * para poder confirmarlo con un caso real).
 */
function cdlr_flow_card_registered( $response ) {
	if ( ! is_array( $response ) ) {
		return false;
	}
	if ( isset( $response['status'] ) && in_array( (int) $response['status'], [ 1, 2 ], true ) ) {
		return true;
	}
	return ! empty( $response['creditCardType'] ) || ! empty( $response['last4'] ) || ! empty( $response['cardNumber'] );
}

/**
 * @return array{status:string,socio:?WP_Post}
 */
function cdlr_flow_complete_signup_for_socio( $socio, $flow_token ) {
	if ( ! $socio || ! $flow_token ) {
		return [ 'status' => 'error', 'socio' => null ];
	}

	$status = get_post_meta( $socio->ID, '_cdlr_status', true );

	// Ya se procesó antes (ej. recargar la página de retorno, o el cron lo
	// alcanzó primero) — no se vuelve a llamar a subscription/create ni a
	// mandar los correos de nuevo.
	if ( in_array( $status, [ 'activo', 'rechazado' ], true ) ) {
		return [ 'status' => $status, 'socio' => $socio ];
	}

	$register_status = cdlr_flow_request( 'GET', 'customer/getRegisterStatus', [ 'token' => $flow_token ] );
	error_log( '[CDLR Flow] customer/getRegisterStatus (socio #' . $socio->ID . '): ' . wp_json_encode( $register_status ) );

	if ( is_wp_error( $register_status ) || ! cdlr_flow_card_registered( $register_status ) ) {
		update_post_meta( $socio->ID, '_cdlr_status', 'rechazado' );
		return [ 'status' => 'rechazado', 'socio' => $socio ];
	}

	$plan_slug   = get_post_meta( $socio->ID, '_cdlr_plan', true );
	$customer_id = get_post_meta( $socio->ID, '_cdlr_flow_customer_id', true );

	$subscription = cdlr_flow_request( 'POST', 'subscription/create', [
		'planId'     => $plan_slug,
		'customerId' => $customer_id,
	] );

	if ( is_wp_error( $subscription ) || empty( $subscription['subscriptionId'] ) ) {
		error_log( '[CDLR Flow] subscription/create falló (socio #' . $socio->ID . '): ' . wp_json_encode( $subscription ) );
		update_post_meta( $socio->ID, '_cdlr_status', 'rechazado' );
		return [ 'status' => 'rechazado', 'socio' => $socio ];
	}

	update_post_meta( $socio->ID, '_cdlr_status', 'activo' );
	update_post_meta( $socio->ID, '_cdlr_flow_subscription_id', $subscription['subscriptionId'] );
	if ( ! empty( $subscription['next_invoice_date'] ) ) {
		update_post_meta( $socio->ID, '_cdlr_next_charge_date', $subscription['next_invoice_date'] );
	}

	cdlr_flow_send_confirmation_emails( $socio->ID );

	return [ 'status' => 'activo', 'socio' => $socio ];
}

/**
 * Usado por page-membresia-retorno.php: busca al socio por su token propio
 * (no el de Flow) y delega en cdlr_flow_complete_signup_for_socio().
 */
function cdlr_flow_complete_signup( $return_token, $flow_token ) {
	if ( ! $return_token || ! $flow_token ) {
		return [ 'status' => 'error', 'socio' => null ];
	}
	$socio = cdlr_flow_find_socio( '_cdlr_return_token', $return_token );
	if ( ! $socio ) {
		return [ 'status' => 'error', 'socio' => null ];
	}
	return cdlr_flow_complete_signup_for_socio( $socio, $flow_token );
}

function cdlr_flow_send_confirmation_emails( $socio_id ) {
	$name       = get_the_title( $socio_id );
	$email      = get_post_meta( $socio_id, '_cdlr_email', true );
	$plans      = cdlr_flow_plans();
	$plan_slug  = get_post_meta( $socio_id, '_cdlr_plan', true );
	$plan_label = isset( $plans[ $plan_slug ] ) ? $plans[ $plan_slug ]['label'] : $plan_slug;

	wp_mail(
		'corporaciondelaraiz@gmail.com',
		sprintf( 'Nueva membresía activa – %s (%s)', $name, $plan_label ),
		sprintf( "Nombre: %s\nEmail: %s\nPlan: %s\n", $name, $email, $plan_label ),
		[ 'Content-Type: text/plain; charset=UTF-8' ]
	);

	wp_mail(
		$email,
		'¡Tu membresía está activa! – Corporación de la Raíz',
		sprintf(
			"¡Hola %s!\n\nTu membresía %s ya está activa. El cobro es automático cada mes a la tarjeta que registraste, a través de Flow.\n\nSi necesitas cancelar o cambiar de plan, escríbenos a corporaciondelaraiz@gmail.com.\n\nGracias por sumarte,\nCorporación de la Raíz",
			$name,
			$plan_label
		),
		[ 'Content-Type: text/plain; charset=UTF-8' ]
	);
}


/* ---------------------------------------------------------------------
 * Paso 3: webhook de Flow para los cobros de los meses siguientes
 * (urlCallback configurado en cada Plan del dashboard).
 * ------------------------------------------------------------------ */

function cdlr_flow_handle_webhook() {
	// Filtro barato de ruido (bots/escaneos) — NO es la autenticación real.
	// La autenticación real es volver a preguntarle a la API de Flow con
	// nuestras propias credenciales en vez de confiar en el body entrante.
	if ( ! isset( $_REQUEST['k'] ) || ! hash_equals( CDLR_FLOW_WEBHOOK_KEY, (string) $_REQUEST['k'] ) ) {
		status_header( 404 );
		exit;
	}

	// La documentación pública de Flow no detalla el payload exacto que
	// manda a "urlCallback" — se registra todo lo recibido para poder
	// confirmarlo con la primera notificación real y ajustar rápido si
	// hace falta (ver nota en PROYECTO.md).
	error_log( '[CDLR Flow] Webhook recibido: ' . wp_json_encode( $_REQUEST ) );

	$token            = isset( $_REQUEST['token'] ) ? sanitize_text_field( wp_unslash( $_REQUEST['token'] ) ) : '';
	$subscription_id  = isset( $_REQUEST['subscriptionId'] ) ? sanitize_text_field( wp_unslash( $_REQUEST['subscriptionId'] ) ) : '';
	$status_response  = null;

	if ( $token ) {
		$status_response = cdlr_flow_request( 'GET', 'payment/getStatus', [ 'token' => $token ] );
	} elseif ( $subscription_id ) {
		$status_response = cdlr_flow_request( 'GET', 'subscription/get', [ 'subscriptionId' => $subscription_id ] );
	}

	if ( is_wp_error( $status_response ) || ! is_array( $status_response ) ) {
		error_log( '[CDLR Flow] Webhook: no se pudo confirmar el estado autoritativo. Payload recibido: ' . wp_json_encode( $_REQUEST ) );
		status_header( 200 ); // Se responde 200 igual: un error acá dispara reintentos de Flow, y esto puede ser un problema transitorio de nuestro lado.
		exit;
	}

	$resolved_subscription_id = $subscription_id ?: ( $status_response['subscriptionId'] ?? '' );
	$socio                    = $resolved_subscription_id ? cdlr_flow_find_socio( '_cdlr_flow_subscription_id', $resolved_subscription_id ) : null;

	if ( ! $socio ) {
		error_log( '[CDLR Flow] Webhook: no se encontró socio para subscriptionId=' . $resolved_subscription_id );
		// Es dinero real cambiando de manos sin que el sitio se entere — no
		// puede perderse en silencio, se avisa además del error_log.
		wp_mail(
			'corporaciondelaraiz@gmail.com',
			'⚠️ Webhook de Flow sin socio asociado',
			'Llegó una notificación de Flow que no se pudo asociar a ningún socio registrado en el sitio. Revisar error_log del servidor. Payload: ' . wp_json_encode( $_REQUEST ),
			[ 'Content-Type: text/plain; charset=UTF-8' ]
		);
		status_header( 200 );
		exit;
	}

	// Idempotencia: Flow puede reintentar la entrega del mismo evento aunque
	// ya se haya procesado con éxito.
	$event_id   = $token ?: wp_json_encode( $status_response );
	$last_event = get_post_meta( $socio->ID, '_cdlr_last_charge_token', true );
	if ( $last_event === $event_id ) {
		status_header( 200 );
		exit;
	}
	update_post_meta( $socio->ID, '_cdlr_last_charge_token', $event_id );

	// Convención habitual de Flow para el campo "status": 2 = pagado.
	$paid = isset( $status_response['status'] ) && 2 === (int) $status_response['status'];

	if ( $paid ) {
		update_post_meta( $socio->ID, '_cdlr_status', 'activo' );
		update_post_meta( $socio->ID, '_cdlr_failed_charges', 0 );
	} else {
		update_post_meta( $socio->ID, '_cdlr_status', 'moroso' );
		update_post_meta( $socio->ID, '_cdlr_failed_charges', 1 + (int) get_post_meta( $socio->ID, '_cdlr_failed_charges', true ) );

		$email = get_post_meta( $socio->ID, '_cdlr_email', true );
		if ( is_email( $email ) ) {
			wp_mail(
				$email,
				'No pudimos procesar tu cobro mensual – Corporación de la Raíz',
				"Hola,\n\nNo pudimos procesar el cobro automático de tu membresía este mes. Flow va a reintentar automáticamente en los próximos días — si el problema persiste, escríbenos a corporaciondelaraiz@gmail.com para actualizar tu medio de pago.\n\nGracias,\nCorporación de la Raíz",
				[ 'Content-Type: text/plain; charset=UTF-8' ]
			);
		}
	}

	status_header( 200 );
	exit;
}
add_action( 'admin_post_cdlr_flow_webhook', 'cdlr_flow_handle_webhook' );
add_action( 'admin_post_nopriv_cdlr_flow_webhook', 'cdlr_flow_handle_webhook' );


/* ---------------------------------------------------------------------
 * Cron: recupera registros que quedaron "pendiente" (el socio cerró la
 * pestaña de Flow sin terminar, o el retorno al navegador nunca llegó).
 * ------------------------------------------------------------------ */

add_action( 'wp', function () {
	if ( ! wp_next_scheduled( 'cdlr_flow_reconcile_pending_event' ) ) {
		wp_schedule_event( time(), 'daily', 'cdlr_flow_reconcile_pending_event' );
	}
} );

add_action( 'cdlr_flow_reconcile_pending_event', 'cdlr_flow_reconcile_pending' );

function cdlr_flow_reconcile_pending() {
	$posts = get_posts( [
		'post_type'      => 'cdlr_socio',
		'posts_per_page' => -1,
		'post_status'    => 'any',
		'meta_key'       => '_cdlr_status',
		'meta_value'     => 'pendiente',
		'date_query'     => [ [ 'before' => '48 hours ago' ] ],
	] );

	foreach ( $posts as $post ) {
		$flow_token = get_post_meta( $post->ID, '_cdlr_flow_register_token', true );

		if ( $flow_token ) {
			$result = cdlr_flow_complete_signup_for_socio( $post, $flow_token );
			if ( 'activo' === $result['status'] ) {
				continue; // Sí había registrado la tarjeta, solo no volvió a la página de retorno — recuperado.
			}
		}

		// Después de 48h sin completar el registro, lo más probable es que
		// la persona no haya terminado — se marca cancelado para no dejarlo
		// flotando como "pendiente" para siempre.
		update_post_meta( $post->ID, '_cdlr_status', 'cancelado' );
	}
}
