<?php
/**
 * Alianzas ("Trabajemos juntos") — página propia, código 100% a medida
 * (mismo patrón que page-quienes-somos.php / page-practicas.php). Pensada
 * para mostrarse a marcas potenciales (ej. MAXUS, ver PROYECTO.md sección
 * 9.16): quiénes somos en números, por qué colaborar, y contacto directo.
 *
 * La franja de logos (cdlr_alianzas_logos()) arranca vacía a propósito —
 * se oculta sola mientras no haya ningún aliado real cargado, en vez de
 * mostrar una sección a medio llenar.
 */

get_header();

$logos = cdlr_alianzas_logos();
?>

<main id="cdlr-main" class="cdlr-home cdlr-alianzas">

	<section class="cdlr-mem-hero">
		<div class="cdlr-container" data-reveal>
			<p class="cdlr-eyebrow">Patrocinios</p>
			<h1 class="cdlr-mem-hero__title">Trabajemos <span>juntos</span></h1>
			<p class="cdlr-hero__lead">Buscamos marcas que quieran ser parte de la escena musical emergente de Concepción — visibilidad real, en la calle, junto a un proyecto cultural con historia y números concretos.</p>
		</div>
	</section>

	<section class="cdlr-stats" aria-label="Alcance real de nuestros proyectos">
		<div class="cdlr-container cdlr-stats__grid">
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="23" data-suffix="+">0</span></span>
				<span class="cdlr-stat__label">Bandas locales en La Grúa del Rock</span>
			</div>
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="400" data-suffix="k+">0</span></span>
				<span class="cdlr-stat__label">Asistentes en Festival REC 2026</span>
			</div>
			<div class="cdlr-stat" data-reveal>
				<span class="cdlr-stat__number"><span data-count="100" data-suffix="%">0</span></span>
				<span class="cdlr-stat__label">Gratuito, en la calle, para todos</span>
			</div>
		</div>
	</section>

	<section class="cdlr-alianzas-porque">
		<div class="cdlr-container cdlr-alianzas-porque__grid">
			<div class="cdlr-alianzas-porque__card" data-reveal>
				<span class="cdlr-eyebrow">Visibilidad real</span>
				<h2 class="cdlr-section-title">La marca sale a la calle, no se queda en una pantalla</h2>
				<p>La Grúa del Rock es un escenario móvil que recorre plazas y calles de Concepción con público real en vivo — presencia de marca en el vehículo, en el escenario y en cada pieza de difusión del recorrido, no solo un logo más en una grilla de auspiciadores.</p>
			</div>
			<div class="cdlr-alianzas-porque__card" data-reveal>
				<span class="cdlr-eyebrow">Alcance verificable</span>
				<h2 class="cdlr-section-title">Historia y números concretos, no una promesa</h2>
				<p>Más de 400.000 personas en el Festival REC 2026, 23+ bandas locales ya subieron a la Grúa, cobertura en redes y prensa de cada temporada. Todo lo que mostramos acá ya pasó de verdad.</p>
			</div>
		</div>
	</section>

	<?php if ( ! empty( $logos ) ) : ?>
	<section class="cdlr-alianzas-logos">
		<div class="cdlr-container">
			<h2 class="cdlr-section-title" data-reveal>Marcas que ya son parte de esto</h2>
			<div class="cdlr-alianzas-logos__grid">
				<?php foreach ( $logos as $marca ) : ?>
					<?php
					$logo_html = wp_get_attachment_image( $marca['logo_id'] ?? 0, 'medium', false, [ 'class' => 'cdlr-alianzas-logos__img', 'alt' => $marca['nombre'] ?? '' ] );
					if ( ! $logo_html ) {
						continue;
					}
					?>
					<div class="cdlr-alianzas-logos__item" data-reveal>
						<?php if ( ! empty( $marca['url'] ) ) : ?>
							<a href="<?php echo esc_url( $marca['url'] ); ?>" target="_blank" rel="noopener noreferrer"><?php echo $logo_html; ?></a>
						<?php else : ?>
							<?php echo $logo_html; ?>
						<?php endif; ?>
					</div>
				<?php endforeach; ?>
			</div>
		</div>
	</section>
	<?php endif; ?>

	<section class="cdlr-cta" id="conversemos">
		<div class="cdlr-container">
			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">¿Conversamos?</h2>
				<p>Cuéntanos tu idea de colaboración — auspicio de una temporada, aporte en especie, o algo distinto que se te ocurra. Escríbenos directo:</p>
				<a class="cdlr-btn cdlr-btn--primary" href="mailto:contacto@corporaciondelaraiz.cl?subject=Alianza%20con%20la%20Corporaci%C3%B3n%20De%20La%20Ra%C3%ADz">contacto@corporaciondelaraiz.cl</a>
			</div>
		</div>
	</section>

</main>

<?php
get_footer();
