( function () {
	'use strict';

	function initModals() {
		var modals = document.querySelectorAll( '.cdlr-modal' );
		if ( ! modals.length ) {
			return;
		}

		var lastTrigger = null;

		function openModal( modal ) {
			if ( ! modal ) {
				return;
			}
			modals.forEach( function ( other ) {
				if ( other !== modal ) {
					closeModal( other );
				}
			} );
			modal.hidden = false;
			window.requestAnimationFrame( function () {
				modal.classList.add( 'is-open' );
			} );
			var firstField = modal.querySelector( 'input:not([type="hidden"]), textarea, button' );
			if ( firstField ) {
				firstField.focus();
			}
			document.body.classList.add( 'cdlr-modal-open' );
		}

		function closeModal( modal ) {
			if ( ! modal || modal.hidden ) {
				return;
			}
			modal.classList.remove( 'is-open' );
			modal.hidden = true;
			document.body.classList.remove( 'cdlr-modal-open' );
			if ( lastTrigger ) {
				lastTrigger.focus();
				lastTrigger = null;
			}
		}

		document.querySelectorAll( '[data-open-modal]' ).forEach( function ( trigger ) {
			trigger.addEventListener( 'click', function ( event ) {
				var modal = document.getElementById( 'cdlr-modal-' + trigger.dataset.openModal );
				if ( ! modal ) {
					return;
				}
				event.preventDefault();
				lastTrigger = trigger;
				// Si el formulario de este modal quedó en el aviso de "puedes
				// cerrar esto" de una postulación anterior, se vuelve a la
				// vista de formulario en vez de reabrir pegado en ese aviso.
				var form = modal.querySelector( 'form' );
				if ( form && typeof form.cdlrReset === 'function' ) {
					form.cdlrReset();
				}
				openModal( modal );
			} );
		} );

		document.querySelectorAll( '[data-modal-close]' ).forEach( function ( closer ) {
			closer.addEventListener( 'click', function () {
				closeModal( closer.closest( '.cdlr-modal' ) );
			} );
		} );

		document.addEventListener( 'keydown', function ( event ) {
			if ( event.key !== 'Escape' ) {
				return;
			}
			modals.forEach( function ( modal ) {
				if ( ! modal.hidden ) {
					closeModal( modal );
				}
			} );
		} );

		return { open: openModal, close: closeModal, all: modals };
	}

	function initBandForm() {
		var form = document.getElementById( 'cdlr-band-form' );
		if ( ! form ) {
			return;
		}
		var statusEl = document.getElementById( 'cdlr-band-form-status' );
		var submitBtn = form.querySelector( '.cdlr-form__submit' );
		var fileInput = document.getElementById( 'cdlr_dossier' );
		var emailInput = document.getElementById( 'cdlr_email_band' );
		var pendingEl = document.getElementById( 'cdlr-band-pending' );
		var pendingEmailEl = document.getElementById( 'cdlr-band-pending-email' );

		function resetToForm() {
			form.hidden = false;
			if ( pendingEl ) {
				pendingEl.hidden = true;
			}
			statusEl.classList.remove( 'is-success', 'is-error' );
			statusEl.textContent = '';
		}

		// initModals() llama esto al reabrir el modal, para no dejarlo pegado
		// en el aviso de "puedes cerrar esto" de una postulación anterior.
		form.cdlrReset = resetToForm;

		form.addEventListener( 'submit', function ( event ) {
			if ( ! window.fetch || typeof window.cdlrContact === 'undefined' ) {
				return; // sin JS/fetch, el formulario igual funciona por submit normal.
			}

			// Tamaño y extensión se revisan ANTES de subir: si no, con un
			// archivo grande y una conexión lenta el usuario espera varios
			// minutos para recién enterarse de que pesaba demasiado o era el
			// tipo equivocado (así se detectó este caso real).
			var file = fileInput && fileInput.files && fileInput.files[ 0 ];
			if ( file ) {
				var maxSize = parseInt( fileInput.dataset.maxSize, 10 );
				if ( maxSize && file.size > maxSize ) {
					event.preventDefault();
					statusEl.classList.remove( 'is-success' );
					statusEl.classList.add( 'is-error' );
					statusEl.textContent = 'El dossier no puede pesar más de ' + Math.round( maxSize / 1024 / 1024 ) + 'MB.';
					return;
				}
				if ( ! /\.pdf$/i.test( file.name ) ) {
					event.preventDefault();
					statusEl.classList.remove( 'is-success' );
					statusEl.classList.add( 'is-error' );
					statusEl.textContent = 'El dossier debe ser un archivo PDF.';
					return;
				}
			}

			event.preventDefault();

			if ( submitBtn ) {
				submitBtn.disabled = true;
			}

			// No se deja al usuario esperando frente al popup: subir un
			// dossier pesado puede tardar minutos por su propia conexión, algo
			// que la página no puede acelerar. Se avisa que puede cerrar la
			// ventana tranquilo — la confirmación real llega por correo
			// cuando el servidor termine de recibirla (ver
			// cdlr_handle_band_application, que le manda un correo a la banda
			// además del aviso interno).
			if ( pendingEmailEl ) {
				pendingEmailEl.textContent = emailInput && emailInput.value ? emailInput.value : 'tu correo';
			}
			form.hidden = true;
			if ( pendingEl ) {
				pendingEl.hidden = false;
			}

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
					if ( data && data.success ) {
						form.reset();
						return;
					}
					// Si ya cerró el modal esto no se ve — caso raro, casi
					// todo ya se validó antes de llegar hasta acá.
					resetToForm();
					statusEl.classList.add( 'is-error' );
					statusEl.textContent = data && data.data && data.data.message ? data.data.message : 'Revisa tus datos e intenta de nuevo.';
				} )
				.catch( function () {
					resetToForm();
					statusEl.classList.add( 'is-error' );
					statusEl.textContent = 'No se pudo enviar, revisa tu conexión e intenta de nuevo.';
				} )
				.finally( function () {
					if ( submitBtn ) {
						submitBtn.disabled = false;
					}
				} );
		} );
	}

	function initMembershipPopup( modals ) {
		var modal = document.getElementById( 'cdlr-modal-membresia' );
		if ( ! modal || ! modals ) {
			return;
		}

		var STORAGE_KEY = 'cdlrMembershipPopupShown';
		try {
			if ( window.sessionStorage.getItem( STORAGE_KEY ) ) {
				return;
			}
		} catch ( e ) {
			// Storage bloqueado (modo privado, etc.) — se muestra igual, sin recordar.
		}

		var triggered = false;

		function maybeShow() {
			if ( triggered || document.body.classList.contains( 'cdlr-modal-open' ) ) {
				return;
			}
			var scrolled = window.scrollY + window.innerHeight;
			var pageHeight = document.documentElement.scrollHeight;
			if ( scrolled < pageHeight * 0.5 ) {
				return;
			}
			triggered = true;
			window.removeEventListener( 'scroll', maybeShow );
			modals.open( modal );
			try {
				window.sessionStorage.setItem( STORAGE_KEY, '1' );
			} catch ( e ) {
				// Ignorar si no hay storage disponible.
			}
		}

		window.addEventListener( 'scroll', maybeShow, { passive: true } );
	}

	function init() {
		var modals = initModals();
		initBandForm();
		initMembershipPopup( modals );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', init );
	} else {
		init();
	}
} )();
