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
	// Cupones de descuento (agregado 2026-08-18) — mismo patrón que
	// cdlr_socio: sin UI en wp-admin, el cupón "real" vive en Flow
	// (/coupon/create); este CPT es solo la libreta que relaciona un código
	// legible (post_title) con el ID numérico que le asignó Flow, más los
	// contadores de uso que Flow no expone consultar directamente.
	register_post_type( 'cdlr_cupon', [
		'label'    => 'Cupones (Flow)',
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
 * Cupones de descuento (agregado 2026-08-18) — para que la directiva pueda
 * aportar con un % de descuento (hasta 100%, o sea $0 de cobro real) sin
 * dejar de pasar por el mismo flujo de Flow. Los cupones se crean desde el
 * panel admin de la app Flutter (ver cdlr_cupones_handle_crear() más
 * abajo), que llama acá mediante un endpoint autenticado con el ID token de
 * Firebase de quien esté logueado en /admin — nunca con un secreto suelto
 * en el código de la app.
 * ------------------------------------------------------------------ */

/**
 * Normaliza un código de cupón para comparar sin importar mayúsculas ni
 * espacios de más — mismo criterio en todos lados (creación, validación,
 * listado) para que "directorio2026" y "DIRECTORIO2026 " sean el mismo
 * cupón.
 */
function cdlr_flow_normalizar_codigo_cupon( $codigo ) {
	return strtoupper( trim( (string) $codigo ) );
}

function cdlr_flow_find_cupon_by_codigo( $codigo ) {
	$normalizado = cdlr_flow_normalizar_codigo_cupon( $codigo );
	if ( '' === $normalizado ) {
		return null;
	}
	$posts = get_posts( [
		'post_type'      => 'cdlr_cupon',
		'posts_per_page' => 1,
		'post_status'    => 'any',
		'meta_key'       => '_cdlr_codigo_normalizado',
		'meta_value'     => $normalizado,
	] );
	return $posts ? $posts[0] : null;
}

/**
 * Crea un cupón real en Flow (`/coupon/create`) y el post `cdlr_cupon` que
 * lo relaciona con un código legible. `$usos_maximos` = 0 significa sin
 * límite de usos (Flow no recibe ese parámetro en ese caso — se controla
 * enteramente de nuestro lado, ver cdlr_flow_validar_codigo_cupon()).
 *
 * @return array{post_id:int,flow_coupon_id:int}|WP_Error
 */
function cdlr_flow_crear_cupon( $codigo, $percent_off, $usos_maximos = 0, $expira = '' ) {
	$normalizado = cdlr_flow_normalizar_codigo_cupon( $codigo );
	if ( '' === $normalizado ) {
		return new WP_Error( 'cdlr_cupon_codigo', 'El código del cupón no puede estar vacío.' );
	}
	if ( cdlr_flow_find_cupon_by_codigo( $normalizado ) ) {
		return new WP_Error( 'cdlr_cupon_duplicado', 'Ya existe un cupón con ese código.' );
	}
	$percent_off = (float) $percent_off;
	if ( $percent_off <= 0 || $percent_off > 100 ) {
		return new WP_Error( 'cdlr_cupon_porcentaje', 'El porcentaje de descuento debe estar entre 1 y 100.' );
	}

	$params = [
		'name'     => $normalizado,
		// duration=0 (indefinido): el descuento aplica a todos los cobros
		// mientras la suscripción exista, no solo a los primeros N meses —
		// el caso de uso real (directores aportando gratis) es permanente,
		// no una promoción de lanzamiento.
		'duration' => 0,
	];
	if ( $percent_off === (float) (int) $percent_off ) {
		$params['percent_off'] = (int) $percent_off;
	} else {
		$params['percent_off'] = $percent_off;
	}
	if ( $usos_maximos > 0 ) {
		$params['max_redemptions'] = (int) $usos_maximos;
	}
	if ( $expira ) {
		$params['expires'] = $expira;
	}

	$result = cdlr_flow_request( 'POST', 'coupon/create', $params );
	if ( is_wp_error( $result ) || empty( $result['id'] ) ) {
		return is_wp_error( $result ) ? $result : new WP_Error( 'cdlr_cupon_flow', 'Flow no devolvió un ID de cupón.' );
	}

	$post_id = wp_insert_post( [
		'post_type'   => 'cdlr_cupon',
		'post_title'  => $normalizado,
		'post_status' => 'private',
	] );
	if ( is_wp_error( $post_id ) ) {
		return $post_id;
	}

	update_post_meta( $post_id, '_cdlr_codigo_normalizado', $normalizado );
	update_post_meta( $post_id, '_cdlr_flow_coupon_id', (int) $result['id'] );
	update_post_meta( $post_id, '_cdlr_descuento_pct', $percent_off );
	update_post_meta( $post_id, '_cdlr_usos_maximos', (int) $usos_maximos );
	update_post_meta( $post_id, '_cdlr_usos_actuales', 0 );
	update_post_meta( $post_id, '_cdlr_activo', 1 );
	update_post_meta( $post_id, '_cdlr_expira', $expira );

	return [ 'post_id' => $post_id, 'flow_coupon_id' => (int) $result['id'] ];
}

function cdlr_flow_cupon_a_array( $post ) {
	return [
		'id'            => $post->ID,
		'codigo'        => $post->post_title,
		'flowCouponId'  => (int) get_post_meta( $post->ID, '_cdlr_flow_coupon_id', true ),
		'descuentoPct'  => (float) get_post_meta( $post->ID, '_cdlr_descuento_pct', true ),
		'usosMaximos'   => (int) get_post_meta( $post->ID, '_cdlr_usos_maximos', true ),
		'usosActuales'  => (int) get_post_meta( $post->ID, '_cdlr_usos_actuales', true ),
		'activo'        => (bool) get_post_meta( $post->ID, '_cdlr_activo', true ),
		'expira'        => (string) get_post_meta( $post->ID, '_cdlr_expira', true ),
		'creadoEn'      => $post->post_date_gmt,
	];
}

function cdlr_flow_listar_cupones() {
	$posts = get_posts( [
		'post_type'      => 'cdlr_cupon',
		'posts_per_page' => -1,
		'post_status'    => 'any',
		'orderby'        => 'date',
		'order'          => 'DESC',
	] );
	return array_map( 'cdlr_flow_cupon_a_array', $posts );
}

/**
 * Prende/apaga un cupón de nuestro lado (no llama a Flow para
 * habilitar/deshabilitar el cupón allá — más simple, y suficiente: un
 * cupón "inactivo" acá nunca se le pasa a subscription/create, así que
 * nunca se usa aunque siga existiendo en Flow).
 */
function cdlr_flow_activar_cupon( $post_id, $activo ) {
	if ( 'cdlr_cupon' !== get_post_type( $post_id ) ) {
		return new WP_Error( 'cdlr_cupon_no_encontrado', 'Cupón no encontrado.' );
	}
	update_post_meta( $post_id, '_cdlr_activo', $activo ? 1 : 0 );
	return true;
}

/**
 * Elimina un cupón por completo (a diferencia de cdlr_flow_activar_cupon(),
 * que solo lo apaga). `coupon/delete` en Flow en la práctica solo lo marca
 * inactivo de su lado (status=0, confirmado probando contra producción
 * 2026-08-18) — no lo borra físicamente allá, pero no importa: nunca más se
 * le va a pasar ese couponId a subscription/create desde acá, y de nuestro
 * lado el post desaparece del todo (no queda ni desactivado en la lista).
 */
function cdlr_flow_eliminar_cupon( $post_id ) {
	if ( 'cdlr_cupon' !== get_post_type( $post_id ) ) {
		return new WP_Error( 'cdlr_cupon_no_encontrado', 'Cupón no encontrado.' );
	}
	$flow_coupon_id = (int) get_post_meta( $post_id, '_cdlr_flow_coupon_id', true );
	if ( $flow_coupon_id ) {
		$result = cdlr_flow_request( 'POST', 'coupon/delete', [ 'couponId' => $flow_coupon_id ] );
		if ( is_wp_error( $result ) ) {
			// No es fatal: aunque Flow no confirme la baja de su lado, seguimos
			// adelante y borramos el post — lo que importa de verdad es que
			// nunca más se use ese couponId desde este sitio.
			error_log( '[CDLR Flow] coupon/delete falló para cupón #' . $post_id . ' (Flow id ' . $flow_coupon_id . '): ' . $result->get_error_message() );
		}
	}
	wp_delete_post( $post_id, true );
	return true;
}

/**
 * Valida un código de cupón ingresado en /membresia/ — existe, está
 * activo, no expiró y no superó su máximo de usos.
 *
 * @return array{post_id:int,flow_coupon_id:int}|WP_Error
 */
function cdlr_flow_validar_codigo_cupon( $codigo ) {
	$post = cdlr_flow_find_cupon_by_codigo( $codigo );
	if ( ! $post ) {
		return new WP_Error( 'cdlr_cupon_invalido', 'Ese cupón no existe.' );
	}
	if ( ! (bool) get_post_meta( $post->ID, '_cdlr_activo', true ) ) {
		return new WP_Error( 'cdlr_cupon_inactivo', 'Ese cupón ya no está activo.' );
	}
	$expira = get_post_meta( $post->ID, '_cdlr_expira', true );
	if ( $expira && strtotime( $expira ) < time() ) {
		return new WP_Error( 'cdlr_cupon_expirado', 'Ese cupón ya expiró.' );
	}
	$usos_maximos  = (int) get_post_meta( $post->ID, '_cdlr_usos_maximos', true );
	$usos_actuales = (int) get_post_meta( $post->ID, '_cdlr_usos_actuales', true );
	if ( $usos_maximos > 0 && $usos_actuales >= $usos_maximos ) {
		return new WP_Error( 'cdlr_cupon_agotado', 'Ese cupón ya alcanzó su máximo de usos.' );
	}

	return [
		'post_id'        => $post->ID,
		'flow_coupon_id' => (int) get_post_meta( $post->ID, '_cdlr_flow_coupon_id', true ),
	];
}

/**
 * Se llama una sola vez que la suscripción queda "activo" de verdad (no en
 * cada intento) — ver cdlr_flow_complete_signup_for_socio().
 */
function cdlr_flow_incrementar_uso_cupon( $post_id ) {
	$actuales = (int) get_post_meta( $post_id, '_cdlr_usos_actuales', true );
	update_post_meta( $post_id, '_cdlr_usos_actuales', $actuales + 1 );
}


/* ---------------------------------------------------------------------
 * Monto personalizado (agregado 2026-08-18) — "otro monto" en /membresia/.
 * Los planes de Flow son de monto fijo, así que un aporte personalizado
 * necesita su propio Plan creado al vuelo (/plans/create) con el monto
 * exacto que la persona eligió, en vez de reusar amigo/colaborador/
 * embajador.
 * ------------------------------------------------------------------ */

/**
 * @return string|WP_Error El planId del plan recién creado.
 */
function cdlr_flow_crear_plan_monto_personalizado( $monto ) {
	$monto = (int) $monto;
	if ( $monto < 1000 ) {
		return new WP_Error( 'cdlr_monto_invalido', 'El monto mínimo de aporte es $1.000.' );
	}

	// planId único y sin espacios (lo exige Flow) — no hace falta guardarlo
	// en ningún otro lado más que en el propio socio (_cdlr_plan), este plan
	// es de un solo uso, no se reusa entre socios distintos.
	$plan_id = 'personalizado_' . time() . '_' . wp_generate_password( 6, false, false );

	$result = cdlr_flow_request( 'POST', 'plans/create', [
		'planId'   => $plan_id,
		'name'     => 'Aporte personalizado ($' . number_format( $monto, 0, ',', '.' ) . '/mes)',
		'amount'   => $monto,
		'interval' => 3, // mensual, igual que los 3 planes fijos
	] );

	if ( is_wp_error( $result ) || empty( $result['planId'] ) ) {
		return is_wp_error( $result ) ? $result : new WP_Error( 'cdlr_plan_flow', 'Flow no pudo crear el plan personalizado.' );
	}

	return $result['planId'];
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

	$name                 = isset( $_POST['cdlr_name'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_name'] ) ) : '';
	$email                = isset( $_POST['cdlr_email'] ) ? sanitize_email( wp_unslash( $_POST['cdlr_email'] ) ) : '';
	$plan_slug            = isset( $_POST['cdlr_plan'] ) ? sanitize_key( wp_unslash( $_POST['cdlr_plan'] ) ) : '';
	$monto_personalizado  = isset( $_POST['cdlr_monto_personalizado'] ) ? (int) $_POST['cdlr_monto_personalizado'] : 0;
	$cupon_codigo         = isset( $_POST['cdlr_cupon'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_cupon'] ) ) : '';
	$plans                = cdlr_flow_plans();
	$es_personalizado     = ( 'personalizado' === $plan_slug );

	if ( '' === $name || ! is_email( $email ) || ( ! $es_personalizado && ! isset( $plans[ $plan_slug ] ) ) ) {
		error_log( '[CDLR Flow][debug] Falló validación de campos. name=' . wp_json_encode( $name ) . ' email=' . wp_json_encode( $email ) . ' plan_slug=' . wp_json_encode( $plan_slug ) );
		$fail( 'Revisa tu nombre, tu email y el plan elegido.' );
		return;
	}
	if ( $es_personalizado && $monto_personalizado < 1000 ) {
		error_log( '[CDLR Flow][debug] Monto personalizado inválido: ' . wp_json_encode( $monto_personalizado ) );
		$fail( 'Ingresa un monto de al menos $1.000.' );
		return;
	}

	// El cupón se valida ANTES de tocar nada en Flow — así un código
	// inválido no deja a medio camino un cliente/plan creado por nada.
	$cupon = null;
	if ( '' !== $cupon_codigo ) {
		$cupon = cdlr_flow_validar_codigo_cupon( $cupon_codigo );
		if ( is_wp_error( $cupon ) ) {
			error_log( '[CDLR Flow][debug] Cupón inválido: ' . $cupon->get_error_message() );
			$fail( $cupon->get_error_message() );
			return;
		}
	}

	$customer = cdlr_flow_get_or_create_customer( $name, $email );
	if ( is_wp_error( $customer ) ) {
		error_log( '[CDLR Flow][debug] Falló get_or_create_customer: ' . $customer->get_error_message() );
		$fail( 'No pudimos conectar con Flow, intenta de nuevo en unos minutos.' );
		return;
	}

	if ( $es_personalizado ) {
		$plan_id_real = cdlr_flow_crear_plan_monto_personalizado( $monto_personalizado );
		if ( is_wp_error( $plan_id_real ) ) {
			error_log( '[CDLR Flow][debug] Falló crear_plan_monto_personalizado: ' . $plan_id_real->get_error_message() );
			$fail( 'No pudimos crear tu plan de aporte, intenta de nuevo en unos minutos.' );
			return;
		}
		update_post_meta( $customer['post_id'], '_cdlr_plan', $plan_id_real );
		update_post_meta( $customer['post_id'], '_cdlr_monto_personalizado', $monto_personalizado );
	} else {
		update_post_meta( $customer['post_id'], '_cdlr_plan', $plan_slug );
	}

	if ( $cupon ) {
		update_post_meta( $customer['post_id'], '_cdlr_cupon_post_id', $cupon['post_id'] );
		update_post_meta( $customer['post_id'], '_cdlr_flow_coupon_id', $cupon['flow_coupon_id'] );
	}

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
		cdlr_flow_sync_credencial_firestore( $socio->ID );
		return [ 'status' => 'rechazado', 'socio' => $socio ];
	}

	$plan_slug   = get_post_meta( $socio->ID, '_cdlr_plan', true );
	$customer_id = get_post_meta( $socio->ID, '_cdlr_flow_customer_id', true );
	$coupon_id   = (int) get_post_meta( $socio->ID, '_cdlr_flow_coupon_id', true );

	$subscription_params = [
		'planId'     => $plan_slug,
		'customerId' => $customer_id,
	];
	if ( $coupon_id ) {
		$subscription_params['couponId'] = $coupon_id;
	}

	$subscription = cdlr_flow_request( 'POST', 'subscription/create', $subscription_params );

	if ( is_wp_error( $subscription ) || empty( $subscription['subscriptionId'] ) ) {
		error_log( '[CDLR Flow] subscription/create falló (socio #' . $socio->ID . '): ' . wp_json_encode( $subscription ) );
		update_post_meta( $socio->ID, '_cdlr_status', 'rechazado' );
		cdlr_flow_sync_credencial_firestore( $socio->ID );
		return [ 'status' => 'rechazado', 'socio' => $socio ];
	}

	update_post_meta( $socio->ID, '_cdlr_status', 'activo' );
	update_post_meta( $socio->ID, '_cdlr_flow_subscription_id', $subscription['subscriptionId'] );
	if ( ! empty( $subscription['next_invoice_date'] ) ) {
		update_post_meta( $socio->ID, '_cdlr_next_charge_date', $subscription['next_invoice_date'] );
	}

	// El uso del cupón se cuenta acá (suscripción real ya creada en Flow),
	// no al validarlo en el formulario — si alguien escribe el código pero
	// nunca termina de pagar, no debería consumir un cupo del cupón.
	$cupon_post_id = (int) get_post_meta( $socio->ID, '_cdlr_cupon_post_id', true );
	if ( $cupon_post_id ) {
		cdlr_flow_incrementar_uso_cupon( $cupon_post_id );
	}

	cdlr_flow_send_confirmation_emails( $socio->ID );
	cdlr_flow_sync_credencial_firestore( $socio->ID );

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
	// get_post_field(), no get_the_title(): el CPT cdlr_socio se crea con
	// post_status = 'private' a propósito (sin UI en wp-admin), y
	// get_the_title() le antepone "Privado: " a los títulos de posts
	// privados fuera del admin — se coló en el asunto de este correo hasta
	// que se detectó el 2026-08-18 al probar la sincronización real a
	// Firestore (mismo bug, ver cdlr_flow_sync_credencial_firestore()).
	$name       = get_post_field( 'post_title', $socio_id );
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

	cdlr_flow_sync_credencial_firestore( $socio->ID );

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
		cdlr_flow_sync_credencial_firestore( $post->ID );
	}
}


/* ---------------------------------------------------------------------
 * Credencial digital del socio (agregado 2026-08-12) — sincroniza el
 * estado real de la membresía hacia Firestore, para que la app Flutter
 * pueda mostrarlo en tiempo real sin consultarle nada al sitio PHP
 * directamente. Este sitio sigue siendo la fuente de verdad; esto solo
 * empuja una copia de lectura hacia la colección `credenciales` (ver
 * `app/firebase/firestore.rules` y `app/lib/models/credencial_model.dart`
 * en el monorepo `delaraiz`).
 *
 * Requiere una cuenta de servicio de Firebase (Consola de Firebase >
 * Configuración del proyecto > Cuentas de servicio > Generar nueva clave
 * privada) — de ese JSON se sacan `client_email` y `private_key` para las
 * constantes `CDLR_FIREBASE_*` de wp-config.php. Mientras no existan, estas
 * funciones no hacen nada (no rompen el flujo de Flow, que ya funciona sin
 * esto) — no se pudo probar de punta a punta todavía porque el proyecto de
 * Firebase real recién se crea mañana (ver PROYECTO.md).
 * ------------------------------------------------------------------ */

/**
 * Codifica en base64url (sin padding) — variante que exige JWT, distinta
 * del base64 estándar de PHP.
 */
function cdlr_flow_base64url( $data ) {
	return rtrim( strtr( base64_encode( $data ), '+/', '-_' ), '=' );
}

/**
 * Consigue (y cachea ~55 minutos, vía transient) un token de acceso OAuth2
 * para la cuenta de servicio de Firebase. Sin librerías nuevas: se firma un
 * JWT a mano con `openssl_sign()` (nativo de PHP, mismo criterio que la
 * firma HMAC de Flow más arriba en este archivo) y se cambia por un token
 * en el endpoint de Google — flujo estándar "JWT Bearer" de OAuth2 para
 * cuentas de servicio.
 *
 * @return string|WP_Error
 */
function cdlr_flow_firebase_access_token() {
	$cached = get_transient( 'cdlr_firebase_access_token' );
	if ( $cached ) {
		return $cached;
	}

	$now    = time();
	$header = [ 'alg' => 'RS256', 'typ' => 'JWT' ];
	$claims = [
		'iss'   => CDLR_FIREBASE_CLIENT_EMAIL,
		'scope' => 'https://www.googleapis.com/auth/datastore',
		'aud'   => 'https://oauth2.googleapis.com/token',
		'iat'   => $now,
		'exp'   => $now + 3600,
	];

	$signing_input = cdlr_flow_base64url( wp_json_encode( $header ) ) . '.' . cdlr_flow_base64url( wp_json_encode( $claims ) );

	// La llave privada del JSON de Firebase trae saltos de línea reales,
	// pero si se pegó en wp-config.php como texto plano puede haber quedado
	// con "\n" literales (dos caracteres) en vez de saltos reales — se
	// normaliza acá para aceptar cualquiera de los dos formatos.
	$private_key_pem = str_replace( '\\n', "\n", CDLR_FIREBASE_PRIVATE_KEY );
	$private_key     = openssl_pkey_get_private( $private_key_pem );
	if ( ! $private_key ) {
		return new WP_Error( 'cdlr_firebase_key', 'No se pudo leer la llave privada de Firebase — revisar el formato en wp-config.php.' );
	}

	$signature = '';
	$firmado   = openssl_sign( $signing_input, $signature, $private_key, 'SHA256' );
	if ( ! $firmado ) {
		return new WP_Error( 'cdlr_firebase_sign', 'No se pudo firmar el JWT para Firebase.' );
	}

	$jwt = $signing_input . '.' . cdlr_flow_base64url( $signature );

	$response = wp_remote_post( 'https://oauth2.googleapis.com/token', [
		'body'    => [
			'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
			'assertion'  => $jwt,
		],
		'timeout' => 15,
	] );

	if ( is_wp_error( $response ) ) {
		return $response;
	}

	$body = json_decode( wp_remote_retrieve_body( $response ), true );
	if ( empty( $body['access_token'] ) ) {
		return new WP_Error( 'cdlr_firebase_token', 'Google no devolvió un access_token: ' . wp_remote_retrieve_body( $response ) );
	}

	// Se cachea un poco menos que su duración real (3600s) para no usarlo
	// justo cuando está por vencer.
	set_transient( 'cdlr_firebase_access_token', $body['access_token'], 3300 );

	return $body['access_token'];
}

/**
 * Escribe (crea o actualiza, "upsert") el documento `credenciales/{email}`
 * en Firestore con el estado actual del socio. Se llama cada vez que
 * cambia `_cdlr_status` — ver los 4 puntos donde se invoca más arriba en
 * este archivo (alta, webhook de cobro exitoso/fallido, y el cron de
 * reconciliación).
 */
function cdlr_flow_sync_credencial_firestore( $socio_id ) {
	if ( ! defined( 'CDLR_FIREBASE_PROJECT_ID' ) || ! defined( 'CDLR_FIREBASE_CLIENT_EMAIL' ) || ! defined( 'CDLR_FIREBASE_PRIVATE_KEY' ) ) {
		return; // Firebase todavía no está configurado — no es un error, solo no hay nada que sincronizar hacia allá por ahora.
	}

	$email = get_post_meta( $socio_id, '_cdlr_email', true );
	if ( ! is_email( $email ) ) {
		return;
	}
	$email = strtolower( trim( $email ) );

	$access_token = cdlr_flow_firebase_access_token();
	if ( is_wp_error( $access_token ) ) {
		error_log( '[CDLR Flow] No se pudo obtener token de acceso a Firebase: ' . $access_token->get_error_message() );
		return;
	}

	$plan_slug           = get_post_meta( $socio_id, '_cdlr_plan', true );
	$monto_personalizado = get_post_meta( $socio_id, '_cdlr_monto_personalizado', true );
	$estado              = get_post_meta( $socio_id, '_cdlr_status', true );
	$next_charge         = get_post_meta( $socio_id, '_cdlr_next_charge_date', true );

	// Los planes "otro monto" (agregado 2026-08-18) tienen un planId dinámico
	// del tipo "personalizado_<timestamp>_<random>" — ese string no significa
	// nada para la app Flutter (NivelMembresia solo conoce amigo/colaborador/
	// embajador, y caía silenciosamente a "Amigo" con $5.000 si se le mandaba
	// tal cual, un bug real encontrado el 2026-08-18 al ver el panel de
	// Socios). Se normaliza acá a un valor fijo "personalizado" + el monto
	// real por separado, para que la app lo muestre bien sin tener que
	// entender el formato del planId dinámico.
	$es_personalizado = str_starts_with( (string) $plan_slug, 'personalizado_' );

	$fields = [
		'email'         => [ 'stringValue' => $email ],
		// get_post_field(), no get_the_title() — ver el comentario en
		// cdlr_flow_send_confirmation_emails() más arriba.
		'nombre'        => [ 'stringValue' => get_post_field( 'post_title', $socio_id ) ],
		'plan'          => [ 'stringValue' => $es_personalizado ? 'personalizado' : $plan_slug ],
		'estado'        => [ 'stringValue' => $estado ],
		'actualizadoEn' => [ 'timestampValue' => gmdate( 'Y-m-d\TH:i:s\Z' ) ],
	];
	if ( $es_personalizado && $monto_personalizado ) {
		$fields['montoPersonalizado'] = [ 'integerValue' => (int) $monto_personalizado ];
	}
	if ( $next_charge ) {
		$fields['proximoCobro'] = [ 'timestampValue' => gmdate( 'Y-m-d\TH:i:s\Z', strtotime( $next_charge ) ) ];
	}

	// PATCH sobre la ruta del documento hace "upsert" (crea si no existe) en
	// la API REST de Firestore — no hace falta un paso aparte para crear.
	//
	// El query string de "updateMask.fieldPaths" se arma a mano (no con
	// add_query_arg() en un loop) — bug real encontrado el 2026-08-18 en la
	// primera prueba contra un Firestore de verdad: add_query_arg() re-parsea
	// la URL en cada llamada con wp_parse_str()/parse_str(), que sigue la
	// regla histórica de PHP de convertir los puntos de un nombre de
	// parámetro en guion bajo — el primer "updateMask.fieldPaths" quedaba
	// bien, pero al agregar el segundo campo el primero ya se había mutado a
	// "updateMask_fieldPaths", y Firestore rechazaba la URL entera (HTTP 400,
	// "Unknown name updateMask_fieldPaths"). Construir el query string en un
	// solo paso, sin re-parsearlo, evita el problema.
	$query_mask = implode( '&', array_map(
		fn( $campo ) => 'updateMask.fieldPaths=' . rawurlencode( $campo ),
		array_keys( $fields )
	) );
	$url = sprintf(
		'https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/credenciales/%s?%s',
		CDLR_FIREBASE_PROJECT_ID,
		rawurlencode( $email ),
		$query_mask
	);

	$response = wp_remote_request( $url, [
		'method'  => 'PATCH',
		'headers' => [
			'Authorization' => 'Bearer ' . $access_token,
			'Content-Type'  => 'application/json',
		],
		'body'    => wp_json_encode( [ 'fields' => $fields ] ),
		'timeout' => 15,
	] );

	if ( is_wp_error( $response ) ) {
		error_log( '[CDLR Flow] Error de red sincronizando credencial a Firestore (socio #' . $socio_id . '): ' . $response->get_error_message() );
		return;
	}
	$code = wp_remote_retrieve_response_code( $response );
	if ( $code >= 400 ) {
		error_log( '[CDLR Flow] Firestore devolvió error (HTTP ' . $code . ') sincronizando credencial (socio #' . $socio_id . '): ' . wp_remote_retrieve_body( $response ) );
	}
}


/* ---------------------------------------------------------------------
 * Panel admin de Cupones (app Flutter) — agregado 2026-08-18. Autenticado
 * con el ID token de Firebase de quien esté logueado en /admin (mismo
 * usuario que ya usa el resto del panel) — nunca con un secreto suelto
 * embebido en el código de la app, que sería trivial de extraer de un
 * bundle de Flutter web público.
 * ------------------------------------------------------------------ */

function cdlr_flow_base64url_decode( $data ) {
	$resto = strlen( $data ) % 4;
	if ( $resto ) {
		$data .= str_repeat( '=', 4 - $resto );
	}
	return base64_decode( strtr( $data, '-_', '+/' ) );
}

/**
 * Certificados públicos de Google para verificar tokens de Firebase Auth
 * (`securetoken@system.gserviceaccount.com`) — cacheados vía transient
 * (~1h) para no pedirlos en cada request.
 *
 * @return array|WP_Error Mapa kid => certificado PEM.
 */
function cdlr_flow_firebase_public_certs() {
	$cached = get_transient( 'cdlr_firebase_public_certs' );
	if ( $cached ) {
		return $cached;
	}
	$response = wp_remote_get( 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com', [ 'timeout' => 15 ] );
	if ( is_wp_error( $response ) ) {
		return $response;
	}
	$certs = json_decode( wp_remote_retrieve_body( $response ), true );
	if ( ! is_array( $certs ) || ! $certs ) {
		return new WP_Error( 'cdlr_certs', 'No se pudieron obtener los certificados públicos de Firebase.' );
	}
	set_transient( 'cdlr_firebase_public_certs', $certs, HOUR_IN_SECONDS );
	return $certs;
}

/**
 * Verifica que la petición actual traiga un ID token de Firebase válido de
 * un admin activo (mismo criterio que esAdminActivo() en firestore.rules
 * del lado Flutter). Devuelve el uid si es válido, o un WP_Error explicando
 * por qué no.
 *
 * El token viaja como parámetro del formulario (`id_token`), NO en el
 * header "Authorization" — se probó primero con el header, pero el
 * navegador exige mandar antes una petición OPTIONS de "preflight" en
 * cuanto hay un header custom como Authorization, y LiteSpeed en este
 * hosting bloquea OPTIONS con 403 a nivel de servidor (no llega ni a
 * ejecutar PHP) — confirmado el 2026-08-18 probando contra producción.
 * Mandarlo en el body evita el preflight por completo (POST +
 * application/x-www-form-urlencoded cuentan como "petición simple" para
 * CORS mientras no se agreguen headers custom).
 *
 * @return string|WP_Error
 */
function cdlr_flow_verificar_admin_request() {
	$id_token = isset( $_POST['id_token'] ) ? sanitize_text_field( wp_unslash( $_POST['id_token'] ) ) : '';
	if ( ! $id_token ) {
		return new WP_Error( 'cdlr_auth_falta', 'Falta el token de autenticación.' );
	}

	$partes = explode( '.', $id_token );
	if ( 3 !== count( $partes ) ) {
		return new WP_Error( 'cdlr_auth_formato', 'Token con formato inválido.' );
	}
	list( $header_b64, $payload_b64, $signature_b64 ) = $partes;

	$header    = json_decode( cdlr_flow_base64url_decode( $header_b64 ), true );
	$payload   = json_decode( cdlr_flow_base64url_decode( $payload_b64 ), true );
	$signature = cdlr_flow_base64url_decode( $signature_b64 );

	if ( ! is_array( $header ) || ! is_array( $payload ) || empty( $header['kid'] ) ) {
		return new WP_Error( 'cdlr_auth_formato', 'Token con formato inválido.' );
	}

	$certs = cdlr_flow_firebase_public_certs();
	if ( is_wp_error( $certs ) ) {
		return $certs;
	}
	if ( empty( $certs[ $header['kid'] ] ) ) {
		return new WP_Error( 'cdlr_auth_kid', 'Token firmado con una llave desconocida.' );
	}

	$public_key = openssl_pkey_get_public( $certs[ $header['kid'] ] );
	if ( ! $public_key ) {
		return new WP_Error( 'cdlr_auth_key', 'No se pudo leer el certificado público de Firebase.' );
	}

	$signing_input = $header_b64 . '.' . $payload_b64;
	$valido        = openssl_verify( $signing_input, $signature, $public_key, 'SHA256' );
	if ( 1 !== $valido ) {
		return new WP_Error( 'cdlr_auth_firma', 'La firma del token no es válida.' );
	}

	$ahora = time();
	if ( empty( $payload['exp'] ) || $payload['exp'] < $ahora ) {
		return new WP_Error( 'cdlr_auth_expirado', 'El token expiró, vuelve a iniciar sesión.' );
	}
	if ( empty( $payload['iat'] ) || $payload['iat'] > $ahora + 60 ) {
		return new WP_Error( 'cdlr_auth_iat', 'Token con fecha de emisión inválida.' );
	}
	if ( empty( $payload['aud'] ) || CDLR_FIREBASE_PROJECT_ID !== $payload['aud'] ) {
		return new WP_Error( 'cdlr_auth_aud', 'Token emitido para otro proyecto.' );
	}
	if ( empty( $payload['iss'] ) || 'https://securetoken.google.com/' . CDLR_FIREBASE_PROJECT_ID !== $payload['iss'] ) {
		return new WP_Error( 'cdlr_auth_iss', 'Token con emisor inválido.' );
	}
	if ( empty( $payload['sub'] ) ) {
		return new WP_Error( 'cdlr_auth_sub', 'Token sin usuario asociado.' );
	}
	$uid = $payload['sub'];

	// El token prueba que la persona inició sesión de verdad — falta
	// confirmar que además es un admin activo (mismo chequeo que hacen las
	// reglas de Firestore del lado de la app, pero desde el servidor: se usa
	// la cuenta de servicio, que no necesita pasar por esas reglas).
	$access_token = cdlr_flow_firebase_access_token();
	if ( is_wp_error( $access_token ) ) {
		return $access_token;
	}
	$doc_url = sprintf(
		'https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/usuarios/%s',
		CDLR_FIREBASE_PROJECT_ID,
		rawurlencode( $uid )
	);
	$doc_response = wp_remote_get( $doc_url, [
		'headers' => [ 'Authorization' => 'Bearer ' . $access_token ],
		'timeout' => 15,
	] );
	if ( is_wp_error( $doc_response ) ) {
		return $doc_response;
	}
	if ( 404 === wp_remote_retrieve_response_code( $doc_response ) ) {
		return new WP_Error( 'cdlr_auth_no_admin', 'Ese usuario no tiene perfil de admin.' );
	}
	$doc    = json_decode( wp_remote_retrieve_body( $doc_response ), true );
	$rol    = $doc['fields']['rol']['stringValue'] ?? '';
	$activo = $doc['fields']['activo']['booleanValue'] ?? false;
	if ( 'admin' !== $rol || ! $activo ) {
		return new WP_Error( 'cdlr_auth_no_admin', 'Ese usuario no es un admin activo.' );
	}

	return $uid;
}

/**
 * CORS: la app Flutter corre en un dominio distinto (Firebase Hosting), así
 * que el navegador exige este header antes de dejar leer la respuesta a JS.
 * Lista blanca explícita en vez de "*" por prolijidad, aunque estos
 * endpoints ya no aceptan credenciales de navegador (el token va en el
 * body, no en un header, justamente para no depender de un preflight
 * OPTIONS que este hosting bloquea — ver cdlr_flow_verificar_admin_request()).
 */
function cdlr_cupones_cors_headers() {
	$origenes_permitidos = [
		'https://delaraiz-app.web.app',
		'https://delaraiz-app.firebaseapp.com',
		'http://localhost:8765', // flutter run -d chrome, para probar en local
	];
	$origen = $_SERVER['HTTP_ORIGIN'] ?? '';
	if ( in_array( $origen, $origenes_permitidos, true ) ) {
		header( 'Access-Control-Allow-Origin: ' . $origen );
	}
	header( 'Access-Control-Allow-Methods: POST' );
	header( 'Vary: Origin' );
}

/**
 * Corre al principio de cada endpoint de este panel: pone el header CORS y
 * exige un admin real autenticado (corta con 401 si no lo es). El corte
 * corto para OPTIONS queda solo como red de seguridad — al no usar headers
 * custom, el navegador no debería mandar preflight para estas peticiones en
 * primer lugar, pero si algún día se agrega un header custom y vuelve a
 * dispararse, que responda 200 en vez de heredar el 401 de más abajo.
 *
 * @return string uid del admin, ya verificado.
 */
function cdlr_cupones_bootstrap() {
	cdlr_cupones_cors_headers();
	if ( 'OPTIONS' === ( $_SERVER['REQUEST_METHOD'] ?? '' ) ) {
		status_header( 200 );
		exit;
	}
	$auth = cdlr_flow_verificar_admin_request();
	if ( is_wp_error( $auth ) ) {
		wp_send_json_error( [ 'message' => $auth->get_error_message() ], 401 );
	}
	return $auth;
}

function cdlr_cupones_handle_listar() {
	cdlr_cupones_bootstrap();
	wp_send_json_success( cdlr_flow_listar_cupones() );
}
add_action( 'admin_post_cdlr_cupones_listar', 'cdlr_cupones_handle_listar' );
add_action( 'admin_post_nopriv_cdlr_cupones_listar', 'cdlr_cupones_handle_listar' );

function cdlr_cupones_handle_crear() {
	cdlr_cupones_bootstrap();

	$codigo       = isset( $_POST['codigo'] ) ? sanitize_text_field( wp_unslash( $_POST['codigo'] ) ) : '';
	$percent_off  = isset( $_POST['percentOff'] ) ? (float) $_POST['percentOff'] : 0;
	$usos_maximos = isset( $_POST['usosMaximos'] ) ? (int) $_POST['usosMaximos'] : 0;
	$expira       = isset( $_POST['expira'] ) ? sanitize_text_field( wp_unslash( $_POST['expira'] ) ) : '';

	$result = cdlr_flow_crear_cupon( $codigo, $percent_off, $usos_maximos, $expira );
	if ( is_wp_error( $result ) ) {
		wp_send_json_error( [ 'message' => $result->get_error_message() ], 400 );
	}
	wp_send_json_success( cdlr_flow_cupon_a_array( get_post( $result['post_id'] ) ) );
}
add_action( 'admin_post_cdlr_cupones_crear', 'cdlr_cupones_handle_crear' );
add_action( 'admin_post_nopriv_cdlr_cupones_crear', 'cdlr_cupones_handle_crear' );

function cdlr_cupones_handle_toggle() {
	cdlr_cupones_bootstrap();

	$post_id = isset( $_POST['id'] ) ? (int) $_POST['id'] : 0;
	$activo  = isset( $_POST['activo'] ) ? filter_var( wp_unslash( $_POST['activo'] ), FILTER_VALIDATE_BOOLEAN ) : false;

	$result = cdlr_flow_activar_cupon( $post_id, $activo );
	if ( is_wp_error( $result ) ) {
		wp_send_json_error( [ 'message' => $result->get_error_message() ], 400 );
	}
	wp_send_json_success( cdlr_flow_cupon_a_array( get_post( $post_id ) ) );
}
add_action( 'admin_post_cdlr_cupones_toggle', 'cdlr_cupones_handle_toggle' );
add_action( 'admin_post_nopriv_cdlr_cupones_toggle', 'cdlr_cupones_handle_toggle' );

function cdlr_cupones_handle_eliminar() {
	cdlr_cupones_bootstrap();

	$post_id = isset( $_POST['id'] ) ? (int) $_POST['id'] : 0;
	$result  = cdlr_flow_eliminar_cupon( $post_id );
	if ( is_wp_error( $result ) ) {
		wp_send_json_error( [ 'message' => $result->get_error_message() ], 400 );
	}
	wp_send_json_success( [ 'id' => $post_id ] );
}
add_action( 'admin_post_cdlr_cupones_eliminar', 'cdlr_cupones_handle_eliminar' );
add_action( 'admin_post_nopriv_cdlr_cupones_eliminar', 'cdlr_cupones_handle_eliminar' );
