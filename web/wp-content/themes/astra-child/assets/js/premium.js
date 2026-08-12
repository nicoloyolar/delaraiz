( function () {
	'use strict';

	var reduceMotion = window.matchMedia && window.matchMedia( '(prefers-reduced-motion: reduce)' ).matches;

	function animateCounter( el ) {
		var target = parseFloat( el.dataset.count, 10 );
		var suffix = el.dataset.suffix || '';

		if ( reduceMotion || isNaN( target ) ) {
			el.textContent = target + suffix;
			return;
		}

		var duration = 1200;
		var start = null;

		function step( timestamp ) {
			if ( start === null ) {
				start = timestamp;
			}
			var progress = Math.min( ( timestamp - start ) / duration, 1 );
			var eased = 1 - Math.pow( 1 - progress, 3 );
			el.textContent = Math.round( eased * target ) + suffix;
			if ( progress < 1 ) {
				window.requestAnimationFrame( step );
			}
		}

		window.requestAnimationFrame( step );
	}

	function initReveal() {
		var revealEls = document.querySelectorAll( '[data-reveal]' );
		var counters = document.querySelectorAll( '[data-count]' );

		if ( ! ( 'IntersectionObserver' in window ) ) {
			revealEls.forEach( function ( el ) {
				el.classList.add( 'is-visible' );
			} );
			counters.forEach( animateCounter );
			return;
		}

		var revealObserver = new IntersectionObserver(
			function ( entries, observer ) {
				entries.forEach( function ( entry ) {
					if ( entry.isIntersecting ) {
						entry.target.classList.add( 'is-visible' );
						observer.unobserve( entry.target );
					}
				} );
			},
			{ threshold: 0.15 }
		);
		revealEls.forEach( function ( el ) {
			revealObserver.observe( el );
		} );

		var countObserver = new IntersectionObserver(
			function ( entries, observer ) {
				entries.forEach( function ( entry ) {
					if ( entry.isIntersecting ) {
						animateCounter( entry.target );
						observer.unobserve( entry.target );
					}
				} );
			},
			{ threshold: 0.6 }
		);
		counters.forEach( function ( el ) {
			countObserver.observe( el );
		} );
	}

	function initContactForm() {
		var form = document.getElementById( 'cdlr-contact-form' );
		if ( ! form ) {
			return;
		}
		var statusEl = document.getElementById( 'cdlr-form-status' );
		var submitBtn = form.querySelector( '.cdlr-form__submit' );

		form.addEventListener( 'submit', function ( event ) {
			if ( ! window.fetch || typeof window.cdlrContact === 'undefined' ) {
				return; // deja que el navegador haga el submit normal (funciona sin JS)
			}
			event.preventDefault();

			if ( submitBtn ) {
				submitBtn.disabled = true;
			}
			statusEl.classList.remove( 'is-success', 'is-error' );
			statusEl.textContent = 'Enviando...';

			fetch( cdlrContact.ajaxUrl, {
				method: 'POST',
				credentials: 'same-origin',
				headers: { 'X-Requested-With': 'XMLHttpRequest' },
				body: new FormData( form ),
			} )
				.then( function ( response ) {
					return response.json();
				} )
				.then( function ( data ) {
					var ok = !! ( data && data.success );
					statusEl.textContent = data && data.data && data.data.message ? data.data.message : ( ok ? '¡Gracias! Te vamos a contactar pronto.' : 'Revisa tus datos e intenta de nuevo.' );
					statusEl.classList.add( ok ? 'is-success' : 'is-error' );
					if ( ok ) {
						form.reset();
					}
				} )
				.catch( function () {
					form.submit();
				} )
				.finally( function () {
					if ( submitBtn ) {
						submitBtn.disabled = false;
					}
				} );
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', function () {
			initReveal();
			initContactForm();
		} );
	} else {
		initReveal();
		initContactForm();
	}
} )();
