import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../screens/admin/banda_detail_screen.dart';
import '../screens/admin/documentacion_screen.dart';
import '../screens/admin/equipo/equipo_list_screen.dart';
import '../screens/admin/espacios/espacio_detail_screen.dart';
import '../screens/admin/espacios/espacios_list_screen.dart';
import '../screens/admin/financiamiento/fondo_detail_screen.dart';
import '../screens/admin/financiamiento/financiamiento_list_screen.dart';
import '../screens/admin/login_screen.dart';
import '../screens/admin/proyectos/proyecto_detail_screen.dart';
import '../screens/admin/proyectos/proyectos_list_screen.dart';
import '../screens/admin/resumen_screen.dart';
import '../screens/public/postulacion_form_screen.dart';

/// Adapta un `Stream` (en este caso, los cambios de sesión de Firebase
/// Auth) a un `Listenable`, que es lo que `go_router` necesita para
/// re-evaluar sus `redirect` cada vez que cambia el estado de auth.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Rutas de la aplicación:
/// - `/` : formulario público de postulación (sin autenticación).
/// - `/admin/login` : acceso de la directiva de la corporación.
/// - `/admin` : Resumen ejecutivo con KPIs de todos los módulos (protegida).
/// - `/admin/proyectos`, `/admin/proyectos/:id` : gestión de Proyectos.
/// - `/admin/espacios`, `/admin/espacios/:id` : Espacios recuperados.
/// - `/admin/equipo` : directorio de Equipo y Voluntarios.
/// - `/admin/financiamiento`, `/admin/financiamiento/:id` : Fondos.
/// - `/admin/documentos` : documentación institucional.
/// - `/admin/banda/:id` : detalle de una postulación de banda.
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authNotifier = _AuthChangeNotifier(authService.authStateChanges);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final estaAutenticado = authService.currentUser != null;
      final vaAlLogin = state.matchedLocation == '/admin/login';
      final esRutaAdmin = state.matchedLocation.startsWith('/admin');

      if (esRutaAdmin && !vaAlLogin && !estaAutenticado) {
        return '/admin/login';
      }
      if (vaAlLogin && estaAutenticado) {
        return '/admin';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PostulacionFormScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const ResumenScreen(),
      ),
      GoRoute(
        path: '/admin/proyectos',
        builder: (context, state) => const ProyectosListScreen(),
      ),
      GoRoute(
        path: '/admin/proyectos/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProyectoDetailScreen(proyectoId: id);
        },
      ),
      GoRoute(
        path: '/admin/espacios',
        builder: (context, state) => const EspaciosListScreen(),
      ),
      GoRoute(
        path: '/admin/espacios/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EspacioDetailScreen(espacioId: id);
        },
      ),
      GoRoute(
        path: '/admin/equipo',
        builder: (context, state) => const EquipoListScreen(),
      ),
      GoRoute(
        path: '/admin/financiamiento',
        builder: (context, state) => const FinanciamientoListScreen(),
      ),
      GoRoute(
        path: '/admin/financiamiento/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FondoDetailScreen(fondoId: id);
        },
      ),
      GoRoute(
        path: '/admin/banda/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BandaDetailScreen(bandaId: id);
        },
      ),
      GoRoute(
        path: '/admin/documentos',
        builder: (context, state) => const DocumentacionScreen(),
      ),
    ],
  );
});
