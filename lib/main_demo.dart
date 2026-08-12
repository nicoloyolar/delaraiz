import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/app_theme.dart';
import 'demo/sample_data.dart';
import 'providers/providers.dart';
import 'screens/admin/banda_detail_screen.dart';
import 'screens/admin/documentacion_screen.dart';
import 'screens/admin/proyectos/proyecto_detail_screen.dart';

/// Entry point SOLO para demo visual — NO usar en producción.
///
/// No inicializa Firebase: reemplaza los providers que normalmente leen
/// de Firestore por datos de muestra en memoria ([bandasDemo],
/// [proyectoDemo]), para poder mostrar el look & feel del panel
/// administrativo sin necesitar un proyecto de Firebase configurado
/// todavía. Los módulos sin datos de muestra propios (actividades,
/// bitácora, componentes, equipo, personas, financiamiento) se muestran
/// vacíos.
void main() {
  runApp(
    ProviderScope(
      overrides: [
        proyectosStreamProvider.overrideWith((ref) => Stream.value([proyectoDemo])),
        proyectoDetalleProvider.overrideWith((ref, id) => Stream.value(proyectoDemo)),
        postulacionesPorProyectoProvider.overrideWith((ref, proyectoId) {
          final filtro = ref.watch(filtroEstadoProvider);
          final texto = ref.watch(textoBusquedaProvider).trim().toLowerCase();

          final filtradas = bandasDemo.where((b) {
            final coincideEstado = filtro == null || b.estado == filtro;
            final coincideTexto = texto.isEmpty ||
                b.nombreGrupo.toLowerCase().contains(texto) ||
                b.comuna.toLowerCase().contains(texto) ||
                b.generoMusical.toLowerCase().contains(texto);
            return coincideEstado && coincideTexto;
          }).toList();

          return Stream.value(filtradas);
        }),
        todasLasBandasProvider.overrideWith((ref) => Stream.value(bandasDemo)),
        bandaDetalleProvider.overrideWith((ref, id) {
          final coincidencias = bandasDemo.where((b) => b.id == id);
          return coincidencias.isEmpty ? null : coincidencias.first;
        }),
        actividadesStreamProvider.overrideWith((ref, proyectoId) => Stream.value(const [])),
        bitacoraStreamProvider.overrideWith((ref, proyectoId) => Stream.value(const [])),
        componentesStreamProvider.overrideWith((ref, proyectoId) => Stream.value(const [])),
        equipoProyectoStreamProvider.overrideWith((ref, proyectoId) => Stream.value(const [])),
        personasStreamProvider.overrideWith((ref) => Stream.value(const [])),
        postulacionesFondosPorProyectoProvider.overrideWith((ref, proyectoId) => Stream.value(const [])),
        documentosStreamProvider.overrideWith((ref) {
          final categoria = ref.watch(categoriaDocumentoFiltroProvider);
          final texto = ref.watch(textoBusquedaDocumentosProvider).trim().toLowerCase();

          final filtrados = documentosDemo.where((d) {
            final coincideCategoria = categoria == null || d.categoria == categoria;
            final coincideTexto = texto.isEmpty || d.titulo.toLowerCase().contains(texto);
            return coincideCategoria && coincideTexto;
          }).toList();

          return Stream.value(filtrados);
        }),
      ],
      child: const _DemoApp(),
    ),
  );
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/admin/proyectos/${proyectoDemo.id}',
      routes: [
        GoRoute(
          path: '/admin/proyectos/:id',
          builder: (context, state) =>
              ProyectoDetailScreen(proyectoId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/admin/banda/:id',
          builder: (context, state) =>
              BandaDetailScreen(bandaId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/admin/documentos',
          builder: (context, state) => const DocumentacionScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Demo — Corporación de La Raíz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
