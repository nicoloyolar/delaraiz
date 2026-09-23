import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_palette.dart';
import '../../../models/local_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/pill.dart';
import 'local_form_dialog.dart';

/// Mantenedor de Locales adheridos al beneficio de acceso de Embajador —
/// agregado 2026-09-23 (sección 9.15/9.25 de PROYECTO.md). Arranca vacío a
/// propósito: la lista real de locales todavía no está consolidada con la
/// directiva, se carga acá a medida que se confirmen alianzas reales — sin
/// ningún local activo, el botón de generar cupón simplemente no aparece en
/// la credencial de los socios Embajador.
class LocalesListScreen extends ConsumerWidget {
  const LocalesListScreen({super.key});

  void _copiarLinkValidacion(BuildContext context, LocalModel local) {
    final url = 'https://delaraiz-app.web.app/validar/${local.id}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link de validación copiado: $url')),
    );
  }

  Future<void> _alternarActivo(WidgetRef ref, LocalModel local) {
    return ref.read(localServiceProvider).actualizar(LocalModel(
          id: local.id,
          nombre: local.nombre,
          beneficio: local.beneficio,
          activo: !local.activo,
        ));
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, LocalModel local) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar "${local.nombre}"'),
        content: const Text(
          '¿Seguro? Cualquier cupón de acceso generado para este local deja de '
          'poder validarse — no borra cupones ya usados, solo el local.',
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
    await ref.read(localServiceProvider).eliminar(local.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localesAsync = ref.watch(localesTodosProvider);

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
                    Text('Locales', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Locales adheridos al beneficio de acceso de Embajador. Cada uno '
                      'tiene su propio link de validación, para que quien reciba a los '
                      'socios en la puerta pueda escanear/escribir el código.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(context: context, builder: (_) => const LocalFormDialog()),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo local'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: localesAsync.when(
              data: (locales) {
                if (locales.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay locales cargados.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: locales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final local = locales[index];
                    return _FilaLocal(
                      local: local,
                      onEditar: () => showDialog<void>(
                        context: context,
                        builder: (_) => LocalFormDialog(local: local),
                      ),
                      onAlternarActivo: () => _alternarActivo(ref, local),
                      onCopiarLink: () => _copiarLinkValidacion(context, local),
                      onEliminar: () => _eliminar(context, ref, local),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar los locales: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaLocal extends StatelessWidget {
  const _FilaLocal({
    required this.local,
    required this.onEditar,
    required this.onAlternarActivo,
    required this.onCopiarLink,
    required this.onEliminar,
  });

  final LocalModel local;
  final VoidCallback onEditar;
  final VoidCallback onAlternarActivo;
  final VoidCallback onCopiarLink;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(local.nombre, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Pill(
                      label: local.activo ? 'Activo' : 'Inactivo',
                      color: local.activo ? AppColors.seleccionada : context.colors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(local.beneficio, style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_rounded, size: 20),
            tooltip: 'Copiar link de validación',
            onPressed: onCopiarLink,
          ),
          Switch(value: local.activo, onChanged: (_) => onAlternarActivo()),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Editar',
            onPressed: onEditar,
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
