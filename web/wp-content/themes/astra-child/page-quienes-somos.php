<?php
/**
 * Quiénes somos — página propia, código 100% a medida (mismo patrón que
 * page-membresia.php / page-la-grua-del-rock.php). Contenido (misión, visión,
 * equipo) tomado del dossier corporativo; los perfiles usan un badge con
 * iniciales en vez de fotos, porque no hay fotos reales del equipo todavía.
 */

get_header();

$equipo = [
	[
		'nombre' => 'Pablo Rifo',
		'cargo'  => 'Presidente y Director de la Corporación',
		'bio'    => 'Gestor cultural y productor musical con más de dos décadas de trayectoria dedicada al fortalecimiento de la escena artística de Concepción. Fundador de Corporación De La Raíz y creador de La Grúa del Rock.',
	],
	[
		'nombre' => 'Alexis Villanueva',
		'cargo'  => 'Director Audiovisual',
		'bio'    => 'Director Audiovisual de la Universidad Católica de la Santísima Concepción, con experiencia en post-producción y animación digital.',
	],
	[
		'nombre' => 'Fabián Aguayo',
		'cargo'  => 'Técnico en Sonido',
		'bio'    => 'Técnico en Sonido y estudiante de Ingeniería en Sonido de la Universidad Santo Tomás, con experiencia en producción musical y sonido en vivo para los eventos de la Corporación.',
	],
	[
		'nombre' => 'Benjamín Órdenes',
		'cargo'  => 'Técnico en Sonido',
		'bio'    => 'Parte del equipo técnico de sonido de la Corporación.',
	],
	[
		'nombre' => 'Edgardo Cabezas',
		'cargo'  => 'Encargado de Comunicaciones',
		'bio'    => 'Estudiante de Periodismo de la Universidad Gabriela Mistral y Contador Auditor de la Universidad Católica de la Santísima Concepción.',
	],
	[
		'nombre' => 'Patricio Alcaíno',
		'cargo'  => 'Encargado de Finanzas y Proyectos',
		'bio'    => 'Ingeniero Civil Industrial y MBA de la Universidad Católica de la Santísima Concepción, con experiencia en evaluación y gestión de proyectos con co-financiamiento CORFO.',
	],
];
?>

<main id="cdlr-main" class="cdlr-home cdlr-quienes">

	<section class="cdlr-mem-hero">
		<div class="cdlr-container" data-reveal>
			<p class="cdlr-eyebrow">Corporación de la Raíz</p>
			<h1 class="cdlr-mem-hero__title">Quiénes <span>somos</span></h1>
			<p class="cdlr-hero__lead">Una corporación cultural sin fines de lucro fundada en 2023 en Concepción, dedicada a dar visibilidad y apoyo a su escena musical emergente.</p>
		</div>
	</section>

	<section class="cdlr-quienes-mv">
		<div class="cdlr-container cdlr-quienes-mv__grid">
			<div class="cdlr-quienes-mv__card" data-reveal>
				<span class="cdlr-eyebrow">Misión</span>
				<p>Internacionalizar la ciudad de Concepción, dando apoyo y difusión a su escena musical emergente. Fortalecer la comunidad entre artistas y proyectos musicales a nivel nacional e internacional.</p>
			</div>
			<div class="cdlr-quienes-mv__card" data-reveal>
				<span class="cdlr-eyebrow">Visión</span>
				<p>Ser el principal medio de difusión y apoyo de la escena musical para las bandas emergentes del territorio latinoamericano.</p>
			</div>
		</div>
	</section>

	<section class="cdlr-quienes-equipo">
		<div class="cdlr-container">
			<h2 class="cdlr-section-title" data-reveal>Equipo</h2>
			<div class="cdlr-quienes-grid">
				<?php foreach ( $equipo as $persona ) : ?>
					<article class="cdlr-persona" data-reveal>
						<span class="cdlr-persona__avatar"><?php echo esc_html( cdlr_initials( $persona['nombre'] ) ); ?></span>
						<h3 class="cdlr-persona__nombre"><?php echo esc_html( $persona['nombre'] ); ?></h3>
						<p class="cdlr-persona__cargo"><?php echo esc_html( $persona['cargo'] ); ?></p>
						<p class="cdlr-persona__bio"><?php echo esc_html( $persona['bio'] ); ?></p>
					</article>
				<?php endforeach; ?>
			</div>
			<p class="cdlr-quienes-directorio" data-reveal>El Directorio de la Corporación está compuesto por Pablo Rifo (Presidente), Ricardo Inostroza (Secretario) y Loreto Inostroza (Tesorera).</p>
		</div>
	</section>

	<section class="cdlr-cta" id="sumate-equipo">
		<div class="cdlr-container cdlr-cta__grid">
			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">¿Quieres sumarte al equipo?</h2>
				<p>Recibimos alumnos en práctica de sonido, audiovisual y apoyo general a la gestión de la Corporación durante todo el año.</p>
				<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/practicas/' ) ); ?>">Postula tu práctica</a>
			</div>
			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">¿Prefieres apoyar como socio?</h2>
				<p>Con tu aporte mensual financias los shows gratuitos y La Grúa del Rock en Concepción.</p>
				<a class="cdlr-btn cdlr-btn--ghost" href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Ver planes de membresía</a>
			</div>
		</div>
	</section>

</main>

<?php
get_footer();
