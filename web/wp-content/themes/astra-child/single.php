<?php
/**
 * Vista de una entrada individual del blog — plantilla a medida, mismo
 * sistema de diseño premium que el resto del sitio. Antes usaba el single.php
 * genérico de Astra (hero simple + contenido boxeado, solo con la tipografía
 * ajustada vía blog.css) — se veía "de fábrica" comparado con el resto.
 *
 * La imagen destacada ahora se usa como fondo del hero (si la entrada tiene
 * una) — esto resuelve de paso el pendiente de "la imagen destacada no se ve
 * en la vista de post individual" que quedaba anotado en PROYECTO.md: ya no
 * depende del ajuste de Customizer de Astra, la plantilla la muestra directo.
 *
 * Sin firma de autor a propósito: el único usuario de WordPress del sitio es
 * la cuenta personal del desarrollador, sin un autor editorial real asignado
 * a las entradas — mostrar "Por [ese usuario]" expondría un dato que no
 * corresponde en un sitio institucional. Si en algún momento hay un usuario
 * editorial real (ej. la periodista mencionada en el backlog), se puede
 * agregar la firma de vuelta.
 */

get_header();

while ( have_posts() ) :
	the_post();
	$hero_image = has_post_thumbnail() ? get_the_post_thumbnail_url( get_the_ID(), 'full' ) : '';
	?>

	<main id="cdlr-main" class="cdlr-home cdlr-single-post">

		<section class="cdlr-post-hero<?php echo $hero_image ? ' cdlr-post-hero--photo' : ''; ?>"<?php echo $hero_image ? ' style="--hero-image: url(\'' . esc_url( $hero_image ) . '\');"' : ''; ?>>
			<div class="cdlr-container cdlr-post-hero__inner" data-reveal>
				<a class="cdlr-post-hero__back" href="<?php echo esc_url( home_url( '/noticias/' ) ); ?>"><?php echo cdlr_icon( 'arrow-right', 'cdlr-post-hero__back-icon' ); ?> Volver a Noticias</a>
				<p class="cdlr-eyebrow">Noticias</p>
				<h1 class="cdlr-post-hero__title"><?php the_title(); ?></h1>
				<p class="cdlr-post-hero__date"><?php echo esc_html( get_the_date( 'j \d\e F \d\e Y' ) ); ?></p>
			</div>
		</section>

		<article <?php post_class( 'cdlr-post-body' ); ?>>
			<div class="cdlr-post-body__inner">
				<div class="entry-content">
					<?php the_content(); ?>
				</div>
			</div>
		</article>

		<?php if ( comments_open() || get_comments_number() ) : ?>
			<div class="cdlr-post-comments">
				<div class="cdlr-post-body__inner">
					<?php comments_template(); ?>
				</div>
			</div>
		<?php endif; ?>

	</main>

	<?php
endwhile;

get_footer();
