<?php

/**
 * Integración con Flow.cl (cobro recurrente de membresías) — vive en su
 * propio archivo, separado de todo lo demás de este tema, porque es el único
 * código que mueve dinero real. Ver inc/flow.php para el detalle completo.
 */
require_once get_stylesheet_directory() . '/inc/flow.php';

/**
 * Los nonces de WordPress vencen por defecto a las ~24-48h. Como este sitio
 * usa caché de página (LiteSpeed) y el nonce de cada formulario queda
 * "congelado" en el HTML cacheado, si pasan más de 1-2 días sin purgar caché
 * cualquier formulario empieza a fallar siempre ("revisa tus datos") sin que
 * sea culpa de lo que se escribió — pasó de verdad en producción con
 * Membresía el 2026-08-06 (ver PROYECTO.md). Se sube a 7 días como red de
 * seguridad sitewide, para todos los formularios (contacto, membresía,
 * prácticas, postulación de banda) — reduce mucho la probabilidad de que
 * vuelva a pasar, aunque no la elimina del todo (páginas de mucho tráfico
 * como la home siguen sin excluirse del caché, a propósito, por costo de
 * rendimiento — ver PROYECTO.md sección 5.1).
 */
add_filter( 'nonce_life', function () {
	return 7 * DAY_IN_SECONDS;
} );

add_action( 'wp_enqueue_scripts', function () {
	wp_enqueue_style( 'astra-parent-style', get_template_directory_uri() . '/style.css' );
	wp_enqueue_style(
		'astra-child-style',
		get_stylesheet_directory_uri() . '/style.css',
		[ 'astra-parent-style' ],
		wp_get_theme()->get( 'Version' )
	);
} );

/**
 * Header y footer a medida en toda la web: se saca lo que arma Astra (Header
 * Builder con Font Awesome y JS propio; footer genérico con el crédito al
 * tema) y se reemplaza por versiones propias, con el mismo sistema de diseño
 * de la portada.
 */
add_action( 'wp', function () {
	remove_all_actions( 'astra_header' );
	add_action( 'astra_header', 'cdlr_render_header' );

	remove_all_actions( 'astra_footer' );
	add_action( 'astra_footer', 'cdlr_render_footer' );
} );

function cdlr_render_header() {
	$header_class = is_front_page() ? 'cdlr-header cdlr-header--overlay' : 'cdlr-header cdlr-header--solid';
	?>
	<header class="<?php echo esc_attr( $header_class ); ?>" id="cdlr-header">
		<div class="cdlr-header__inner">
			<a class="cdlr-header__logo" href="<?php echo esc_url( home_url( '/' ) ); ?>">
				<?php bloginfo( 'name' ); ?>
			</a>

			<nav class="cdlr-header__nav" aria-label="Navegación principal">
				<?php
				wp_nav_menu( [
					'theme_location' => 'primary',
					'container'      => false,
					'menu_class'     => 'cdlr-header__menu',
					'fallback_cb'    => 'cdlr_header_menu_fallback',
					'depth'          => 1,
				] );
				?>
				<a class="cdlr-btn cdlr-btn--primary cdlr-header__cta" href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Hazte socio/a</a>
			</nav>

			<button type="button" class="cdlr-header__toggle" id="cdlr-header-toggle" aria-expanded="false" aria-controls="cdlr-mobile-panel">
				<span class="screen-reader-text">Abrir menú</span>
				<span class="cdlr-header__toggle-bars" aria-hidden="true"></span>
			</button>
		</div>

		<div class="cdlr-mobile-panel" id="cdlr-mobile-panel" hidden>
			<?php
			wp_nav_menu( [
				'theme_location' => 'primary',
				'container'      => false,
				'menu_class'     => 'cdlr-mobile-panel__menu',
				'fallback_cb'    => 'cdlr_header_menu_fallback',
				'depth'          => 1,
			] );
			?>
			<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Hazte socio/a</a>
		</div>
	</header>
	<?php
}

/**
 * Si todavía no se crea un menú en Apariencia > Menús, se listan las páginas
 * publicadas (mismo comportamiento por defecto que ya tenía Astra).
 *
 * `$cdlr_menu_excluded_slugs`: páginas que tienen que existir públicas para
 * que algo funcione (ej. la de retorno de pago de Flow, a la que Flow
 * redirige después de pagar) pero que nadie debería navegar directo desde el
 * menú — no se pueden poner en borrador/privadas porque necesitan seguir
 * siendo accesibles por URL para cualquier visitante, solo se ocultan de
 * esta lista automática.
 */
function cdlr_header_menu_fallback( $args ) {
	$excluded_slugs = [ 'membresia-retorno' ];

	$pages = get_pages( [ 'sort_column' => 'menu_order', 'parent' => 0 ] );
	echo '<ul class="' . esc_attr( $args['menu_class'] ) . '">';
	foreach ( $pages as $page ) {
		if ( in_array( $page->post_name, $excluded_slugs, true ) ) {
			continue;
		}
		printf(
			'<li><a href="%1$s"%2$s>%3$s</a></li>',
			esc_url( get_permalink( $page ) ),
			is_page( $page->ID ) ? ' aria-current="page"' : '',
			esc_html( get_the_title( $page ) )
		);
	}
	echo '</ul>';
}

/**
 * Redes sociales del footer. Las URLs quedan vacías hasta que se confirmen
 * los usuarios/enlaces definitivos (ver PROYECTO.md, sección Pendientes) —
 * mientras tanto cdlr_render_footer() dibuja los íconos como vista previa,
 * sin volverlos clicables, para no publicar enlaces rotos.
 */
