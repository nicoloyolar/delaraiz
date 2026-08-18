import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_colors.dart';
import '../../models/documento_model.dart';
import '../../providers/providers.dart';
import '../../widgets/documento_card.dart';
import '../../widgets/subir_documento_dialog.dart';

/// Pantalla de gestión de documentación institucional de la Corporación
/// de La Raíz (estatutos, actas, contratos, informes) — independiente
/// de las postulaciones de bandas. Ruta protegida `/admin/documentos`.
///
/// El `AdminShell` (sidebar) lo provee el `ShellRoute` en `app_router.dart`.
class DocumentacionScreen extends ConsumerWidget {
  const DocumentacionScreen({super.key});

  Future<void> _abrirArchivo(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el archivo: $url')),
        );
      }
    }
  }

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref, DocumentoModel documento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Seguro que deseas eliminar "${documento.titulo}"? Esta acción no se puede deshacer.'),
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
      await ref.read(documentoServiceProvider).eliminarDocumento(documento);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento eliminado.')),
        );
      }
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
    final documentosAsync = ref.watch(documentosStreamProvider);
    final categoriaActual = ref.watch(categoriaDocumentoFiltroProvider);

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
                    Text('Documentación', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Estatutos, actas, contratos e informes de la Corporación',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const SubirDocumentoDialog(),
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Subir documento'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por título...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) =>
                ref.read(textoBusquedaDocumentosProvider.notifier).state = value,
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: [
              _filtroChip(context, ref, label: 'Todas', categoria: null, actual: categoriaActual),
              for (final categoria in CategoriaDocumento.values)
                _filtroChip(context, ref, label: categoria.label, categoria: categoria, actual: categoriaActual),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: documentosAsync.when(
              data: (documentos) {
                if (documentos.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay documentos en esta categoría.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columnas = (constraints.maxWidth / 300).floor().clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: documentos.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        mainAxisExtent: 240,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final documento = documentos[index];
                        return DocumentoCard(
                          documento: documento,
                          onDescargar: () => _abrirArchivo(context, documento.archivoUrl),
                          onEliminar: () => _confirmarEliminar(context, ref, documento),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error al cargar la documentación: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtroChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required CategoriaDocumento? categoria,
    required CategoriaDocumento? actual,
  }) {
    final seleccionado = actual == categoria;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) => ref.read(categoriaDocumentoFiltroProvider.notifier).state = categoria,
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
