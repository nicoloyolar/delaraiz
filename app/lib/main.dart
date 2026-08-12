import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: DeLaRaizApp()));
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

    return MaterialApp.router(
      title: 'Corporación de La Raíz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
