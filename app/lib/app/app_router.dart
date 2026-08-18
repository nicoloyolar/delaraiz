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
import '../screens/admin/cupones/cupones_list_screen.dart';
import '../screens/admin/resumen_screen.dart';
import '../screens/admin/socios/socios_list_screen.dart';
import '../screens/public/credencial_screen.dart';
import '../screens/public/postulacion_form_screen.dart';
import '../widgets/admin_shell.dart';

/// A qué `AdminRoute` (para resaltar el ítem activo del sidebar)
/// corresponde una ubicación de `/admin/*`. Vive acá y no en cada
/// pantalla porque, desde el `ShellRoute` de abajo, es el propio router
/// el que sabe en qué sección está — las pantallas ya no arman su propio
/// `AdminShell`.
AdminRoute _adminRouteDeUbicacion(String location) {
  if (location.startsWith('/admin/proyectos')) return AdminRoute.proyectos;
  if (location.startsWith('/admin/espacios')) return AdminRoute.espacios;
  if (location.startsWith('/admin/equipo')) return AdminRoute.equipo;
  if (location.startsWith('/admin/financiamiento')) return AdminRoute.financiamiento;
  if (location.startsWith('/admin/socios')) return AdminRoute.socios;
  if (location.startsWith('/admin/cupones')) return AdminRoute.cupones;
  if (location.startsWith('/admin/documentos')) return AdminRoute.documentos;
  return AdminRoute.resumen;
}

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

// Ya existe una cuenta admin real (nicolas.iloyolar@gmail.com, Firebase Auth
// + documento `usuarios/{uid}` con rol admin, creados 2026-08-18 al conectar
// el proyecto real `delaraiz-app`) — el bypass queda apagado. `/admin/*`
// ahora exige sesión real, como corresponde en producción.
const bool _omitirAutenticacionTemporalmente = false;

/// Rutas de la aplicación:
/// - `/` : formulario público de postulación (sin autenticación).
/// - `/credencial` : credencial digital del socio (login/registro propio,
///   sin relación con el acceso admin — agregado 2026-08-12).
/// - `/admin/login` : acceso de la directiva de la corporación.
/// - `/admin` : Resumen ejecutivo con KPIs de todos los módulos (protegida).
/// - `/admin/proyectos`, `/admin/proyectos/:id` : gestión de Proyectos.
/// - `/admin/espacios`, `/admin/espacios/:id` : Espacios recuperados.
/// - `/admin/equipo` : directorio de Equipo y Voluntarios.
/// - `/admin/financiamiento`, `/admin/financiamiento/:id` : Fondos.
/// - `/admin/socios` : mantenedor de Socios (aportes vía Flow, moderación
///   manual — agregado 2026-08-14).
/// - `/admin/documentos` : documentación institucional.
/// - `/admin/banda/:id` : detalle de una postulación de banda.
final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authNotifier = _AuthChangeNotifier(authService.authStateChanges);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    // El punto de entrada es el panel administrativo (protegido por el
    // `redirect` de abajo, que manda a `/admin/login` si no hay sesión).
    // El formulario público sigue disponible en "/" para compartir como
    // enlace externo a las bandas, pero ya no es lo primero que se ve al
    // abrir la app.
    initialLocation: '/admin',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Con el bypass temporal activo, se trata como si siempre hubiera
      // sesión — así el login queda inalcanzable en ambos sentidos (no
      // solo "no te manda al login", sino "te saca si ya estabas ahí").
      final estaAutenticado =
          authService.currentUser != null || _omitirAutenticacionTemporalmente;
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
        path: '/credencial',
        builder: (context, state) => const CredencialScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      // Las 6 secciones "de lista" del panel comparten el mismo `AdminShell`
      // (sidebar) como widget persistente — antes cada pantalla armaba su
      // propia copia del sidebar, así que `go_router` la reconstruía entera
      // (con animación de transición de página) cada vez que se navegaba
      // entre secciones, y eso era el "salto" al cambiar de pantalla.
      // `NoTransitionPage` además saca la animación de deslizamiento del
      // contenido interno, para que el cambio se sienta instantáneo, como
      // cambiar de tab — no como abrir una página nueva.
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(
            currentRoute: _adminRouteDeUbicacion(state.matchedLocation),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ResumenScreen()),
          ),
          GoRoute(
            path: '/admin/proyectos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProyectosListScreen()),
          ),
          GoRoute(
            path: '/admin/espacios',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EspaciosListScreen()),
          ),
          GoRoute(
            path: '/admin/equipo',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EquipoListScreen()),
          ),
          GoRoute(
            path: '/admin/financiamiento',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FinanciamientoListScreen()),
          ),
          GoRoute(
            path: '/admin/socios',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SociosListScreen()),
          ),
          GoRoute(
            path: '/admin/cupones',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CuponesListScreen()),
          ),
          GoRoute(
            path: '/admin/documentos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DocumentacionScreen()),
          ),
        ],
      ),
      // Las vistas de detalle SÍ quedan fuera del shell, a propósito: son
      // pantallas de "profundizar" (drill-down) a pantalla completa, sin
      // sidebar — igual que antes, no es parte del bug reportado.
      GoRoute(
        path: '/admin/proyectos/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProyectoDetailScreen(proyectoId: id);
        },
      ),
      GoRoute(
        path: '/admin/espacios/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EspacioDetailScreen(espacioId: id);
        },
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
    ],
  );
});
