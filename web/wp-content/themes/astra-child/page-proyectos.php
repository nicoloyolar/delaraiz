<?php
/**
 * Proyectos — página propia, código 100% a medida (mismo patrón que
 * page-quienes-somos.php / page-alianzas.php). Agregada 2026-09-24 a pedido
 * del checklist de "Optimización de la Página Web" (ítem 4, área TI): el
 * nav pedido reemplaza "La Grúa del Rock" (único proyecto con página propia
 * hasta ahora) por "Proyectos", que agrupa las 4 líneas reales del dossier.
 *
 * El texto de las 4 líneas es el mismo ya usado en la sección "Lo que
 * hacemos" de la home (`front-page.php`, id="proyectos") — se copia literal
 * acá para no desalinear los dos lugares sin querer. Solo La Grúa del Rock
 * tiene página propia con más detalle (historia, cifras, timeline) — las
 * otras 3 líneas no, mismo alcance que ya tenía la home.
 */

get_header();
?>

<main id="cdlr-main" class="cdlr-home cdlr-proyectos">

	<section class="cdlr-mem-hero">
		<div class="cdlr-container" data-reveal>
			<p class="cdlr-eyebrow">Corporación de la Raíz</p>
			<h1 class="cdlr-mem-hero__title">Nuestros <span>proyectos</span></h1>
			<p class="cdlr-hero__lead">4 líneas de trabajo, todas con el mismo objetivo: dar visibilidad y apoyo real a la escena musical emergente de Concepción.</p>
		</div>
	</section>

	<section class="cdlr-pillars">
		<div class="cdlr-container">
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

	<section class="cdlr-cta" id="apoya">
		<div class="cdlr-container">
			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">Tu aporte financia estos 4 proyectos</h2>
				<p>Cada membresía ayuda directo a que estas líneas de trabajo sigan funcionando durante todo el año.</p>
				<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Ver planes de membresía</a>
			</div>
		</div>
	</section>

</main>

<?php
get_footer();
