import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación, usado por dos flujos bien distintos:
///
/// - **Dashboard administrativo** (`/admin/*`): las cuentas de la directiva
///   se crean manualmente desde la Consola de Firebase, sin auto-registro
///   — solo usan [signIn].
/// - **Credencial digital del socio** (`/credencial`, agregado 2026-08-12):
///   sí permite auto-registro vía [crearCuenta], porque no sería viable
///   crear a mano la cuenta de cada socio que se suscribe en `/membresia/`.
///   Un socio autenticado NO obtiene acceso admin solo por tener una cuenta
///   — eso lo decide `firestore.rules` (`esAdminActivo()`, que exige un
///   documento en `usuarios/{uid}` con `rol: "admin"`, algo que un socio
///   autoregistrado nunca tiene).
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emite el usuario autenticado actual (o `null`) en cada cambio de
  /// sesión. El router lo usa como guardia de las rutas `/admin/*`, y la
  /// pantalla de credencial lo usa para saber si mostrar el login/registro
  /// o la credencial ya activa.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Auto-registro para socios — usar el mismo correo con el que se
  /// suscribió en `/membresia/`, para que la app pueda encontrar su
  /// credencial en Firestore (ver `CredencialService`).
  Future<UserCredential> crearCuenta({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  /// Traduce los códigos de error de Firebase Auth a mensajes legibles.
  /// Cubre tanto códigos de inicio de sesión (dashboard admin) como de
  /// registro (credencial de socio).
  String mensajeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo ingresado no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta nuevamente en unos minutos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo — intenta iniciar sesión en vez de crear una nueva.';
      case 'weak-password':
        return 'La contraseña es muy débil — usa al menos 6 caracteres.';
      default:
        return 'No se pudo completar la operación. Intenta nuevamente.';
    }
  }
}
