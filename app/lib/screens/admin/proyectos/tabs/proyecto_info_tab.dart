import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_colors.dart';
import '../../../../models/proyecto_model.dart';
import '../../../../providers/providers.dart';

/// Tab "Info": datos generales del proyecto, espacios asociados y el
/// control de si acepta postulaciones públicas de bandas.
class ProyectoInfoTab extends ConsumerWidget {
  const ProyectoInfoTab({super.key, required this.proyecto});

  final ProyectoModel proyecto;

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Seguro que deseas eliminar "${proyecto.nombre}"? Se perderá el acceso a sus '
          'actividades, bitácora, componentes y equipo asociados. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rechazada),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await ref.read(proyectoServiceProvider).eliminarProyecto(proyecto.id!);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  Future<void> _cambiarPostulacionesAbiertas(BuildContext context, WidgetRef ref, bool valor) async {
    try {
      final service = ref.read(proyectoServiceProvider);
      if (valor) {
        await service.establecerProyectoConPostulacionesAbiertas(proyecto.id!);
      } else {
        await service.cerrarPostulacionesBandas(proyecto.id!);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personasAsync = ref.watch(personasStreamProvider);
    final espaciosAsync = ref.watch(espaciosStreamProvider);

    final responsableNombre = personasAsync.maybeWhen(
      data: (personas) => personas.where((p) => p.id == proyecto.responsableId).firstOrNull?.nombre,
      orElse: () => null,
    );

    final espaciosDelProyecto = espaciosAsync.maybeWhen(
      data: (espacios) => espacios.where((e) => proyecto.espacioIds.contains(e.id)).toList(),
      orElse: () => const [],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tarjeta(
                context,
                icono: Icons.info_outline_rounded,
                titulo: 'Datos generales',
                child: Column(
                  children: [
                    _fila('Tipo', proyecto.tipo),
                    _fila('Descripción', proyecto.descripcion ?? '—'),
                    _fila('Responsable', responsableNombre ?? 'Sin asignar'),
                    _fila(
                      'Fecha de inicio',
                      proyecto.fechaInicio != null ? DateFormat('dd/MM/yyyy').format(proyecto.fechaInicio!) : '—',
                    ),
                    _fila(
                      'Fecha de término',
                      proyecto.fechaTermino != null ? DateFormat('dd/MM/yyyy').format(proyecto.fechaTermino!) : '—',
                    ),
                    _fila(
                      'Presupuesto estimado',
                      proyecto.presupuestoEstimado != null
                          ? NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0)
                              .format(proyecto.presupuestoEstimado)
                          : '—',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _tarjeta(
                context,
                icono: Icons.location_city_outlined,
                titulo: 'Espacios asociados',
                child: espaciosDelProyecto.isEmpty
                    ? const Text('Este proyecto no tiene espacios asociados todavía.',
                        style: TextStyle(color: AppColors.textSecondary))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final espacio in espaciosDelProyecto)
                            Chip(label: Text(espacio.nombre)),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _tarjeta(
                context,
                icono: Icons.campaign_outlined,
                titulo: 'Postulaciones públicas de bandas',
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        proyecto.aceptaPostulacionesBandas
                            ? 'El formulario público ("/") está recibiendo postulaciones para este proyecto.'
                            : 'El formulario público no está aceptando postulaciones para este proyecto.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Switch(
                      value: proyecto.aceptaPostulacionesBandas,
                      onChanged: (valor) => _cambiarPostulacionesAbiertas(context, ref, valor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _confirmarEliminar(context, ref),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rechazada),
                label: const Text('Eliminar proyecto', style: TextStyle(color: AppColors.rechazada)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(BuildContext context, {required IconData icono, required String titulo, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(etiqueta, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Expanded(child: Text(valor, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
