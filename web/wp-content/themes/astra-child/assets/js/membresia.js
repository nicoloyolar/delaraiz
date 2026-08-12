( function () {
	'use strict';

	function initPlanButtons() {
		var buttons      = document.querySelectorAll( '.cdlr-plan__cta' );
		var planInput    = document.getElementById( 'cdlr_plan' );
		var selectedWrap = document.getElementById( 'cdlr-plan-selected' );
		var selectedName = document.getElementById( 'cdlr-plan-selected-name' );
		var formSection  = document.getElementById( 'postula' );

		if ( ! buttons.length || ! planInput ) {
			return;
		}

		buttons.forEach( function ( button ) {
			button.addEventListener( 'click', function () {
				var plan      = button.dataset.plan || '';
				var planLabel = button.dataset.planLabel || plan;

				planInput.value = plan;

				if ( selectedName ) {
					selectedName.textContent = planLabel;
				}
				if ( selectedWrap ) {
					selectedWrap.hidden = false;
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
