import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_palette.dart';
import '../../../../app/estado_colors.dart';
import '../../../../providers/providers.dart';
import '../../../../widgets/pill.dart';
import '../../financiamiento/fondo_form_dialog.dart';

/// Tab "Financiamiento": postulaciones a fondos concursables asociadas a
/// este proyecto específico.
class ProyectoFinanciamientoTab extends ConsumerWidget {
  const ProyectoFinanciamientoTab({super.key, required this.proyectoId});

  final String proyectoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fondosAsync = ref.watch(postulacionesFondosPorProyectoProvider(proyectoId));
    final formatoMoneda = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => FondoFormDialog(proyectoIdFijo: proyectoId),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva postulación'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: fondosAsync.when(
              data: (fondos) {
                if (fondos.isEmpty) {
                  return Center(
                    child: Text('Este proyecto no tiene postulaciones a fondos registradas.', style: TextStyle(color: context.colors.textSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: fondos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final fondo = fondos[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/admin/financiamiento/${fondo.id}'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fondo.nombreFondo, style: Theme.of(context).textTheme.titleSmall),
                                  if (fondo.institucion != null)
                                    Text(fondo.institucion!, style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(formatoMoneda.format(fondo.montoSolicitado), style: TextStyle(color: context.colors.textPrimary)),
                            const SizedBox(width: 12),
                            Pill(label: fondo.estado.label, color: EstadoColors.fondo(fondo.estado)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error al cargar financiamiento: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
