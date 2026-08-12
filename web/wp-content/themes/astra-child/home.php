<?php
/**
 * Noticias — plantilla a medida para la página de entradas del blog, mismo
 * sistema de diseño premium 100% código que el resto del sitio (hero +
 * tarjetas, reutilizando .cdlr-container/.cdlr-section-title/.cdlr-btn de
 * header.css/premium.css). Antes esta página usaba el archivo genérico de
 * Astra, con solo la tipografía ajustada (blog.css) — se veía "de fábrica"
 * comparada con el resto del sitio.
 *
 * WordPress usa este archivo automáticamente para la página asignada como
 * "Tus entradas más recientes muestran" en Ajustes > Lectura (la portada real
 * es front-page.php, esta es la página de entradas — hoy "Noticias", ID 378).
 */

get_header();
?>

<main id="cdlr-main" class="cdlr-home cdlr-noticias">

	<section class="cdlr-noticias-hero">
		<div class="cdlr-container" data-reveal>
			<p class="cdlr-eyebrow">El blog de la Corporación</p>
			<h1 class="cdlr-noticias-hero__title">Noticias</h1>
			<p class="cdlr-hero__lead">Recaps de shows, novedades de nuestros proyectos y todo lo que va pasando en la escena musical de Concepción.</p>
		</div>
	</section>

	<section class="cdlr-noticias-list">
		<div class="cdlr-container">

			<?php if ( have_posts() ) : ?>

				<div class="cdlr-noticias__grid">
					<?php while ( have_posts() ) : the_post(); ?>
						<article class="cdlr-noticias-card" data-reveal>
							<a class="cdlr-noticias-card__media" href="<?php the_permalink(); ?>" aria-hidden="true" tabindex="-1">
								<?php if ( has_post_thumbnail() ) : ?>
									<?php the_post_thumbnail( 'large', [ 'loading' => 'lazy' ] ); ?>
								<?php else : ?>
									<span class="cdlr-noticias-card__media-fallback"><?php echo cdlr_icon( 'megaphone' ); ?></span>
								<?php endif; ?>
							</a>
							<div class="cdlr-noticias-card__body">
								<span class="cdlr-noticias-card__date"><?php echo esc_html( get_the_date( 'j \d\e F \d\e Y' ) ); ?></span>
								<h2 class="cdlr-noticias-card__title">
									<a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
								</h2>
								<p class="cdlr-noticias-card__excerpt"><?php echo esc_html( wp_trim_words( get_the_excerpt(), 26 ) ); ?></p>
								<a class="cdlr-btn cdlr-btn--link" href="<?php the_permalink(); ?>">Leer más <?php echo cdlr_icon( 'arrow-right' ); ?></a>
							</div>
						</article>
					<?php endwhile; ?>
				</div>

				<?php
				the_posts_pagination( [
					'prev_text' => 'Anterior',
					'next_text' => 'Siguiente',
					'screen_reader_text' => 'Paginación de noticias',
				] );
				?>

			<?php else : ?>

				<p class="cdlr-noticias__empty">Todavía no hay entradas publicadas — vuelve pronto.</p>

			<?php endif; ?>

		</div>
	</section>

</main>

<?php
get_footer();
