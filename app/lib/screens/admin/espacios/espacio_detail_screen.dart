import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_colors.dart';
import '../../../models/espacio_model.dart';
import '../../../providers/providers.dart';
import 'espacio_form_dialog.dart';

/// Vista de detalle de un Espacio: datos generales, fotos, documentación
/// legal y el historial de proyectos que lo han usado (derivado de
/// consultar qué proyectos incluyen este espacio en su `espacioIds`).
/// Ruta protegida `/admin/espacios/:id`.
class EspacioDetailScreen extends ConsumerWidget {
  const EspacioDetailScreen({super.key, required this.espacioId});

  final String espacioId;

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref, EspacioModel espacio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar espacio'),
        content: Text('¿Seguro que deseas eliminar "${espacio.nombre}"? Esta acción no se puede deshacer.'),
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
      await ref.read(espacioServiceProvider).eliminarEspacio(espacio.id!);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espacioAsync = ref.watch(espacioDetalleProvider(espacioId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalle del espacio')),
      body: espacioAsync.when(
        data: (espacio) {
          if (espacio == null) return const Center(child: Text('Este espacio no existe.'));
          return _DetalleContenido(espacio: espacio, onEliminar: () => _confirmarEliminar(context, ref, espacio));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar: $error')),
      ),
    );
  }
}

class _DetalleContenido extends ConsumerWidget {
  const _DetalleContenido({required this.espacio, required this.onEliminar});

  final EspacioModel espacio;
  final VoidCallback onEliminar;

  Future<void> _abrir(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final proyectosAsync = ref.watch(proyectosDelEspacioProvider(espacio.id!));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(espacio.nombre, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text('${espacio.direccion}, ${espacio.comuna}', style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => showDialog<void>(context: context, builder: (_) => EspacioFormDialog(espacio: espacio)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _tarjeta(
                context,
                icono: Icons.info_outline_rounded,
                titulo: 'Datos generales',
                child: Column(
                  children: [
                    _fila('Tenencia', espacio.tipoTenencia.label),
                    _fila('Estado legal', espacio.estadoLegal ?? '—'),
                    _fila('Capacidad', espacio.capacidad?.toString() ?? '—'),
                    _fila('Descripción', espacio.descripcion ?? '—'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (espacio.fotoUrls.isNotEmpty) ...[
                _tarjeta(
                  context,
                  icono: Icons.photo_library_outlined,
                  titulo: 'Fotos',
                  child: SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: espacio.fotoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(espacio.fotoUrls[i], width: 110, height: 110, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (espacio.documentoUrls.isNotEmpty) ...[
                _tarjeta(
                  context,
                  icono: Icons.description_outlined,
                  titulo: 'Documentación legal',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < espacio.documentoUrls.length; i++)
                        OutlinedButton.icon(
                          onPressed: () => _abrir(context, espacio.documentoUrls[i]),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                          label: Text('Documento ${i + 1}'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _tarjeta(
                context,
                icono: Icons.history_rounded,
                titulo: 'Historial de uso (proyectos)',
                child: proyectosAsync.when(
                  data: (proyectos) {
                    if (proyectos.isEmpty) {
                      return const Text('Este espacio no ha sido asociado a ningún proyecto todavía.',
                          style: TextStyle(color: AppColors.textSecondary));
                    }
                    return Column(
                      children: [
                        for (final proyecto in proyectos)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.auto_awesome_mosaic_outlined, color: AppColors.accent),
                            title: Text(proyecto.nombre),
                            subtitle: Text(proyecto.estado.label),
                            trailing: const Icon(Icons.arrow_forward_rounded, size: 16),
                            onTap: () => context.push('/admin/proyectos/${proyecto.id}'),
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Error: $e'),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rechazada),
                label: const Text('Eliminar espacio', style: TextStyle(color: AppColors.rechazada)),
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
          SizedBox(width: 140, child: Text(etiqueta, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Expanded(child: Text(valor, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