function cdlr_social_links() {
	return [
		'instagram' => [ 'label' => 'Instagram', 'icon' => 'instagram', 'url' => '' ],
		'tiktok'    => [ 'label' => 'TikTok', 'icon' => 'tiktok', 'url' => '' ],
		'youtube'   => [ 'label' => 'YouTube', 'icon' => 'youtube', 'url' => '' ],
		'whatsapp'  => [ 'label' => 'WhatsApp', 'icon' => 'whatsapp', 'url' => '' ],
	];
}

/**
 * Footer a medida en toda la web: reemplaza el footer genérico de Astra
 * (crédito al tema, sin redes ni contacto) por uno con el mismo sistema de
 * diseño del header/portada.
 */
function cdlr_render_footer() {
	?>
	<footer class="cdlr-footer" id="colophon" itemtype="https://schema.org/WPFooter" itemscope="itemscope">
		<div class="cdlr-container cdlr-footer__grid">

			<div class="cdlr-footer__brand">
				<a class="cdlr-footer__logo" href="<?php echo esc_url( home_url( '/' ) ); ?>"><?php bloginfo( 'name' ); ?></a>
				<p>Escena musical emergente, cultura gratuita y accesible en Concepción.</p>
			</div>

			<div class="cdlr-footer__col">
				<h2 class="cdlr-footer__heading">Enlaces</h2>
				<ul class="cdlr-footer__links">
					<li><a href="<?php echo esc_url( home_url( '/' ) ); ?>">Inicio</a></li>
					<li><a href="<?php echo esc_url( home_url( '/la-grua-del-rock/' ) ); ?>">La Grúa del Rock</a></li>
					<li><a href="<?php echo esc_url( home_url( '/quienes-somos/' ) ); ?>">Quiénes somos</a></li>
					<li><a href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Membresía</a></li>
					<li><a href="<?php echo esc_url( home_url( '/practicas/' ) ); ?>">Prácticas profesionales</a></li>
				</ul>
			</div>

			<div class="cdlr-footer__col">
				<h2 class="cdlr-footer__heading">Contacto</h2>
				<ul class="cdlr-footer__links">
					<li><a href="mailto:corporaciondelaraiz@gmail.com">corporaciondelaraiz@gmail.com</a></li>
					<li>Concepción, Chile</li>
				</ul>
			</div>

			<div class="cdlr-footer__col">
				<h2 class="cdlr-footer__heading">Síguenos</h2>
				<div class="cdlr-footer__social">
					<?php foreach ( cdlr_social_links() as $social ) : ?>
						<?php if ( $social['url'] ) : ?>
							<a class="cdlr-footer__social-item" href="<?php echo esc_url( $social['url'] ); ?>" target="_blank" rel="noopener">
								<?php echo cdlr_icon( $social['icon'] ); ?>
								<span class="screen-reader-text"><?php echo esc_html( $social['label'] ); ?></span>
							</a>
						<?php else : ?>
							<span class="cdlr-footer__social-item cdlr-footer__social-item--soon">
								<?php echo cdlr_icon( $social['icon'] ); ?>
								<span class="screen-reader-text"><?php echo esc_html( $social['label'] ); ?> (próximamente)</span>
							</span>
						<?php endif; ?>
					<?php endforeach; ?>
				</div>
			</div>

		</div>

		<div class="cdlr-footer__bottom">
			<div class="cdlr-container">
				<p>&copy; <?php echo esc_html( gmdate( 'Y' ) ); ?> Corporación de la Raíz. Todos los derechos reservados.</p>
			</div>
		</div>
	</footer>
	<?php
}

/**
 * Modales sitewide: postulación de banda y el popup de membresía que aparece
 * al hacer scroll (este último para ayudar a conseguir financiamiento/
 * colaboradores). Se dibujan una sola vez al final de la página (wp_footer).
 *
 * El modal de postulación de banda (`#cdlr-modal-band`) queda intencionalmente
 * SIN ningún botón que lo abra desde el 2026-08-06: venció el plazo de
 * postulaciones de esta temporada de La Grúa del Rock, así que los 3 CTAs que
 * antes lo abrían (`data-open-modal="band"` en el header/panel móvil/hero)
 * ahora apuntan directo a /membresia/ con el texto "Hazte socio/a" — el
 * énfasis del sitio pasa a conseguir socios, no postulaciones de banda. El
 * handler (`cdlr_handle_band_application`) y el markup del modal se dejaron
 * intactos a propósito: para reabrir la convocatoria a futuro, basta con
 * devolver `data-open-modal="band"` a cualquier botón — no hay que reconstruir
 * nada. modals.js sigue soportando el trigger de scroll para el popup de
 * membresía igual que antes.
 */
