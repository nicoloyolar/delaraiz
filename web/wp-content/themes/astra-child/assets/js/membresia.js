( function () {
	'use strict';

	function initPlanButtons() {
		// Incluye tanto las 3 tarjetas de plan fijo como el botón discreto
		// "Elige tu propio monto" (mismo comportamiento de selección, el
		// monto personalizado se maneja aparte más abajo).
		var buttons        = document.querySelectorAll( '.cdlr-plan__cta, #cdlr-plan-custom-btn' );
		var planInput      = document.getElementById( 'cdlr_plan' );
		var selectedWrap   = document.getElementById( 'cdlr-plan-selected' );
		var selectedName   = document.getElementById( 'cdlr-plan-selected-name' );
		var formSection    = document.getElementById( 'postula' );
		var montoWrap      = document.getElementById( 'cdlr-monto-personalizado-wrap' );
		var montoInput     = document.getElementById( 'cdlr_monto_personalizado_input' );

		if ( ! buttons.length || ! planInput ) {
			return;
		}

		buttons.forEach( function ( button ) {
			button.addEventListener( 'click', function () {
				var plan          = button.dataset.plan || '';
				var planLabel     = button.dataset.planLabel || plan;
				var esPersonalizado = 'personalizado' === plan;

				planInput.value = plan;

				if ( selectedName ) {
					selectedName.textContent = planLabel;
				}
				if ( selectedWrap ) {
					selectedWrap.hidden = false;
				}

				// El campo de monto solo es obligatorio (y visible) cuando se
				// eligió "otro monto" — para los 3 planes fijos queda oculto y
				// sin required, así no bloquea el envío del formulario.
				if ( montoWrap && montoInput ) {
					montoWrap.hidden = ! esPersonalizado;
					montoInput.required = esPersonalizado;
					if ( esPersonalizado ) {
						montoInput.focus();
					}
				}

				if ( formSection && formSection.scrollIntoView ) {
					formSection.scrollIntoView( { behavior: 'smooth', block: 'start' } );
				}
			} );
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', initPlanButtons );
	} else {
		initPlanButtons();
	}
} )();
