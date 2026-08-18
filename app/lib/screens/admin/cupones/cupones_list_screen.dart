import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../models/cupon_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/pill.dart';
import 'cupon_form_dialog.dart';

/// Mantenedor de Cupones de descuento — agregado 2026-08-18, para que la
/// directiva pueda aportar con un % de descuento en /membresia/ (hasta
/// 100%, o sea $0 de cobro real) sin dejar de pasar por el flujo real de
/// Flow. El `AdminShell` (sidebar) lo provee el `ShellRoute` en
/// `app_router.dart`. Ruta protegida `/admin/cupones`.
class CuponesListScreen extends ConsumerWidget {
  const CuponesListScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, CuponModel cupon) async {
    try {
      await ref.read(cuponesServiceProvider).cambiarEstado(cupon.id, !cupon.activo);
      ref.invalidate(cuponesListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')),
        );
      }
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, CuponModel cupon) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar cupón "${cupon.codigo}"'),
        content: const Text(
          '¿Seguro que quieres eliminarlo? Deja de existir para el panel — si alguien '
          'todavía tiene el código, ya no le va a funcionar en /membresia/.',
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
      await ref.read(cuponesServiceProvider).eliminar(cupon.id);
      ref.invalidate(cuponesListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuponesAsync = ref.watch(cuponesListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cupones', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Cupones de descuento para /membresia/ — un 100% deja el aporte en \$0, '
                      'útil para que la directiva pueda ser socia sin costo.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.invalidate(cuponesListProvider),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refrescar (los usos no se actualizan solos en esta pantalla)',
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => showDialog<void>(context: context, builder: (_) => const CuponFormDialog()),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo cupón'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: cuponesAsync.when(
              data: (cupones) {
                if (cupones.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay cupones creados.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: cupones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cupon = cupones[index];
                    return _FilaCupon(
                      cupon: cupon,
                      onToggle: () => _toggle(context, ref, cupon),
                      onEliminar: () => _eliminar(context, ref, cupon),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar los cupones: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCupon extends StatelessWidget {
  const _FilaCupon({required this.cupon, required this.onToggle, required this.onEliminar});

  final CuponModel cupon;
  final VoidCallback onToggle;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estaVencido = cupon.expirado;
    // "Activo de verdad" combina el interruptor manual con la fecha de
    // expiración — un cupón puede seguir con `activo=true` en la base pero
    // ya haber vencido; el Pill de estado tiene que reflejar la realidad,
    // no solo el interruptor.
    final activoDeVerdad = cupon.activo && !estaVencido;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.sell_outlined, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cupon.codigo,
                        style: theme.textTheme.titleSmall?.copyWith(letterSpacing: .5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pill(
                      label: estaVencido ? 'Vencido' : (activoDeVerdad ? 'Activo' : 'Desactivado'),
                      color: activoDeVerdad ? AppColors.seleccionada : AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${cupon.descuentoPct.toStringAsFixed(cupon.descuentoPct % 1 == 0 ? 0 : 1)}% de descuento',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      cupon.esIlimitado
                          ? 'Usos: ${cupon.usosActuales} (sin límite)'
                          : 'Usos: ${cupon.usosActuales}/${cupon.usosMaximos}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    if (cupon.expira.isNotEmpty)
                      Text(
                        'Expira: ${cupon.expira}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(cupon.activo ? Icons.toggle_on_rounded : Icons.toggle_off_outlined,
                color: cupon.activo ? AppColors.accent : AppColors.textMuted, size: 28),
            tooltip: cupon.activo ? 'Desactivar' : 'Activar',
            onPressed: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.rechazada,
            tooltip: 'Eliminar',
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}
