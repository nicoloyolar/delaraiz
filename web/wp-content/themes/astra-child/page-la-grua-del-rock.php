<?php
/**
 * La Grúa del Rock — página propia, código 100% a medida (mismo patrón que
 * page-membresia.php). WordPress la sirve para la página con slug
 * "la-grua-del-rock".
 */

get_header();

$hero_image = wp_get_attachment_image_url( 58, 'full' );
?>

<main id="cdlr-main" class="cdlr-home cdlr-grua">

	<section class="cdlr-grua-hero" style="--hero-image: url('<?php echo esc_url( $hero_image ); ?>');">
		<div class="cdlr-container cdlr-grua-hero__inner" data-reveal>
			<p class="cdlr-eyebrow">Un proyecto de Corporación de la Raíz</p>
			<h1 class="cdlr-grua-hero__title">La Grúa del <span>Rock</span></h1>
			<p class="cdlr-hero__lead">Una grúa de remolque acondicionada como escenario móvil, que recorre las calles de Concepción con bandas locales tocando en vivo — directo para quien vaya pasando.</p>
			<div class="cdlr-hero__actions">
				<a class="cdlr-btn cdlr-btn--primary" href="#hitos">Ver la temporada 2025-2026</a>
				<a class="cdlr-btn cdlr-btn--link" href="<?php echo esc_url( home_url( '/' ) ); ?>">Conoce la Corporación <?php echo cdlr_icon( 'arrow-right' ); ?></a>
			</div>
		</div>
	</section>

	<section class="cdlr-grua-about">
		<div class="cdlr-container cdlr-grua-about__grid">
			<div class="cdlr-grua-about__copy" data-reveal>
				<span class="cdlr-eyebrow">Qué es</span>
				<h2 class="cdlr-section-title">Un escenario que sale a buscar al público</h2>
				<p>La Grúa del Rock nace en 2025 del acondicionamiento de una grúa de remolque como escenario móvil. En vez de esperar a que el público llegue a un recinto, es la música la que recorre la ciudad: artistas tocando en vivo mientras la grúa avanza por plazas y calles.</p>
				<p>El objetivo es doble: acercar a los artistas locales a la comunidad, dándoles una tribuna poco convencional para mostrar su trabajo, y forjar la identidad de Concepción como "ciudad del rock" a través de una instancia única en la región.</p>
			</div>
			<figure class="cdlr-grua-about__media" data-reveal>
				<?php echo wp_get_attachment_image( 52, 'large', false, [ 'alt' => 'Frontal de La Grúa del Rock con su rotulado pintado a mano', 'loading' => 'lazy' ] ); ?>
			</figure>
		</div>
	</section>

	<section class="cdlr-stats" aria-label="Cifras de la primera temporada">
		<div class="cdlr-container cdlr-stats__grid">
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="23" data-suffix="+">0</span></span>
				<span class="cdlr-stat__label">Bandas locales subieron a la Grúa</span>
			</div>
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="2" data-suffix="-3h">0</span></span>
				<span class="cdlr-stat__label">De música en cada recorrido</span>
			</div>
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="100" data-suffix="%">0</span></span>
				<span class="cdlr-stat__label">Gratuito, en la calle, para todos</span>
			</div>
		</div>
	</section>

	<section class="cdlr-grua-hitos" id="hitos">
		<div class="cdlr-container">
			<h2 class="cdlr-section-title" data-reveal>Primera temporada: 2025 – 2026</h2>
			<p class="cdlr-plans__lead" data-reveal>Cada sábado, cerca del mediodía, una banda distinta tocaba en vivo sobre la Grúa mientras esta recorría las calles de Concepción.</p>

			<ol class="cdlr-timeline">
				<li class="cdlr-timeline__item" data-reveal>
					<span class="cdlr-timeline__date">Octubre 2025</span>
					<h3>Lanzamiento de La Grúa del Rock</h3>
					<p>Primera salida de la temporada: la Grúa comienza a recorrer plazas y calles de Concepción con una banda local distinta cada sábado.</p>
				</li>
				<li class="cdlr-timeline__item" data-reveal>
					<span class="cdlr-timeline__date">28–29 marzo 2026</span>
					<h3>Escenario alternativo del Festival REC</h3>
					<p>La Grúa del Rock fue el escenario alternativo de la XI edición del Festival REC, evento gratuito que reunió a más de 400.000 asistentes en ambos días. 10 bandas locales tocaron sobre la Grúa durante el festival.</p>
				</li>
				<li class="cdlr-timeline__item" data-reveal>
					<span class="cdlr-timeline__date">11 abril 2026</span>
					<h3>Festival Grúa del Rock</h3>
					<p>Cierre de la primera temporada en Plaza René Schneider (Plaza de Tribunales de Concepción): 9 bandas locales de distinta trayectoria — desde nombres consolidados como Loika hasta proyectos emergentes como Duna Vaguada y bandas juveniles como Aura — con producción de sonido y visual propia, sobre la misma Grúa del Rock.</p>
				</li>
			</ol>
		</div>
	</section>

	<section class="cdlr-grua-rutas">
		<div class="cdlr-container cdlr-grua-rutas__grid">
			<span class="cdlr-grua-rutas__icon"><?php echo cdlr_icon( 'map-pin' ); ?></span>
			<div>
				<span class="cdlr-eyebrow">Ligado a este proyecto</span>
				<h2 class="cdlr-section-title" style="text-align:left">Rutas Musicales Patrimoniales</h2>
				<p>Una línea de trabajo que usa el mismo escenario móvil para llevar festivales a lugares de relevancia histórica de Concepción. La idea es que, además de disfrutar de la música en vivo, el público tenga la oportunidad de conocer el valor patrimonial de esos espacios a través de charlas, infografías y otras actividades complementarias a cargo de actores locales.</p>
			</div>
		</div>
	</section>

	<section class="cdlr-cta" id="apoya">
		<div class="cdlr-container cdlr-cta__grid">
			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">Súmate a que la Grúa siga rodando</h2>
				<p>Cada temporada de La Grúa del Rock se financia con el aporte de quienes creen en este proyecto. Hazte socio y ayuda a que siga recorriendo las calles de Concepción.</p>
				<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Ver planes de membresía</a>
			</div>
			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">¿Eres una banda de Concepción?</h2>
				<p>La convocatoria de esta temporada ya cerró, pero puedes escribirnos y te avisamos apenas abramos la próxima.</p>
				<a class="cdlr-btn cdlr-btn--ghost" href="<?php echo esc_url( home_url( '/#sumate' ) ); ?>">Escríbenos</a>
			</div>
		</div>
	</section>

</main>

<?php
get_footer();
