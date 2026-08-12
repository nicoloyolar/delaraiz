<?php
/**
 * Página de Membresía — mismo sistema de diseño premium 100% código que la
 * portada (front-page.php). WordPress la sirve automáticamente para la
 * página con slug "membresia" (page-membresia.php tiene prioridad sobre
 * page.php en la jerarquía de plantillas).
 *
 * Excluida del caché de página (LiteSpeed) a propósito: el formulario lleva
 * un nonce de WordPress embebido en el HTML, que vence a las ~24-48h. Si
 * LiteSpeed sirve una copia cacheada más vieja que eso, el formulario falla
 * siempre con "revisa tus datos" sin importar lo que se escriba — pasó en
 * producción el 2026-08-06 (dos días sin purgar caché desde el último
 * despliegue). Sin esto, cualquier deploy que no purgue caché de inmediato
 * vuelve a romper el formulario apenas venza el nonce.
 */
nocache_headers();
if ( function_exists( 'do_action' ) ) {
	do_action( 'litespeed_control_set_nocache', 'cdlr-membresia-form-nonce' );
}

get_header();

$status = isset( $_GET['cdlr_status'] ) ? sanitize_key( wp_unslash( $_GET['cdlr_status'] ) ) : '';
?>

<main id="cdlr-main" class="cdlr-home cdlr-membresia">

	<section class="cdlr-mem-hero">
		<div class="cdlr-container" data-reveal>
			<p class="cdlr-eyebrow">Financia el circuito de la Grúa del Rock</p>
			<h1 class="cdlr-mem-hero__title">Sé parte de la <span>revolución cultural</span></h1>
			<p class="cdlr-hero__lead">Elige tu plan de membresía y ayuda a llevar shows gratuitos, en vivo y sin filtros, a las calles de Concepción.</p>
			<div class="cdlr-hero__actions">
				<a class="cdlr-btn cdlr-btn--primary" href="#planes">Ver los planes</a>
				<a class="cdlr-btn cdlr-btn--link" href="#faq">Preguntas frecuentes <?php echo cdlr_icon( 'arrow-right' ); ?></a>
			</div>
		</div>
	</section>

	<section class="cdlr-plans" id="planes">
		<div class="cdlr-container">
			<h2 class="cdlr-section-title" data-reveal>Elige tu plan</h2>
			<p class="cdlr-plans__lead" data-reveal>Todos los planes aportan directo a la producción de shows gratuitos y a mantener La Grúa del Rock en movimiento.</p>

			<div class="cdlr-plans__grid">

				<article class="cdlr-plan" data-reveal>
					<span class="cdlr-plan__icon"><?php echo cdlr_icon( 'volume' ); ?></span>
					<h3 class="cdlr-plan__name">Amigo</h3>
					<p class="cdlr-plan__price"><span>$5.000</span> /mes</p>
					<ul class="cdlr-plan__list">
						<li><?php echo cdlr_icon( 'check' ); ?> Credencial digital de miembro</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Newsletter exclusivo</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Sorteos exclusivos (4 al año)</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Reconocimiento digital y en créditos de producciones</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Acceso limitado al encuentro anual de miembros</li>
						<li><?php echo cdlr_icon( 'check' ); ?> 50% de descuento en charlas y seminarios exclusivos (5 al año)</li>
						<li><?php echo cdlr_icon( 'ticket' ); ?> 50% de descuento en Sesiones De La Raíz (5 al año)</li>
					</ul>
					<button type="button" class="cdlr-btn cdlr-btn--ghost cdlr-plan__cta" data-plan="amigo" data-plan-label="Amigo ($5.000/mes)">Quiero ser Amigo/a</button>
				</article>

				<article class="cdlr-plan cdlr-plan--featured" data-reveal>
					<span class="cdlr-plan__badge">Más elegido</span>
					<span class="cdlr-plan__icon"><?php echo cdlr_icon( 'handshake' ); ?></span>
					<h3 class="cdlr-plan__name">Colaborador</h3>
					<p class="cdlr-plan__price"><span>$10.000</span> /mes</p>
					<p class="cdlr-plan__includes">Todo lo de Amigo, más:</p>
					<ul class="cdlr-plan__list">
						<li><?php echo cdlr_icon( 'check' ); ?> Acceso completo al encuentro anual de miembros</li>
						<li><?php echo cdlr_icon( 'check' ); ?> Charlas y seminarios exclusivos sin costo (5 al año)</li>
						<li><?php echo cdlr_icon( 'ticket' ); ?> Acceso gratuito a Sesiones De La Raíz (5 al año)</li>
						<li><?php echo cdlr_icon( 'vote' ); ?> Derecho a voto para elegir las bandas de La Grúa del Rock</li>
					</ul>
					<button type="button" class="cdlr-btn cdlr-btn--primary cdlr-plan__cta" data-plan="colaborador" data-plan-label="Colaborador ($10.000/mes)">Quiero ser Colaborador/a</button>
				</article>

				<article class="cdlr-plan" data-reveal>
					<span class="cdlr-plan__icon"><?php echo cdlr_icon( 'sparkles' ); ?></span>
					<h3 class="cdlr-plan__name">Embajador</h3>
					<p class="cdlr-plan__price"><span>$15.000</span> /mes</p>
					<p class="cdlr-plan__includes">Todo lo de Colaborador, más:</p>
					<ul class="cdlr-plan__list">
						<li><?php echo cdlr_icon( 'ticket' ); ?> Acceso a Sesiones De La Raíz + 1 acompañante</li>
						<li><?php echo cdlr_icon( 'store' ); ?> Beneficios en locales adheridos</li>
						<li><?php echo cdlr_icon( 'sparkles' ); ?> Actividad musical exclusiva para Embajadores</li>
						<li><?php echo cdlr_icon( 'gift' ); ?> Regalo de aniversario (al cumplir 12 meses y luego cada 12 meses)</li>
					</ul>
					<button type="button" class="cdlr-btn cdlr-btn--ghost cdlr-plan__cta" data-plan="embajador" data-plan-label="Embajador ($15.000/mes)">Quiero ser Embajador/a</button>
				</article>

			</div>
		</div>
	</section>

	<section class="cdlr-impact" aria-label="Impacto de tu aporte">
		<div class="cdlr-container cdlr-impact__inner" data-reveal>
			<p class="cdlr-impact__figure">100%</p>
			<p class="cdlr-impact__text">de tus aportes van a la producción de shows gratuitos en Concepción.</p>
			<a class="cdlr-btn cdlr-btn--ghost" href="<?php echo esc_url( home_url( '/#historia' ) ); ?>">Conoce más de nuestro impacto cultural <?php echo cdlr_icon( 'arrow-right' ); ?></a>
		</div>
	</section>

	<section class="cdlr-faq" id="faq">
		<div class="cdlr-container">
			<h2 class="cdlr-section-title" data-reveal>Preguntas frecuentes</h2>
			<div class="cdlr-faq__list" data-reveal>
				<details class="cdlr-faq__item">
					<summary>¿Cómo se usa mi aporte?</summary>
					<p>Tu aporte mensual financia directamente la producción de shows gratuitos, el mantenimiento de La Grúa del Rock y la gestión cultural de la Corporación.</p>
				</details>
				<details class="cdlr-faq__item">
					<summary>¿Puedo cambiar de plan más adelante?</summary>
					<p>Sí. Escríbenos indicando el plan al que quieres cambiarte y te ayudamos con el proceso.</p>
				</details>
				<details class="cdlr-faq__item">
					<summary>¿Cómo se realiza el pago mensual?</summary>
					<p>Se cobra automáticamente cada mes a la tarjeta que registras al postular, a través de Flow. Puedes escribirnos a corporaciondelaraiz@gmail.com para cancelar o cambiar de plan cuando quieras.</p>
				</details>
				<details class="cdlr-faq__item">
					<summary>¿Puedo aportar con un monto distinto a los planes?</summary>
					<p>Por supuesto. Cuéntanos en el formulario y buscamos la forma de sumarte al movimiento.</p>
				</details>
			</div>
		</div>
	</section>

	<section class="cdlr-cta" id="postula">
		<div class="cdlr-container cdlr-cta__grid">

			<div class="cdlr-cta__reasons" data-reveal>
				<h2 class="cdlr-section-title">Postula tu membresía</h2>
				<p>Completa tus datos y te llevamos a pagar de forma segura con Flow. Tu membresía se activa apenas se confirme el pago.</p>
				<p class="cdlr-plan-selected" id="cdlr-plan-selected" hidden>Plan seleccionado: <strong id="cdlr-plan-selected-name"></strong></p>
			</div>

			<div class="cdlr-cta__form-wrap" data-reveal>
				<form class="cdlr-form" id="cdlr-contact-form" method="post" action="<?php echo esc_url( admin_url( 'admin-post.php' ) ); ?>" novalidate>
					<input type="hidden" name="action" value="cdlr_flow_subscribe">
					<input type="hidden" name="cdlr_plan" id="cdlr_plan" value="">
					<?php wp_nonce_field( 'cdlr_flow_subscribe', 'cdlr_flow_nonce' ); ?>
					<div class="cdlr-hp" aria-hidden="true">
						<label for="cdlr_website_mem">No completar</label>
						<input type="text" id="cdlr_website_mem" name="cdlr_website" tabindex="-1" autocomplete="off">
					</div>

					<div class="cdlr-field">
						<label for="cdlr_name_mem">Nombre</label>
						<input type="text" id="cdlr_name_mem" name="cdlr_name" placeholder="Ingresa tu nombre" required>
					</div>
					<div class="cdlr-field">
						<label for="cdlr_email_mem">Email</label>
						<input type="email" id="cdlr_email_mem" name="cdlr_email" placeholder="Ingresa tu email" required>
					</div>

					<button type="submit" class="cdlr-btn cdlr-btn--primary cdlr-form__submit">Ir a pagar con Flow</button>

					<div id="cdlr-form-status" role="status" aria-live="polite" class="cdlr-form__status<?php echo $status ? ' is-' . esc_attr( $status ) : ''; ?>">
						<?php if ( 'error' === $status ) : ?>
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
