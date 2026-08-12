( function () {
	'use strict';

	var header = document.getElementById( 'cdlr-header' );
	var toggle = document.getElementById( 'cdlr-header-toggle' );
	var panel = document.getElementById( 'cdlr-mobile-panel' );

	function onScroll() {
		if ( ! header ) {
			return;
		}
		if ( window.scrollY > 8 ) {
			header.classList.add( 'is-scrolled' );
		} else {
			header.classList.remove( 'is-scrolled' );
		}
	}

	if ( header ) {
		onScroll();
		window.addEventListener( 'scroll', onScroll, { passive: true } );
	}

	if ( ! toggle || ! panel ) {
		return;
	}

	function closePanel() {
		toggle.setAttribute( 'aria-expanded', 'false' );
		panel.classList.remove( 'is-open' );
		panel.hidden = true;
	}

	function openPanel() {
		panel.hidden = false;
		window.requestAnimationFrame( function () {
			panel.classList.add( 'is-open' );
		} );
		toggle.setAttribute( 'aria-expanded', 'true' );
	}

	toggle.addEventListener( 'click', function () {
		var isOpen = toggle.getAttribute( 'aria-expanded' ) === 'true';
		if ( isOpen ) {
			closePanel();
		} else {
			openPanel();
		}
	} );

	document.addEventListener( 'keydown', function ( event ) {
		if ( event.key === 'Escape' && toggle.getAttribute( 'aria-expanded' ) === 'true' ) {
			closePanel();
			toggle.focus();
		}
	} );

	document.addEventListener( 'click', function ( event ) {
		if ( toggle.getAttribute( 'aria-expanded' ) !== 'true' ) {
			return;
		}
		if ( ! panel.contains( event.target ) && ! toggle.contains( event.target ) ) {
			closePanel();
		}
	} );

	// Si cambia a desktop con el panel abierto, se cierra para no dejarlo huérfano.
	window.addEventListener( 'resize', function () {
		if ( window.innerWidth > 897 && toggle.getAttribute( 'aria-expanded' ) === 'true' ) {
			closePanel();
		}
	} );
} )();
