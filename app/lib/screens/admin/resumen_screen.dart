import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_colors.dart';
import '../../app/estado_colors.dart';
import '../../models/postulacion_fondo_model.dart';
import '../../models/proyecto_model.dart';
import '../../providers/providers.dart';
import '../../widgets/pill.dart';
import '../../widgets/stat_card.dart';

/// Pantalla de aterrizaje del panel admin: KPIs cruzados de todos los
/// módulos (proyectos, bandas, espacios, equipo, financiamiento) para
/// tener una vista rápida del estado general de la Corporación sin entrar
/// a cada sección. Ruta protegida `/admin`.
///
/// El `AdminShell` (sidebar) ya no se arma acá — lo provee el `ShellRoute`
/// en `app_router.dart`, como widget persistente compartido por las 6
/// secciones de lista del panel (evita que el sidebar se reconstruya al
/// navegar entre secciones).
class ResumenScreen extends ConsumerWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectosAsync = ref.watch(proyectosStreamProvider);
    final bandasAsync = ref.watch(todasLasBandasProvider);
    final espaciosAsync = ref.watch(espaciosStreamProvider);
    final personasAsync = ref.watch(personasStreamProvider);
    final fondosAsync = ref.watch(postulacionesFondosStreamProvider);

    final proyectosActivos = proyectosAsync.maybeWhen(
      data: (proyectos) => proyectos.where((p) => p.estado == EstadoProyecto.enCurso).length,
      orElse: () => 0,
    );
    final totalProyectos = proyectosAsync.maybeWhen(data: (p) => p.length, orElse: () => 0);
    final totalBandas = bandasAsync.maybeWhen(data: (b) => b.length, orElse: () => 0);
    final totalEspacios = espaciosAsync.maybeWhen(data: (e) => e.length, orElse: () => 0);
    final totalPersonas = personasAsync.maybeWhen(data: (p) => p.length, orElse: () => 0);
    final fondosEnCurso = fondosAsync.maybeWhen(
      data: (fondos) => fondos.where((f) => f.estado != EstadoFondo.rechazado).length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Vista general de la Corporación de La Raíz',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columnas = constraints.maxWidth >= 900 ? 5 : (constraints.maxWidth >= 500 ? 3 : 2);
                final ancho = (constraints.maxWidth - (columnas - 1) * 14) / columnas;
                final tarjetas = [
                  SizedBox(width: ancho, child: StatCard(label: 'Proyectos activos', value: proyectosActivos, icon: Icons.auto_awesome_mosaic_outlined, color: AppColors.accent)),
                  SizedBox(width: ancho, child: StatCard(label: 'Proyectos totales', value: totalProyectos, icon: Icons.dashboard_outlined, color: AppColors.seleccionada)),
                  SizedBox(width: ancho, child: StatCard(label: 'Postulaciones de bandas', value: totalBandas, icon: Icons.groups_rounded, color: AppColors.pendiente)),
                  SizedBox(width: ancho, child: StatCard(label: 'Espacios', value: totalEspacios, icon: Icons.location_city_outlined, color: AppColors.accent)),
                  SizedBox(width: ancho, child: StatCard(label: 'Equipo y voluntarios', value: totalPersonas, icon: Icons.groups_outlined, color: AppColors.seleccionada)),
                ];
                return Wrap(spacing: 14, runSpacing: 14, children: tarjetas);
              },
            ),
            const SizedBox(height: 28),
            Text('Fondos en gestión: $fondosEnCurso postulación(es) activa(s)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            Text('Proyectos recientes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            proyectosAsync.when(
              data: (proyectos) {
                if (proyectos.isEmpty) {
                  return Text('Aún no hay proyectos creados.', style: Theme.of(context).textTheme.bodyMedium);
                }
                final recientes = proyectos.take(6).toList();
                return Column(
                  children: [
                    for (final proyecto in recientes)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/admin/proyectos/${proyecto.id}'),
                          child: Row(
                            children: [
                              Expanded(child: Text(proyecto.nombre, style: Theme.of(context).textTheme.titleSmall)),
                              if (proyecto.aceptaPostulacionesBandas)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.campaign_rounded, size: 16, color: AppColors.accent),
                                ),
                              Pill(label: proyecto.estado.label, color: EstadoColors.proyecto(proyecto.estado)),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error al cargar proyectos: $e'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
