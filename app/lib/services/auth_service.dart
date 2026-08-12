import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación para el acceso al Dashboard administrativo.
///
/// Se usa Firebase Auth con correo/contraseña: las cuentas de la directiva
/// de la corporación se crean manualmente desde la Consola de Firebase
/// (no hay auto-registro público, ya que el dashboard es de uso interno).
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Emite el usuario autenticado actual (o `null`) en cada cambio de
  /// sesión. El router lo usa como guardia de las rutas `/admin/*`.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  /// Traduce los códigos de error de Firebase Auth a mensajes legibles
  /// para la directiva de la corporación (no todos son técnicos).
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
      default:
        return 'No se pudo iniciar sesión. Intenta nuevamente.';
    }
  }
}
