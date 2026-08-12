<?php
/**
 * Portada — landing 100% código de Corporación de la Raíz.
 */

get_header();

$hero_image = wp_get_attachment_image_url( 13, 'full' );
$status     = isset( $_GET['cdlr_status'] ) ? sanitize_key( wp_unslash( $_GET['cdlr_status'] ) ) : '';
?>

<main id="cdlr-main" class="cdlr-home">

	<section class="cdlr-hero" id="inicio" style="--hero-image: url('<?php echo esc_url( $hero_image ); ?>');">
		<div class="cdlr-container cdlr-hero__inner" data-reveal>
			<p class="cdlr-eyebrow">Impulsamos la escena musical emergente de Concepción</p>
			<h1 class="cdlr-hero__title">Transformamos las calles en <span>escenarios</span></h1>
			<p class="cdlr-hero__lead">Corporación cultural sin fines de lucro que da visibilidad a las bandas emergentes de Concepción a través de festivales, producción audiovisual y proyectos propios como La Grúa del Rock, nuestro escenario móvil insignia.</p>
			<div class="cdlr-hero__actions">
				<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Hazte socio/a</a>
				<a class="cdlr-btn cdlr-btn--ghost" href="#sumate">Haz tu aporte</a>
				<a class="cdlr-btn cdlr-btn--link" href="#proyectos">Conoce nuestros proyectos <?php echo cdlr_icon( 'arrow-right' ); ?></a>
			</div>
		</div>
	</section>

	<section class="cdlr-stats" aria-label="Cifras de impacto">
		<div class="cdlr-container cdlr-stats__grid">
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="23" data-suffix="+">0</span></span>
				<span class="cdlr-stat__label">Bandas en La Grúa del Rock</span>
			</div>
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="400" data-suffix="k+">0</span></span>
				<span class="cdlr-stat__label">Asistentes en Festival REC 2026</span>
			</div>
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="100" data-suffix="%">0</span></span>
				<span class="cdlr-stat__label">Gratuito y accesible</span>
			</div>
		</div>
	</section>

	<section class="cdlr-pillars" id="proyectos">
		<div class="cdlr-container">
			<h2 class="cdlr-section-title" data-reveal>Lo que hacemos</h2>
			<div class="cdlr-pillars__grid">

				<article class="cdlr-pillar" data-reveal>
					<span class="cdlr-pillar__icon"><?php echo cdlr_icon( 'truck' ); ?></span>
					<h3>La Grúa del Rock</h3>
					<p>Un escenario móvil que recorre las calles de Concepción con bandas locales tocando en vivo, directo para quien vaya pasando.</p>
					<a class="cdlr-btn cdlr-btn--link" href="<?php echo esc_url( home_url( '/la-grua-del-rock/' ) ); ?>">Conoce el proyecto <?php echo cdlr_icon( 'arrow-right' ); ?></a>
				</article>

				<article class="cdlr-pillar" data-reveal>
					<span class="cdlr-pillar__icon"><?php echo cdlr_icon( 'disc' ); ?></span>
					<h3>Sesiones De La Raíz</h3>
					<p>Desde 2020 grabamos entrevistas y sets en vivo con bandas emergentes en los bares y espacios más icónicos de Concepción.</p>
				</article>

				<article class="cdlr-pillar" data-reveal>
					<span class="cdlr-pillar__icon"><?php echo cdlr_icon( 'handshake' ); ?></span>
					<h3>Patrocinio de Bandas Locales</h3>
					<p>Cada año seleccionamos entre 8 y 10 artistas sin álbum propio y financiamos la grabación y producción de su debut.</p>
				</article>

				<article class="cdlr-pillar" data-reveal>
					<span class="cdlr-pillar__icon"><?php echo cdlr_icon( 'megaphone' ); ?></span>
					<h3>Apoyo a Bandas Juveniles</h3>
					<p>Batallas de bandas y homenajes para que músicos menores de 20 años den sus primeros pasos en la música.</p>
				</article>

			</div>
		</div>
	</section>

	<section class="cdlr-gallery" aria-label="La Grúa del Rock en la calle">
		<div class="cdlr-container cdlr-gallery__grid">
			<figure class="cdlr-gallery__item" data-reveal>
				<?php echo wp_get_attachment_image( 56, 'large', false, [ 'alt' => 'Producción audiovisual de Corporación de la Raíz en terreno', 'loading' => 'lazy' ] ); ?>
				<figcaption>Producción Audiovisual</figcaption>
			</figure>
			<figure class="cdlr-gallery__item" data-reveal>
				<?php echo wp_get_attachment_image( 58, 'large', false, [ 'alt' => 'La Grúa del Rock montada como escenario en la calle', 'loading' => 'lazy' ] ); ?>
				<figcaption>La Grúa del Rock</figcaption>
			</figure>
			<figure class="cdlr-gallery__item" data-reveal>
				<?php echo wp_get_attachment_image( 78, 'large', false, [ 'alt' => 'Espacio público activado por Corporación de la Raíz', 'loading' => 'lazy' ] ); ?>
				<figcaption>Espacios Abiertos</figcaption>
			</figure>
		</div>
	</section>

	<section class="cdlr-mission" aria-label="Nuestra misión">
		<div class="cdlr-container cdlr-mission__grid">
			<p data-reveal>El rock no solo se escucha, <span>se vive en comunidad.</span></p>
			<p data-reveal>Transformando el espacio público <span>a través del arte.</span></p>
			<p data-reveal>Cultura en movimiento: <span>directo desde la calle para todos.</span></p>
		</div>
	</section>

	<section class="cdlr-about" id="historia">
		<div class="cdlr-container cdlr-about__grid">
			<figure class="cdlr-about__media" data-reveal>
				<?php echo wp_get_attachment_image( 57, 'large', false, [ 'alt' => 'Logo de Corporación de la Raíz: un guitarrista naciendo desde las raíces', 'loading' => 'lazy' ] ); ?>
			</figure>
			<div class="cdlr-about__copy" data-reveal>
				<span class="cdlr-eyebrow">Corporación de la Raíz</span>
				<h2 class="cdlr-section-title">Nuestra historia y misión</h2>
				<p>De La Raíz es una corporación cultural sin fines de lucro fundada en 2023 por Pablo Rifo, gestor cultural y productor musical con más de dos décadas de trayectoria en el fortalecimiento de la escena artística de Concepción.</p>
				<p>Nuestra misión es internacionalizar la ciudad de Concepción dando apoyo y difusión a su escena musical emergente, y fortalecer la comunidad entre artistas y proyectos musicales a nivel nacional e internacional — con la aspiración de ser el principal medio de difusión de la escena emergente del territorio latinoamericano.</p>
				<a class="cdlr-btn cdlr-btn--primary" href="#sumate">Súmate al movimiento</a>
			</div>
		</div>
		<div class="cdlr-container">
			<div class="cdlr-values">
				<div class="cdlr-values__item" data-reveal>
					<?php echo cdlr_icon( 'camera' ); ?>
					<p>Generamos instancias para que las bandas emergentes exhiban sus proyectos musicales a través de festivales y eventos, con registro audiovisual sin costo para ellas.</p>
				</div>
				<div class="cdlr-values__item" data-reveal>
					<?php echo cdlr_icon( 'guitar' ); ?>
					<p>Homenajeamos el arte producido por los artistas de la ciudad, reconociendo su valor frente al panorama musical nacional e internacional.</p>
				</div>
				<div class="cdlr-values__item" data-reveal>
					<?php echo cdlr_icon( 'signpost' ); ?>
					<p>Rescatamos el legado cultural de Concepción, aprovechando sus espacios emblemáticos para destacar su valor histórico.</p>
				</div>
			</div>
		</div>
	</section>

	<section class="cdlr-cta" id="sumate">
		<div class="cdlr-container cdlr-cta__grid">

			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">Súmate al movimiento</h2>
				<ul class="cdlr-reasons">
					<li><?php echo cdlr_icon( 'calendar' ); ?> No te pierdas las próximas salidas de la Grúa.</li>
					<li><?php echo cdlr_icon( 'volume' ); ?> Espacios abiertos para bandas emergentes.</li>
					<li><?php echo cdlr_icon( 'disc' ); ?> Enterate antes que nadie de los estrenos de De La Raíz.</li>
					<li><?php echo cdlr_icon( 'handshake' ); ?> Súmate al circuito de gestión urbana y social.</li>
				</ul>
			</div>

			<div class="cdlr-cta__form-wrap" data-reveal>
				<form class="cdlr-form" id="cdlr-contact-form" method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" novalidate>
					<input type="hidden" name="action" value="cdlr_contact">
					<?php wp_nonce_field( 'cdlr_contact', 'cdlr_contact_nonce' ); ?>
					<div class="cdlr-hp" aria-hidden="true">
						<label for="cdlr_website">No completar</label>
						<input type="text" id="cdlr_website" name="cdlr_website" tabindex="-1" autocomplete="off">
					</div>

					<div class="cdlr-field">
						<label for="cdlr_name">Nombre</label>
						<input type="text" id="cdlr_name" name="cdlr_name" placeholder="Ingresa tu nombre" required>
					</div>
					<div class="cdlr-field">
						<label for="cdlr_email">Email</label>
						<input type="email" id="cdlr_email" name="cdlr_email" placeholder="Ingresa tu email" required>
					</div>
					<div class="cdlr-field">
						<label for="cdlr_message">Mensaje</label>
						<textarea id="cdlr_message" name="cdlr_message" rows="4" placeholder="Cuenta con nosotros!" required></textarea>
					</div>

					<button type="submit" class="cdlr-btn cdlr-btn--primary cdlr-form__submit">Enviar</button>

					<div id="cdlr-form-status" role="status" aria-live="polite" class="cdlr-form__status<?php echo $status ? ' is-' . esc_attr( $status ) : ''; ?>">
						<?php if ( 'success' === $status ) : ?>
							¡Gracias! Te vamos a contactar pronto.
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
