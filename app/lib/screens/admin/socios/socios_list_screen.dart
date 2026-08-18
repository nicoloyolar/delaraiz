import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_colors.dart';
import '../../../app/estado_colors.dart';
import '../../../models/credencial_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/pill.dart';

/// Mantenedor de Socios del panel admin — agregado 2026-08-14. Muestra a
/// todas las personas que han hecho aportes reales vía Flow (`/membresia/`
/// en el sitio PHP), sincronizados a la colección `credenciales` de
/// Firestore, con acciones de moderación manual (aprobar/rechazar/bloquear)
/// para casos que el cobro automático no cubre.
///
/// El `AdminShell` (sidebar) lo provee el `ShellRoute` en `app_router.dart`.
/// Ruta protegida `/admin/socios`.
class SociosListScreen extends ConsumerWidget {
  const SociosListScreen({super.key});

  Future<void> _cambiarEstado(
    BuildContext context,
    WidgetRef ref,
    CredencialModel socio,
    EstadoModeracion nuevoEstado, {
    bool requiereConfirmacion = false,
  }) async {
    if (requiereConfirmacion) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${nuevoEstado.label} a "${socio.nombre}"'),
          content: Text(
            '¿Seguro que quieres marcar a "${socio.nombre}" como '
            '"${nuevoEstado.label}"? Esto no cancela su cobro real en '
            'Flow — solo afecta si ve sus beneficios en la app.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.rechazada),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(nuevoEstado.label),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    try {
      await ref.read(sociosAdminServiceProvider).actualizarEstadoModeracion(socio.email, nuevoEstado);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${socio.nombre}" ahora está "${nuevoEstado.label}".')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar (¿Firebase ya está conectado?): $e')),
        );
      }
    }
  }

  String _iniciales(String nombre) {
    final palabras = nombre.trim().split(RegExp(r'\s+'));
    final letras = palabras.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
    return letras.isEmpty ? '?' : letras.toUpperCase();
  }

  String _formatoPesos(int monto) {
    final texto = monto.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) buffer.write('.');
      buffer.write(texto[i]);
    }
    return '\$$buffer';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sociosAsync = ref.watch(sociosStreamProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Socios', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Personas que aportan a la Corporación vía Flow (/membresia/). '
            'El estado de pago llega automático — la moderación manual es '
            'para casos excepcionales.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: sociosAsync.when(
              data: (socios) {
                if (socios.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay socios registrados.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: socios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final socio = socios[index];
                    return _FilaSocio(
                      socio: socio,
                      iniciales: _iniciales(socio.nombre),
                      montoFormateado: _formatoPesos(socio.montoMensual),
                      onCambiarEstado: (nuevoEstado, {requiereConfirmacion = false}) =>
                          _cambiarEstado(context, ref, socio, nuevoEstado,
                              requiereConfirmacion: requiereConfirmacion),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar los socios: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaSocio extends StatelessWidget {
  const _FilaSocio({
    required this.socio,
    required this.iniciales,
    required this.montoFormateado,
    required this.onCambiarEstado,
  });

  final CredencialModel socio;
  final String iniciales;
  final String montoFormateado;
  final void Function(EstadoModeracion nuevoEstado, {bool requiereConfirmacion}) onCambiarEstado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: Text(
              iniciales,
              style: theme.textTheme.titleSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800),
            ),
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
                        socio.nombre,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (socio.estadoModeracion != EstadoModeracion.sinRevisar) ...[
                      const SizedBox(width: 8),
                      Pill(
                        label: socio.estadoModeracion.label,
                        color: EstadoColors.moderacion(socio.estadoModeracion),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  socio.email,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Pill(label: socio.estado.label, color: EstadoColors.credencial(socio.estado)),
                    Text(
                      '${socio.plan.label} · $montoFormateado/mes',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (socio.proximoCobro != null)
                      Text(
                        'Próximo cobro: ${DateFormat('dd/MM/yyyy').format(socio.proximoCobro!)}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<EstadoModeracion>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            tooltip: 'Moderar socio',
            onSelected: (nuevoEstado) => onCambiarEstado(
              nuevoEstado,
              requiereConfirmacion: nuevoEstado == EstadoModeracion.rechazado ||
                  nuevoEstado == EstadoModeracion.bloqueado,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: EstadoModeracion.aprobado,
                child: ListTile(leading: Icon(Icons.check_circle_outline_rounded), title: Text('Aprobar')),
              ),
              const PopupMenuItem(
                value: EstadoModeracion.rechazado,
                child: ListTile(leading: Icon(Icons.cancel_outlined), title: Text('Rechazar')),
              ),
              const PopupMenuItem(
                value: EstadoModeracion.bloqueado,
                child: ListTile(leading: Icon(Icons.block_rounded), title: Text('Bloquear')),
              ),
              const PopupMenuItem(
                value: EstadoModeracion.sinRevisar,
                child: ListTile(leading: Icon(Icons.restart_alt_rounded), title: Text('Quitar revisión manual')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