add_action( 'wp_footer', function () {
	?>
	<div class="cdlr-modal" id="cdlr-modal-band" hidden>
		<div class="cdlr-modal__backdrop" data-modal-close></div>
		<div class="cdlr-modal__panel" role="dialog" aria-modal="true" aria-labelledby="cdlr-band-modal-title">
			<button type="button" class="cdlr-modal__close" data-modal-close aria-label="Cerrar">&times;</button>
			<h2 id="cdlr-band-modal-title" class="cdlr-modal__title">Postula tu banda</h2>
			<p class="cdlr-modal__lead">Cuéntanos de tu proyecto: redes sociales, tu música en plataformas, y adjunta el dossier de la banda.</p>

			<form class="cdlr-form" id="cdlr-band-form" method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" enctype="multipart/form-data" novalidate>
				<input type="hidden" name="action" value="cdlr_band_application">
				<?php wp_nonce_field( 'cdlr_band_application', 'cdlr_band_nonce' ); ?>
				<div class="cdlr-hp" aria-hidden="true">
					<label for="cdlr_website_band">No completar</label>
					<input type="text" id="cdlr_website_band" name="cdlr_website" tabindex="-1" autocomplete="off">
				</div>

				<div class="cdlr-field">
					<label for="cdlr_banda">Nombre de la banda</label>
					<input type="text" id="cdlr_banda" name="cdlr_banda" placeholder="Nombre de tu banda o proyecto" required>
				</div>
				<div class="cdlr-field">
					<label for="cdlr_email_band">Email de contacto</label>
					<input type="email" id="cdlr_email_band" name="cdlr_email" placeholder="Ingresa tu email" required>
				</div>
				<div class="cdlr-field">
					<label for="cdlr_redes_band">Redes sociales</label>
					<textarea id="cdlr_redes_band" name="cdlr_redes" rows="2" placeholder="Instagram, Facebook, TikTok..." required></textarea>
				</div>
				<div class="cdlr-field">
					<label for="cdlr_plataformas_band">Música en plataformas</label>
					<textarea id="cdlr_plataformas_band" name="cdlr_plataformas" rows="2" placeholder="Spotify, YouTube, Bandcamp..." required></textarea>
				</div>
				<div class="cdlr-field">
					<label for="cdlr_dossier">Dossier / press-kit (PDF)</label>
					<input type="file" id="cdlr_dossier" name="cdlr_dossier" accept="application/pdf" data-max-size="104857600" required>
					<small>Máximo 100MB, solo PDF.</small>
				</div>
				<div class="cdlr-field">
					<label for="cdlr_message_band">Mensaje (opcional)</label>
					<textarea id="cdlr_message_band" name="cdlr_message" rows="3" placeholder="¿Algo más que quieras contarnos?"></textarea>
				</div>

				<button type="submit" class="cdlr-btn cdlr-btn--primary cdlr-form__submit">Enviar postulación</button>

				<div id="cdlr-band-form-status" role="status" aria-live="polite" class="cdlr-form__status"></div>
			</form>

			<div class="cdlr-band-pending" id="cdlr-band-pending" hidden>
				<p>¡Recibimos los datos de tu postulación! Si tu dossier pesa harto, puede tardar unos minutos en terminar de subirse — no hace falta que esperes mirando esta ventana.</p>
				<p><strong>Puedes cerrarla tranquilamente:</strong> te vamos a confirmar por correo a <strong id="cdlr-band-pending-email"></strong> apenas quede recibida con éxito.</p>
				<button type="button" class="cdlr-btn cdlr-btn--primary" data-modal-close>Entendido, cerrar</button>
			</div>
		</div>
	</div>

	<?php if ( ! is_page( 'membresia' ) ) : ?>
	<div class="cdlr-modal cdlr-modal--wide" id="cdlr-modal-membresia" hidden>
		<div class="cdlr-modal__backdrop" data-modal-close></div>
		<div class="cdlr-modal__panel" role="dialog" aria-modal="true" aria-labelledby="cdlr-membresia-modal-title">
			<button type="button" class="cdlr-modal__close" data-modal-close aria-label="Cerrar">&times;</button>
			<h2 id="cdlr-membresia-modal-title" class="cdlr-modal__title">Ayúdanos a seguir llevando el rock a las calles</h2>
			<p class="cdlr-modal__lead">Con tu aporte mensual financias los shows gratuitos y La Grúa del Rock en Concepción.</p>

			<div class="cdlr-popup-tiers">
				<article class="cdlr-popup-tier">
					<span class="cdlr-popup-tier__icon"><?php echo cdlr_icon( 'volume' ); ?></span>
					<h3 class="cdlr-popup-tier__name">Amigo</h3>
					<p class="cdlr-popup-tier__price">$5.000 <span>/mes</span></p>
				</article>
				<article class="cdlr-popup-tier">
					<span class="cdlr-popup-tier__icon"><?php echo cdlr_icon( 'handshake' ); ?></span>
					<h3 class="cdlr-popup-tier__name">Colaborador</h3>
					<p class="cdlr-popup-tier__price">$10.000 <span>/mes</span></p>
				</article>
				<article class="cdlr-popup-tier">
					<span class="cdlr-popup-tier__icon"><?php echo cdlr_icon( 'sparkles' ); ?></span>
					<h3 class="cdlr-popup-tier__name">Embajador</h3>
					<p class="cdlr-popup-tier__price">$15.000 <span>/mes</span></p>
				</article>
			</div>

			<div class="cdlr-popup-actions">
				<a class="cdlr-btn cdlr-btn--primary" href="<?php echo esc_url( home_url( '/membresia/' ) ); ?>">Ver todos los planes</a>
				<button type="button" class="cdlr-btn cdlr-btn--ghost" data-modal-close>Ahora no</button>
			</div>
		</div>
	</div>
	<?php endif; ?>
	<?php
} );

/**
 * Postulación de banda: reemplaza el "Postula tu banda" que antes llevaba a
 * /membresia/ (esa página es de aportes, no de postulación). El dossier PDF
 * se guarda en la biblioteca de medios (wp_handle_upload) y el correo manda
 * un link de descarga en vez de llevarlo adjunto: los dossiers reales de las
 * bandas pesan bastante más de lo que cabe en un adjunto de correo (Gmail
 * rechaza sobre ~25MB), así que adjuntarlo directo no escalaba — se detectó
 * cuando una postulación real de 59MB se quedó pegada en "Enviando..." el
 * 2026-07-30 (el límite de entonces era 8MB, pensado para ir de adjunto).
 */
