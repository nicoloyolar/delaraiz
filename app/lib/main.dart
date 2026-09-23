import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_colors.dart';
import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Necesario para poder formatear fechas con nombres de día/mes en
  // español (ej. "miércoles 18 de septiembre") — sin esto, cualquier
  // `DateFormat` que use símbolos (no solo números) lanza
  // `LocaleDataException` en tiempo de ejecución. Agregado 2026-08-18 junto
  // con la Agenda, primera pantalla de la app que necesita fechas así de
  // legibles (el resto del código usa "dd/MM/yyyy", que no lo necesita).
  await initializeDateFormatting('es');

  // Antes esto no tenía try/catch: si Firebase fallaba al iniciar (proyecto
  // mal configurado, `firebase_options.dart` todavía en placeholder, sin
  // red), la app crasheaba entera con una excepción sin manejar (pantalla
  // en blanco o roja) en vez de avisar qué pasó — hallazgo del análisis del
  // sistema completo, 2026-08-12.
  Object? errorDeInicio;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (error) {
    errorDeInicio = error;
  }

  // Modo claro/oscuro ya guardado (si alguien lo eligió antes) — se carga
  // ANTES de runApp() para que la primera pantalla ya salga en el modo
  // correcto, sin parpadear en el modo por defecto y recién después
  // cambiar (ver ThemeService/themeModeProvider).
  final themeService = ThemeService();
  final themeModeInicial = await themeService.cargar();

  runApp(
    errorDeInicio == null
        ? ProviderScope(
            overrides: [
              themeModeProvider.overrideWith(
                (ref) => ThemeModeController(ref.watch(themeServiceProvider), themeModeInicial),
              ),
            ],
            child: const DeLaRaizApp(),
          )
        : ErrorDeInicioApp(error: errorDeInicio),
  );
}

/// Pantalla de respaldo si Firebase no pudo inicializar — evita que la app
/// quede en blanco sin explicación alguna.
class ErrorDeInicioApp extends StatelessWidget {
  const ErrorDeInicioApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: AppColors.rechazada, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo conectar con el servidor',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu conexión a internet e intenta de nuevo. Si el problema persiste, avisa a la Corporación.\n\n$error',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// App raíz de la plataforma de la Corporación de La Raíz.
///
/// Usa `MaterialApp.router` (go_router) porque el proyecto expone dos
/// experiencias con URLs propias en Web: el formulario público (`/`) y
/// el dashboard administrativo (`/admin`), cada una navegable/compartible
/// como enlace directo.
class DeLaRaizApp extends ConsumerWidget {
  const DeLaRaizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Corporación de La Raíz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
