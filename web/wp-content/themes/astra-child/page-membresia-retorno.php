<?php
/**
 * Página de retorno tras registrar la tarjeta en Flow (customer/register →
 * url_return, ver inc/flow.php). NO asume éxito solo por haber vuelto de
 * Flow: el navegador suele volver antes de que termine de procesarse todo,
 * o la persona puede haber cerrado sin completar el registro. Acá se
 * confirma el estado real y, si corresponde, se crea la suscripción recién
 * en este momento (cdlr_flow_complete_signup en inc/flow.php).
 *
 * Muestra contenido distinto por visitante vía query string — por eso lleva
 * nocache_headers() y esta página debe quedar excluida de LiteSpeed Cache
 * (agregar /membresia-retorno/ a las URLs no-cacheadas al desplegar; ver
 * PROYECTO.md).
 */

nocache_headers();
if ( function_exists( 'do_action' ) ) {
	// Refuerza el nocache_headers() de arriba con el hook propio de
	// LiteSpeed Cache (el plugin activo en este sitio) — así queda excluida
	// aunque el nocache genérico de WP no baste para su configuración.
	do_action( 'litespeed_control_set_nocache', 'cdlr-membresia-retorno' );
}

// $_REQUEST (no $_GET): la documentación de Flow dice que el retorno del
// navegador se hace "mediante una llamada POST a la urlCallback pasando el
// token como parámetro" — no un GET con el token en la URL como se asumió
// al escribir esto originalmente. El "rt" propio sí sigue llegando siempre
// (es parte de la URL de "url_return" que nosotros mismos armamos, no algo
// que dependa del método HTTP), pero "token" solo llegaba si Flow lo
// mandaba por GET — nunca si lo manda por POST, que es el caso real. Bug
// real encontrado el 2026-08-18 con una prueba real (ver PROYECTO.md,
// sección 9.9): la página SIEMPRE mostraba "Algo no calzó" para cualquier
// socio, no solo si se reenviaba el formulario dos veces como se sospechaba
// antes. $_REQUEST cubre ambos casos sin tener que adivinar cuál usa Flow.
$return_token = isset( $_REQUEST['rt'] ) ? sanitize_text_field( wp_unslash( $_REQUEST['rt'] ) ) : '';
$flow_token   = isset( $_REQUEST['token'] ) ? sanitize_text_field( wp_unslash( $_REQUEST['token'] ) ) : '';

$result = cdlr_flow_complete_signup( $return_token, $flow_token );
$status = $result['status'];

get_header();
?>

<main id="cdlr-main" class="cdlr-home cdlr-membresia">

	<section class="cdlr-mem-hero">
		<div class="cdlr-container" data-reveal>

			<?php if ( 'activo' === $status ) : ?>
				<p class="cdlr-eyebrow">Membresía confirmada</p>
				<h1 class="cdlr-mem-hero__title">¡Listo! Tu membresía está <span>activa</span></h1>
				<p class="cdlr-hero__lead">Te mandamos un correo de confirmación. El cobro es automático cada mes a la tarjeta que registraste, a través de Flow.</p>

			<?php elseif ( 'rechazado' === $status ) : ?>
				<p class="cdlr-eyebrow">Hubo un problema</p>
				<h1 class="cdlr-mem-hero__title">El pago no se pudo <span>procesar</span></h1>
				<p class="cdlr-hero__lead">No alcanzamos a confirmar el registro de tu tarjeta. Puedes intentar de nuevo cuando quieras, sin ningún cobro de por medio.</p>
				<div class="cdlr-hero__actions">
					<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/membresia/#planes' ) ); ?>">Reintentar</a>
				</div>

			<?php elseif ( 'error' === $status ) : ?>
				<p class="cdlr-eyebrow">No encontramos tu postulación</p>
				<h1 class="cdlr-mem-hero__title">Algo no <span>calzó</span></h1>
				<p class="cdlr-hero__lead">Si veniste desde el pago de Flow y ves este mensaje, escríbenos a corporaciondelaraiz@gmail.com para revisarlo directamente.</p>
				<div class="cdlr-hero__actions">
					<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/membresia/#planes' ) ); ?>">Volver a Membresía</a>
				</div>

			<?php else : ?>
				<p class="cdlr-eyebrow">Un momento</p>
				<h1 class="cdlr-mem-hero__title">Estamos confirmando tu <span>pago</span></h1>
				<p class="cdlr-hero__lead">Puedes cerrar esta página tranquilamente: te vamos a avisar por correo apenas quede confirmado. No es necesario que reintentes.</p>

			<?php endif; ?>

		</div>
	</section>

</main>

<?php
get_footer();
