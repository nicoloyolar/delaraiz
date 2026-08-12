<?php
/**
 * Prácticas profesionales — página propia, código 100% a medida (mismo
 * patrón que page-membresia.php). Reutiliza las clases de tarjeta de
 * membresia.css (.cdlr-plan*) para las áreas de práctica, y el mismo
 * backend de formulario (cdlr_handle_contact_form), generalizado para
 * aceptar un asunto/etiqueta distintos a "membresía".
 *
 * Excluida del caché de página (LiteSpeed), mismo motivo que
 * page-membresia.php: el formulario lleva un nonce embebido que vence y, si
 * la página queda cacheada más tiempo que eso, el formulario falla siempre
 * sin importar los datos (ver PROYECTO.md, bug real encontrado 2026-08-06 en
 * Membresía). Tráfico bajo, así que el costo de no cachearla es mínimo.
 */
nocache_headers();
if ( function_exists( 'do_action' ) ) {
	do_action( 'litespeed_control_set_nocache', 'cdlr-practicas-form-nonce' );
}

get_header();

$status = isset( $_GET['cdlr_status'] ) ? sanitize_key( wp_unslash( $_GET['cdlr_status'] ) ) : '';
?>

<main id="cdlr-main" class="cdlr-home cdlr-practicas">

	<section class="cdlr-mem-hero">
		<div class="cdlr-container" data-reveal>
			<p class="cdlr-eyebrow">Súmate al equipo</p>
			<h1 class="cdlr-mem-hero__title">Practica con <span>nosotros</span></h1>
			<p class="cdlr-hero__lead">Recibimos alumnos en práctica de sonido y producción audiovisual, además de apoyo general a la gestión de la Corporación, durante todo el año.</p>
			<div class="cdlr-hero__actions">
				<a class="cdlr-btn cdlr-btn--primary" href="#areas">Ver áreas disponibles</a>
			</div>
		</div>
	</section>

	<section class="cdlr-plans" id="areas">
		<div class="cdlr-container">
			<h2 class="cdlr-section-title" data-reveal>Áreas de práctica</h2>
			<p class="cdlr-plans__lead" data-reveal>Trabajas directo en los proyectos reales de la Corporación: Sesiones De La Raíz, La Grúa del Rock y los eventos de patrocinio de bandas locales.</p>

			<div class="cdlr-plans__grid">

				<article class="cdlr-plan" data-reveal>
					<span class="cdlr-plan__icon"><?php echo cdlr_icon( 'volume' ); ?></span>
					<h3 class="cdlr-plan__name">Sonido</h3>
					<ul class="cdlr-plan__list">
						<li><?php echo cdlr_icon( 'check' ); ?> Apoyo técnico en sonido en vivo para eventos y sesiones grabadas.</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Trabajo directo con el equipo técnico de la Corporación.</li>
					</ul>
					<button type="button" class="cdlr-btn cdlr-btn--ghost cdlr-plan__cta" data-plan="Sonido">Postular en Sonido</button>
				</article>

				<article class="cdlr-plan cdlr-plan--featured" data-reveal>
					<span class="cdlr-plan__icon"><?php echo cdlr_icon( 'camera' ); ?></span>
					<h3 class="cdlr-plan__name">Audiovisual</h3>
					<ul class="cdlr-plan__list">
						<li><?php echo cdlr_icon( 'check' ); ?> Registro y edición de contenido para Sesiones De La Raíz y La Grúa del Rock.</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Producción de material para redes y difusión.</li>
					</ul>
					<button type="button" class="cdlr-btn cdlr-btn--primary cdlr-plan__cta" data-plan="Audiovisual">Postular en Audiovisual</button>
				</article>

				<article class="cdlr-plan" data-reveal>
					<span class="cdlr-plan__icon"><?php echo cdlr_icon( 'handshake' ); ?></span>
					<h3 class="cdlr-plan__name">Apoyo General</h3>
					<ul class="cdlr-plan__list">
						<li><?php echo cdlr_icon( 'check' ); ?> Coordinación de eventos, comunicaciones y gestión de proyectos.</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Ideal para carreras de gestión cultural, periodismo o administración.</li>
					</ul>
					<button type="button" class="cdlr-btn cdlr-btn--ghost cdlr-plan__cta" data-plan="Apoyo general">Postular en Apoyo General</button>
				</article>

			</div>
		</div>
	</section>

	<section class="cdlr-cta" id="postula">
		<div class="cdlr-container cdlr-cta__grid">

			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">Postula tu práctica</h2>
				<p>Cuéntanos de ti y tu institución, y te contactamos para coordinar los detalles.</p>
				<p class="cdlr-plan-selected" id="cdlr-plan-selected" hidden>Área seleccionada: <strong id="cdlr-plan-selected-name"></strong></p>
			</div>

			<div class="cdlr-cta__form-wrap" data-reveal>
				<form class="cdlr-form" id="cdlr-contact-form" method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" novalidate>
					<input type="hidden" name="action" value="cdlr_contact">
					<input type="hidden" name="cdlr_plan" id="cdlr_plan" value="">
					<input type="hidden" name="cdlr_meta_label" value="Área de interés">
					<input type="hidden" name="cdlr_subject_type" value="práctica profesional">
					<input type="hidden" name="cdlr_redirect" value="<?php echo esc_url( home_url( '/practicas/#postula' ) ); ?>">
					<?php wp_nonce_field( 'cdlr_contact', 'cdlr_contact_nonce' ); ?>
					<div class="cdlr-hp" aria-hidden="true">
						<label for="cdlr_website_prac">No completar</label>
						<input type="text" id="cdlr_website_prac" name="cdlr_website" tabindex="-1" autocomplete="off">
					</div>

					<div class="cdlr-field">
						<label for="cdlr_name_prac">Nombre</label>
						<input type="text" id="cdlr_name_prac" name="cdlr_name" placeholder="Ingresa tu nombre" required>
					</div>
					<div class="cdlr-field">
						<label for="cdlr_email_prac">Email</label>
						<input type="email" id="cdlr_email_prac" name="cdlr_email" placeholder="Ingresa tu email" required>
					</div>
					<div class="cdlr-field">
						<label for="cdlr_phone_prac">Teléfono (opcional)</label>
						<input type="tel" id="cdlr_phone_prac" name="cdlr_phone" placeholder="+56 9 ...">
					</div>
					<div class="cdlr-field">
						<label for="cdlr_institution_prac">Institución / casa de estudios</label>
						<input type="text" id="cdlr_institution_prac" name="cdlr_institution" placeholder="Universidad o instituto" required>
					</div>
					<div class="cdlr-field">
						<label for="cdlr_message_prac">Mensaje (opcional)</label>
						<textarea id="cdlr_message_prac" name="cdlr_message" rows="4" placeholder="Cuéntanos por qué quieres practicar con nosotros"></textarea>
					</div>

					<button type="submit" class="cdlr-btn cdlr-btn--primary cdlr-form__submit">Enviar postulación</button>

					<div id="cdlr-form-status" role="status" aria-live="polite" class="cdlr-form__status<?php echo $status ? ' is-' . esc_attr( $status ) : ''; ?>">
						<?php if ( 'success' === $status ) : ?>
							¡Gracias! Vamos a revisar tu postulación y te contactamos pronto.
						<?php elseif ( 'error' === $status ) : ?>
							Revisa tus datos e intenta de nuevo.
						<?php endif; ?>
					</div>
				</form>
			</div>

		</div>
	</section>

</main>

<?php
get_footer();
