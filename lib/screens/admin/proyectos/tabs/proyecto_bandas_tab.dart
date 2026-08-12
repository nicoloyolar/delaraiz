import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_colors.dart';
import '../../../../models/banda_model.dart';
import '../../../../providers/providers.dart';
import '../../../../widgets/banda_card.dart';
import '../../../../widgets/stat_card.dart';

/// Tab "Bandas": postulaciones de bandas recibidas específicamente para
/// este proyecto (solo tiene sentido en proyectos de tipo festival/evento
/// musical, pero no se restringe por tipo — cualquier proyecto puede
/// recibir postulaciones si el admin abre el formulario público para él).
class ProyectoBandasTab extends ConsumerWidget {
  const ProyectoBandasTab({super.key, required this.proyectoId});

  final String proyectoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postulacionesAsync = ref.watch(postulacionesPorProyectoProvider(proyectoId));
    final filtroEstado = ref.watch(filtroEstadoProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          postulacionesAsync.when(
            data: (bandas) => _FilaEstadisticas(bandas: bandas),
            loading: () => const SizedBox(height: 84),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre de grupo, comuna o género...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => ref.read(textoBusquedaProvider.notifier).state = value,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _filtroChip(ref, label: 'Todas', estado: null, actual: filtroEstado),
              for (final estado in EstadoPostulacion.values)
                _filtroChip(ref, label: estado.label, estado: estado, actual: filtroEstado),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: postulacionesAsync.when(
              data: (bandas) {
                if (bandas.isEmpty) {
                  return const Center(
                    child: Text('No hay postulaciones que coincidan con el filtro.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columnas = (constraints.maxWidth / 300).floor().clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: bandas.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        mainAxisExtent: 250,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final banda = bandas[index];
                        return BandaCard(
                          banda: banda,
                          onTap: () => context.push('/admin/banda/${banda.id}'),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar las postulaciones: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtroChip(
    WidgetRef ref, {
    required String label,
    required EstadoPostulacion? estado,
    required EstadoPostulacion? actual,
  }) {
    final seleccionado = actual == estado;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) => ref.read(filtroEstadoProvider.notifier).state = estado,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accentSoft,
      side: BorderSide(color: seleccionado ? AppColors.accent : AppColors.border),
      labelStyle: TextStyle(
        color: seleccionado ? AppColors.accent : AppColors.textSecondary,
        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _FilaEstadisticas extends StatelessWidget {
  const _FilaEstadisticas({required this.bandas});

  final List<BandaModel> bandas;

  @override
  Widget build(BuildContext context) {
    final pendientes = bandas.where((b) => b.estado == EstadoPostulacion.pendiente).length;
    final seleccionadas = bandas.where((b) => b.estado == EstadoPostulacion.seleccionada).length;
    final rechazadas = bandas.where((b) => b.estado == EstadoPostulacion.rechazada).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 700 ? 4 : 2;
        final ancho = (constraints.maxWidth - (columnas - 1) * 14) / columnas;

        final tarjetas = [
          SizedBox(width: ancho, child: StatCard(label: 'Total postulaciones', value: bandas.length, icon: Icons.groups_rounded, color: AppColors.accent)),
          SizedBox(width: ancho, child: StatCard(label: 'Pendientes', value: pendientes, icon: Icons.hourglass_top_rounded, color: AppColors.pendiente)),
          SizedBox(width: ancho, child: StatCard(label: 'Seleccionadas', value: seleccionadas, icon: Icons.check_circle_outline_rounded, color: AppColors.seleccionada)),
          SizedBox(width: ancho, child: StatCard(label: 'Rechazadas', value: rechazadas, icon: Icons.cancel_outlined, color: AppColors.rechazada)),
        ];

        return Wrap(spacing: 14, runSpacing: 14, children: tarjetas);
      },
    );
  }
}