function cdlr_handle_band_application() {
	$is_ajax  = ! empty( $_SERVER['HTTP_X_REQUESTED_WITH'] ) && strtolower( $_SERVER['HTTP_X_REQUESTED_WITH'] ) === 'xmlhttprequest';
	$redirect = wp_get_referer() ? wp_get_referer() : home_url( '/' );

	$fail = function ( $message ) use ( $is_ajax, $redirect ) {
		if ( $is_ajax ) {
			wp_send_json_error( [ 'message' => $message ] );
		}
		wp_safe_redirect( add_query_arg( 'cdlr_band_status', 'error', $redirect ) );
		exit;
	};

	if ( ! isset( $_POST['cdlr_band_nonce'] ) || ! wp_verify_nonce( $_POST['cdlr_band_nonce'], 'cdlr_band_application' ) ) {
		$fail( 'No pudimos validar el formulario, intenta de nuevo.' );
		return;
	}

	// Honeypot: los bots suelen completar todos los campos, incluido este, que está oculto para personas.
	if ( ! empty( $_POST['cdlr_website'] ) ) {
		$fail( 'No se pudo enviar la postulación.' );
		return;
	}

	$banda       = isset( $_POST['cdlr_banda'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_banda'] ) ) : '';
	$email       = isset( $_POST['cdlr_email'] ) ? sanitize_email( wp_unslash( $_POST['cdlr_email'] ) ) : '';
	$redes       = isset( $_POST['cdlr_redes'] ) ? sanitize_textarea_field( wp_unslash( $_POST['cdlr_redes'] ) ) : '';
	$plataformas = isset( $_POST['cdlr_plataformas'] ) ? sanitize_textarea_field( wp_unslash( $_POST['cdlr_plataformas'] ) ) : '';
	$mensaje     = isset( $_POST['cdlr_message'] ) ? sanitize_textarea_field( wp_unslash( $_POST['cdlr_message'] ) ) : '';

	if ( '' === $banda || ! is_email( $email ) || '' === $redes || '' === $plataformas ) {
		$fail( 'Revisa el nombre de la banda, tu email, redes sociales y plataformas de música.' );
		return;
	}

	if ( empty( $_FILES['cdlr_dossier'] ) || UPLOAD_ERR_NO_FILE === $_FILES['cdlr_dossier']['error'] ) {
		$fail( 'Adjunta el dossier de la banda en PDF.' );
		return;
	}
	if ( UPLOAD_ERR_OK !== $_FILES['cdlr_dossier']['error'] ) {
		$fail( 'Hubo un problema subiendo el archivo, intenta de nuevo.' );
		return;
	}

	$max_size = 100 * 1024 * 1024;
	if ( $_FILES['cdlr_dossier']['size'] > $max_size ) {
		$fail( 'El dossier no puede pesar más de 100MB.' );
		return;
	}

	// No confiamos solo en la extensión: se valida el contenido real del
	// archivo (magic bytes) cuando el servidor tiene la extensión fileinfo;
	// si no la tiene, cae a validar por extensión como red de seguridad menor.
	if ( function_exists( 'finfo_open' ) ) {
		$finfo = finfo_open( FILEINFO_MIME_TYPE );
		$mime  = $finfo ? finfo_file( $finfo, $_FILES['cdlr_dossier']['tmp_name'] ) : '';
		if ( $finfo ) {
			finfo_close( $finfo );
		}
	} else {
		$mime = 'pdf' === strtolower( pathinfo( $_FILES['cdlr_dossier']['name'], PATHINFO_EXTENSION ) ) ? 'application/pdf' : '';
	}
	if ( 'application/pdf' !== $mime ) {
		$fail( 'El dossier debe ser un archivo PDF.' );
		return;
	}

	require_once ABSPATH . 'wp-admin/includes/file.php';
	$moved = wp_handle_upload( $_FILES['cdlr_dossier'], [
		'test_form' => false,
		'mimes'     => [ 'pdf' => 'application/pdf' ],
	] );
	if ( ! empty( $moved['error'] ) ) {
		$fail( 'No se pudo procesar el archivo, intenta de nuevo.' );
		return;
	}
	$dossier_url = $moved['url'];

	$subject = sprintf( 'Nueva postulación de banda – %s', $banda );
	$lines   = [
		sprintf( 'Banda: %s', $banda ),
		sprintf( 'Email: %s', $email ),
		'',
		'Redes sociales:',
		$redes,
		'',
		'Música en plataformas:',
		$plataformas,
		'',
		'Dossier:',
		$dossier_url,
	];
	if ( '' !== $mensaje ) {
		$lines[] = '';
		$lines[] = 'Mensaje:';
		$lines[] = $mensaje;
	}

	$sent = wp_mail(
		'corporaciondelaraiz@gmail.com',
		$subject,
		implode( "\n", $lines ),
		[ 'Content-Type: text/plain; charset=UTF-8', sprintf( 'Reply-To: %s <%s>', $banda, $email ) ]
	);

	if ( ! $sent ) {
		$fail( 'No se pudo enviar la postulación, intenta más tarde.' );
		return;
	}

	// Confirmación a la propia banda: como una postulación con dossier pesado
	// puede tardar minutos en subirse, el usuario no se queda esperando frente
	// al popup — este correo es la confirmación real de que quedó recibida.
	wp_mail(
		$email,
		'Recibimos tu postulación – Corporación de la Raíz',
		sprintf(
			"¡Hola!\n\nRecibimos la postulación de %s con éxito. Vamos a revisarla y te contactamos pronto.\n\nGracias por sumarte,\nCorporación de la Raíz",
			$banda
		),
		[ 'Content-Type: text/plain; charset=UTF-8' ]
	);

	if ( $is_ajax ) {
		wp_send_json_success( [ 'message' => '¡Gracias! Vamos a revisar tu postulación y te contactamos pronto.' ] );
	}
	wp_safe_redirect( add_query_arg( 'cdlr_band_status', 'success', $redirect ) );
	exit;
}
add_action( 'admin_post_cdlr_band_application', 'cdlr_handle_band_application' );
add_action( 'admin_post_nopriv_cdlr_band_application', 'cdlr_handle_band_application' );

/**
 * Tipografías propias (Oswald + Montserrat) y el header/footer a medida se
 * cargan en toda la web, ya que ambos aparecen en todas las páginas.
 */
add_action( 'wp_enqueue_scripts', function () {
	wp_enqueue_style(
		'cdlr-fonts',
		'https://fonts.googleapis.com/css2?family=Oswald:wght@500;600;700&family=Montserrat:wght@400;500;600;700&display=swap',
		[],
		null
	);

	$header_css_path = get_stylesheet_directory() . '/assets/css/header.css';
	wp_enqueue_style( 'cdlr-header', get_stylesheet_directory_uri() . '/assets/css/header.css', [ 'astra-child-style' ], file_exists( $header_css_path ) ? filemtime( $header_css_path ) : null );

	$header_js_path = get_stylesheet_directory() . '/assets/js/header.js';
	wp_enqueue_script( 'cdlr-header', get_stylesheet_directory_uri() . '/assets/js/header.js', [], file_exists( $header_js_path ) ? filemtime( $header_js_path ) : null, [ 'strategy' => 'defer', 'in_footer' => true ] );

	$footer_css_path = get_stylesheet_directory() . '/assets/css/footer.css';
	wp_enqueue_style( 'cdlr-footer', get_stylesheet_directory_uri() . '/assets/css/footer.css', [ 'cdlr-header' ], file_exists( $footer_css_path ) ? filemtime( $footer_css_path ) : null );

	$blog_css_path = get_stylesheet_directory() . '/assets/css/blog.css';
	wp_enqueue_style( 'cdlr-blog', get_stylesheet_directory_uri() . '/assets/css/blog.css', [ 'cdlr-header' ], file_exists( $blog_css_path ) ? filemtime( $blog_css_path ) : null );

	// Modales sitewide (postulación de banda + popup de membresía por scroll)
	// — necesitan cargar en cualquier página, no solo donde ya carga premium.js.
	$modals_css_path = get_stylesheet_directory() . '/assets/css/modals.css';
	wp_enqueue_style( 'cdlr-modals', get_stylesheet_directory_uri() . '/assets/css/modals.css', [ 'cdlr-header' ], file_exists( $modals_css_path ) ? filemtime( $modals_css_path ) : null );

	$modals_js_path = get_stylesheet_directory() . '/assets/js/modals.js';
	wp_enqueue_script( 'cdlr-modals', get_stylesheet_directory_uri() . '/assets/js/modals.js', [], file_exists( $modals_js_path ) ? filemtime( $modals_js_path ) : null, [ 'strategy' => 'defer', 'in_footer' => true ] );
	wp_localize_script( 'cdlr-modals', 'cdlrContact', [
		'ajaxUrl' => admin_url( 'admin-post.php' ),
	] );
}, 20 );

/**
 * Home premium: la portada (front-page.php) ya no se construye con Elementor,
 * así que solo carga sus propios assets acá. premium.css/js trae los tokens
 * de diseño (reveal on scroll, contadores, envío del formulario) que también
 * reutiliza la página de membresía.
 */
add_action( 'wp_enqueue_scripts', function () {
	$is_home      = is_front_page();
	$is_membresia = is_page( 'membresia' );
	$is_grua      = is_page( 'la-grua-del-rock' );
	$is_quienes   = is_page( 'quienes-somos' );
	$is_practicas = is_page( 'practicas' );
	$is_noticias  = is_home(); // La página de entradas (home.php) — is_home(), no is_page(), porque WP la trata como el índice del blog, no como una Página normal.
	$is_single    = is_single(); // Una entrada individual (single.php).

	if ( ! $is_home && ! $is_membresia && ! $is_grua && ! $is_quienes && ! $is_practicas && ! $is_noticias && ! $is_single ) {
		return;
	}

	$css_path = get_stylesheet_directory() . '/assets/css/premium.css';
	wp_enqueue_style( 'cdlr-premium', get_stylesheet_directory_uri() . '/assets/css/premium.css', [ 'astra-child-style', 'cdlr-header' ], file_exists( $css_path ) ? filemtime( $css_path ) : null );

	$js_path = get_stylesheet_directory() . '/assets/js/premium.js';
	wp_enqueue_script( 'cdlr-premium', get_stylesheet_directory_uri() . '/assets/js/premium.js', [], file_exists( $js_path ) ? filemtime( $js_path ) : null, [ 'strategy' => 'defer', 'in_footer' => true ] );

	wp_localize_script( 'cdlr-premium', 'cdlrContact', [
		'ajaxUrl' => admin_url( 'admin-post.php' ),
	] );

	// membresia.css trae el hero sin foto (.cdlr-mem-hero) y las tarjetas de
	// plan (.cdlr-plan*) que también reutilizan Quiénes somos y Prácticas.
	if ( $is_membresia || $is_quienes || $is_practicas ) {
		$membresia_css_path = get_stylesheet_directory() . '/assets/css/membresia.css';
		wp_enqueue_style( 'cdlr-membresia', get_stylesheet_directory_uri() . '/assets/css/membresia.css', [ 'cdlr-premium' ], file_exists( $membresia_css_path ) ? filemtime( $membresia_css_path ) : null );
	}

	// membresia.js maneja el clic en las tarjetas de plan (rellenar el campo
	// oculto + scroll al formulario) — Prácticas usa el mismo patrón para
	// elegir área, Quiénes somos no tiene formulario así que no lo necesita.
	if ( $is_membresia || $is_practicas ) {
		$membresia_js_path = get_stylesheet_directory() . '/assets/js/membresia.js';
		wp_enqueue_script( 'cdlr-membresia', get_stylesheet_directory_uri() . '/assets/js/membresia.js', [ 'cdlr-premium' ], file_exists( $membresia_js_path ) ? filemtime( $membresia_js_path ) : null, [ 'strategy' => 'defer', 'in_footer' => true ] );
	}

	if ( $is_grua ) {
		$grua_css_path = get_stylesheet_directory() . '/assets/css/grua-del-rock.css';
		wp_enqueue_style( 'cdlr-grua', get_stylesheet_directory_uri() . '/assets/css/grua-del-rock.css', [ 'cdlr-premium' ], file_exists( $grua_css_path ) ? filemtime( $grua_css_path ) : null );
	}

	if ( $is_quienes ) {
		$quienes_css_path = get_stylesheet_directory() . '/assets/css/quienes-somos.css';
		wp_enqueue_style( 'cdlr-quienes', get_stylesheet_directory_uri() . '/assets/css/quienes-somos.css', [ 'cdlr-membresia' ], file_exists( $quienes_css_path ) ? filemtime( $quienes_css_path ) : null );
	}

	if ( $is_noticias ) {
		$noticias_css_path = get_stylesheet_directory() . '/assets/css/noticias.css';
		wp_enqueue_style( 'cdlr-noticias', get_stylesheet_directory_uri() . '/assets/css/noticias.css', [ 'cdlr-premium' ], file_exists( $noticias_css_path ) ? filemtime( $noticias_css_path ) : null );
	}

	if ( $is_single ) {
		$single_css_path = get_stylesheet_directory() . '/assets/css/single-post.css';
		wp_enqueue_style( 'cdlr-single-post', get_stylesheet_directory_uri() . '/assets/css/single-post.css', [ 'cdlr-premium' ], file_exists( $single_css_path ) ? filemtime( $single_css_path ) : null );
	}
}, 21 );

/**
 * Título/descripción/og:image por página. Sin esto, compartir el link en
 * WhatsApp o redes sociales no mostraba ninguna imagen (detectado en la
 * auditoría del 2026-07-29) — cada entrada usa una foto real ya subida al
 * sitio, no genérica.
 */
add_action( 'wp_head', function () {
	if ( is_front_page() ) {
		$title       = 'Corporación de la Raíz — Transformamos las calles en escenarios';
		$description = 'Corporación cultural sin fines de lucro que impulsa la escena musical emergente de Concepción a través de festivales, producción audiovisual y La Grúa del Rock, nuestro escenario móvil insignia.';
		$image_id    = 58;
		$url         = home_url( '/' );
	} elseif ( is_page( 'membresia' ) ) {
		$title       = 'Membresía — Corporación de la Raíz';
		$description = 'Elige tu plan de membresía y ayuda a financiar los shows gratuitos y La Grúa del Rock en Concepción.';
		$image_id    = 58;
		$url         = home_url( '/membresia/' );
	} elseif ( is_page( 'la-grua-del-rock' ) ) {
		$title       = 'La Grúa del Rock — Corporación de la Raíz';
		$description = 'Un escenario móvil que recorre las calles de Concepción con bandas locales tocando en vivo, directo para quien vaya pasando.';
		$image_id    = 52;
		$url         = home_url( '/la-grua-del-rock/' );
	} elseif ( is_page( 'quienes-somos' ) ) {
		$title       = 'Quiénes somos — Corporación de la Raíz';
		$description = 'Conoce a la corporación cultural sin fines de lucro que impulsa la escena musical emergente de Concepción, y al equipo detrás de La Grúa del Rock.';
		$image_id    = 57;
		$url         = home_url( '/quienes-somos/' );
	} elseif ( is_page( 'practicas' ) ) {
		$title       = 'Prácticas profesionales — Corporación de la Raíz';
		$description = 'Practica en sonido, producción audiovisual o apoyo general a la gestión de la Corporación de la Raíz en Concepción.';
		$image_id    = 56;
		$url         = home_url( '/practicas/' );
	} elseif ( is_home() ) {
		$title       = 'Noticias — Corporación de la Raíz';
		$description = 'Recaps de shows, novedades de nuestros proyectos y todo lo que va pasando en la escena musical de Concepción.';
		$image_id    = 58;
		$url         = home_url( '/noticias/' );
	} elseif ( is_single() ) {
		// Cada entrada usa su propio título/extracto/imagen destacada en vez
		// de un valor fijo — antes las entradas individuales no tenían nada
		// de esto (compartir el link no mostraba ninguna imagen ni resumen).
		$title       = get_the_title() . ' — Corporación de la Raíz';
		$description = wp_trim_words( get_the_excerpt(), 30 );
		$image_id    = get_post_thumbnail_id();
		$url         = get_permalink();
	} else {
		return;
	}

	$image_url = wp_get_attachment_image_url( $image_id, 'large' );

	printf( "\n" . '<meta name="description" content="%1$s">' . "\n", esc_attr( $description ) );
	printf( '<meta property="og:type" content="website">' . "\n" );
	printf( '<meta property="og:title" content="%1$s">' . "\n", esc_attr( $title ) );
	printf( '<meta property="og:description" content="%1$s">' . "\n", esc_attr( $description ) );
	printf( '<meta property="og:url" content="%1$s">' . "\n", esc_url( $url ) );
	if ( $image_url ) {
		printf( '<meta property="og:image" content="%1$s">' . "\n", esc_url( $image_url ) );
	}
}, 1 );

/**
 * page-membresia.php y page-la-grua-del-rock.php son templates a medida
 * igual que front-page.php, así que tienen el mismo problema que resolvió
 * premium.css para la home: no heredan las clases que page.php le da al
 * wrapper de Astra para estirarse a todo el ancho, y el contenido queda
 * boxeado y pegado a la izquierda. Se marcan con una clase propia para poder
 * anular ese boxeado (ver body.cdlr-full-bleed en header.css/membresia.css).
 */
add_filter( 'body_class', function ( $classes ) {
	if ( is_page( 'membresia' ) || is_page( 'la-grua-del-rock' ) || is_page( 'quienes-somos' ) || is_page( 'practicas' ) || is_home() || is_single() ) {
		$classes[] = 'cdlr-full-bleed';
	}
	return $classes;
} );

/**
 * Íconos de línea propios (24x24, stroke=currentColor) para no depender de
 * Font Awesome / Elementor solo para 9 íconos en la portada.
 */
function cdlr_icon( $name, $class = '' ) {
	$paths = [
		'truck'      => '<path d="M1 3h13v13H1z"/><path d="M14 8h4l3 3v5h-7z"/><circle cx="5.5" cy="18.5" r="1.5"/><circle cx="17.5" cy="18.5" r="1.5"/>',
		'camera'     => '<path d="M4 7h3l1.5-2h7L17 7h3a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z"/><circle cx="12" cy="13" r="3.5"/>',
		'megaphone'  => '<path d="M3 10v4a1 1 0 0 0 1 1h2l1 5h2l-1-5h2l8 4V6l-8 4H4a1 1 0 0 0-1 1z"/>',
		'map-pin'    => '<path d="M12 21s7-6.1 7-12a7 7 0 1 0-14 0c0 5.9 7 12 7 12z"/><circle cx="12" cy="9" r="2.5"/>',
		'sparkles'   => '<path d="M12 2l1.8 5.2L19 9l-5.2 1.8L12 16l-1.8-5.2L5 9l5.2-1.8z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
		'guitar'     => '<circle cx="8" cy="16" r="5"/><path d="M11.5 12.5 17 7"/><path d="M15.5 5.5 19 2l3 3-3.5 3.5"/><path d="M14 9l1.5 1.5"/><path d="M16.5 6.5 18 8"/>',
		'signpost'   => '<path d="M12 2v20"/><path d="M12 6H4l2 3-2 3h8"/><path d="M12 12h8l-2 3 2 3h-8"/>',
		'share'      => '<circle cx="6" cy="12" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="18" cy="18" r="2.5"/><path d="M8.2 10.8 15.8 7.2"/><path d="M8.2 13.2l7.6 3.6"/>',
		'calendar'   => '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M8 3v4M16 3v4M3 10h18"/>',
		'volume'     => '<path d="M4 9v6h4l5 4V5L8 9z"/><path d="M17 8a5 5 0 0 1 0 8"/>',
		'disc'       => '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="2.5"/>',
		'handshake'  => '<path d="M2 12l4-3 4 3 3-3 4 3.5"/><path d="M9 12l3 3.5 2-1.5"/><path d="M14 13.5l2 2.5"/><path d="M18 9l4 3-3 4"/>',
		'arrow-right'=> '<path d="M4 12h16"/><path d="M13 5l7 7-7 7"/>',
		'check'      => '<path d="M4 12.5l5 5L20 6.5"/>',
		'ticket'     => '<path d="M3 8a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v2a2 2 0 0 0 0 4v2a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2a2 2 0 0 0 0-4z"/><path d="M12 7v2M12 15v2M12 11v2"/>',
		'vote'       => '<path d="M12 3v6"/><path d="M7 21h10"/><path d="M5 21V10l7-5 7 5v11"/><path d="M9 21v-6h6v6"/>',
		'gift'       => '<rect x="3" y="8" width="18" height="13" rx="1.5"/><path d="M3 12h18"/><path d="M12 8v13"/><path d="M12 8c-1.2-3-3.4-4.5-5-3.5S5.8 8 12 8z"/><path d="M12 8c1.2-3 3.4-4.5 5-3.5S18.2 8 12 8z"/>',
		'store'      => '<path d="M3 9l1.5-5h15L21 9"/><path d="M4 9v11h16V9"/><path d="M9 20v-6h6v6"/>',
		'instagram'  => '<rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.3" cy="6.7" r="0.7" fill="currentColor" stroke="none"/>',
		'tiktok'     => '<path d="M14 3.5v11a3.3 3.3 0 1 1-2.4-3.18"/><path d="M14 3.5c.35 2.75 2.1 4.6 4.6 4.85"/>',
		'youtube'    => '<rect x="2.5" y="5.5" width="19" height="13" rx="4"/><path d="M10.3 9.3v5.4l4.9-2.7z" fill="currentColor" stroke="none"/>',
		'whatsapp'   => '<path d="M12 3a8.5 8.5 0 0 0-7.37 12.75L3.2 21l5.4-1.4A8.5 8.5 0 1 0 12 3z"/><path d="M8.4 10.3c.3 2.85 2.55 5.1 5.4 5.4"/>',
	];

	if ( ! isset( $paths[ $name ] ) ) {
		return '';
	}

	return sprintf(
		'<svg class="cdlr-icon %1$s" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">%2$s</svg>',
		esc_attr( $class ),
		$paths[ $name ]
	);
}

/**
 * Iniciales de un nombre para el badge de avatar de Quiénes somos (no hay
 * fotos reales del equipo todavía).
 */
function cdlr_initials( $name ) {
	$parts    = preg_split( '/\s+/', trim( $name ) );
	$initials = '';
	foreach ( array_slice( $parts, 0, 2 ) as $part ) {
		$initials .= mb_strtoupper( mb_substr( $part, 0, 1 ) );
	}
	return $initials;
}

/**
 * Formulario de contacto nativo (reemplaza el widget de formulario de Pro
 * Elements que usaba la portada) — mismo destinatario que ya estaba
 * configurado en el formulario original. También atiende las postulaciones
 * de /membresia/ y /practicas/: acepta un campo opcional `cdlr_plan` (se
 * agrega al cuerpo del correo, con la etiqueta `cdlr_meta_label` — "Plan" por
 * defecto, para no romper el formulario de membresía que ya estaba en
 * producción) y un `cdlr_subject_type` para el asunto del correo ("membresía"
 * por el mismo motivo). `cdlr_phone`/`cdlr_institution` son opcionales, los
 * usa el formulario de prácticas. `cdlr_redirect` decide a dónde volver tras
 * enviar; wp_safe_redirect ya valida que sea un host propio del sitio, así
 * que cae a home_url('/#sumate') si falta o es inválido.
 */
function cdlr_handle_contact_form() {
	$is_ajax  = ! empty( $_SERVER['HTTP_X_REQUESTED_WITH'] ) && strtolower( $_SERVER['HTTP_X_REQUESTED_WITH'] ) === 'xmlhttprequest';
	$redirect = ! empty( $_POST['cdlr_redirect'] ) ? esc_url_raw( wp_unslash( $_POST['cdlr_redirect'] ) ) : home_url( '/#sumate' );

	$fail = function ( $message ) use ( $is_ajax, $redirect ) {
		if ( $is_ajax ) {
			wp_send_json_error( [ 'message' => $message ] );
		}
		wp_safe_redirect( add_query_arg( 'cdlr_status', 'error', $redirect ) );
		exit;
	};

	if ( ! isset( $_POST['cdlr_contact_nonce'] ) || ! wp_verify_nonce( $_POST['cdlr_contact_nonce'], 'cdlr_contact' ) ) {
		$fail( 'No pudimos validar el formulario, intenta de nuevo.' );
		return;
	}

	// Honeypot: los bots suelen completar todos los campos, incluido este, que está oculto para personas.
	if ( ! empty( $_POST['cdlr_website'] ) ) {
		$fail( 'No se pudo enviar el mensaje.' );
		return;
	}

	$name        = isset( $_POST['cdlr_name'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_name'] ) ) : '';
	$email       = isset( $_POST['cdlr_email'] ) ? sanitize_email( wp_unslash( $_POST['cdlr_email'] ) ) : '';
	$message     = isset( $_POST['cdlr_message'] ) ? sanitize_textarea_field( wp_unslash( $_POST['cdlr_message'] ) ) : '';
	$plan        = isset( $_POST['cdlr_plan'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_plan'] ) ) : '';
	$meta_label  = isset( $_POST['cdlr_meta_label'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_meta_label'] ) ) : 'Plan';
	$subject_type = isset( $_POST['cdlr_subject_type'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_subject_type'] ) ) : 'membresía';
	$phone       = isset( $_POST['cdlr_phone'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_phone'] ) ) : '';
	$institution = isset( $_POST['cdlr_institution'] ) ? sanitize_text_field( wp_unslash( $_POST['cdlr_institution'] ) ) : '';

	if ( '' === $name || ! is_email( $email ) ) {
		$fail( 'Revisa tu nombre y tu email.' );
		return;
	}

	// El formulario de contacto siempre pide mensaje; los de postulación
	// (membresía, prácticas) no, ya vienen con el plan/área elegido, pero
	// igual aceptan uno opcional.
	if ( '' === $plan && '' === $message ) {
		$fail( 'Escríbenos tu mensaje.' );
		return;
	}

	$subject = $plan
		? sprintf( 'Nueva postulación de %s (%s) – %s', $subject_type, $plan, $name )
		: sprintf( 'Nuevo contacto desde la web – %s', $name );

	$lines = [];
	if ( $plan ) {
		$lines[] = sprintf( '%s: %s', $meta_label, $plan );
	}
	$lines[] = sprintf( 'Nombre: %s', $name );
	$lines[] = sprintf( 'Email: %s', $email );
	if ( '' !== $phone ) {
		$lines[] = sprintf( 'Teléfono: %s', $phone );
	}
	if ( '' !== $institution ) {
		$lines[] = sprintf( 'Institución: %s', $institution );
	}
	if ( '' !== $message ) {
		$lines[] = '';
		$lines[] = 'Mensaje:';
		$lines[] = $message;
	}
	$body = implode( "\n", $lines );

	$sent = wp_mail(
		'corporaciondelaraiz@gmail.com',
		$subject,
		$body,
		[ 'Content-Type: text/plain; charset=UTF-8', sprintf( 'Reply-To: %s <%s>', $name, $email ) ]
	);

	if ( ! $sent ) {
		$fail( 'No se pudo enviar el mensaje, intenta más tarde.' );
		return;
	}

	if ( $is_ajax ) {
		wp_send_json_success( [ 'message' => '¡Gracias! Te vamos a contactar pronto.' ] );
	}
	wp_safe_redirect( add_query_arg( 'cdlr_status', 'success', $redirect ) );
	exit;
}
add_action( 'admin_post_cdlr_contact', 'cdlr_handle_contact_form' );
add_action( 'admin_post_nopriv_cdlr_contact', 'cdlr_handle_contact_form' );
