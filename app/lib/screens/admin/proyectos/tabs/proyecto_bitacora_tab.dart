import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_colors.dart';
import '../../../../providers/providers.dart';

/// Tab "Bitácora": registro cronológico de avances del proyecto, con
/// texto y fotos opcionales — el "diario de a bordo" de cada iniciativa.
class ProyectoBitacoraTab extends ConsumerWidget {
  const ProyectoBitacoraTab({super.key, required this.proyectoId});

  final String proyectoId;

  Future<void> _eliminar(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(proyectoServiceProvider).eliminarEntradaBitacora(proyectoId, id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bitacoraAsync = ref.watch(bitacoraStreamProvider(proyectoId));

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
                builder: (_) => _NuevaEntradaDialog(proyectoId: proyectoId),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva entrada'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bitacoraAsync.when(
              data: (entradas) {
                if (entradas.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay entradas de bitácora.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: entradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entrada = entradas[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entrada.fecha != null ? DateFormat('dd/MM/yyyy HH:mm').format(entrada.fecha!) : '—',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ),
                              if (entrada.autorNombre != null)
                                Text(entrada.autorNombre!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                color: AppColors.rechazada,
                                onPressed: () => _eliminar(context, ref, entrada.id!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(entrada.texto, style: const TextStyle(color: AppColors.textPrimary)),
                          if (entrada.fotoUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 84,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: entrada.fotoUrls.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, i) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(entrada.fotoUrls[i], width: 84, height: 84, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error al cargar la bitácora: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NuevaEntradaDialog extends ConsumerStatefulWidget {
  const _NuevaEntradaDialog({required this.proyectoId});

  final String proyectoId;

  @override
  ConsumerState<_NuevaEntradaDialog> createState() => _NuevaEntradaDialogState();
}

class _NuevaEntradaDialogState extends ConsumerState<_NuevaEntradaDialog> {
  final _textoCtrl = TextEditingController();
  final _autorCtrl = TextEditingController();
  List<PlatformFile> _fotos = [];
  bool _guardando = false;

  @override
  void dispose() {
    _textoCtrl.dispose();
    _autorCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFotos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    setState(() => _fotos = result.files);
  }

  Future<void> _guardar() async {
    if (_textoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe el avance antes de guardar.')));
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(proyectoServiceProvider).crearEntradaBitacora(
            proyectoId: widget.proyectoId,
            texto: _textoCtrl.text.trim(),
            autorNombre: _autorCtrl.text.trim().isEmpty ? null : _autorCtrl.text.trim(),
            fotosBytes: _fotos.map((f) => f.bytes!).toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva entrada de bitácora', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: _textoCtrl,
                decoration: const InputDecoration(labelText: 'Avance / novedad'),
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _autorCtrl,
                decoration: const InputDecoration(labelText: 'Autor (opcional)'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fotos.isEmpty ? 'Sin fotos seleccionadas' : '${_fotos.length} foto(s) seleccionada(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    OutlinedButton(onPressed: _elegirFotos, child: const Text('Elegir fotos')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
