import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_colors.dart';
import '../models/documento_model.dart';
import '../providers/providers.dart';
import '../utils/validators.dart';

/// Diálogo para subir un nuevo documento institucional (estatutos, actas,
/// contratos, informes) desde el panel de "Documentación".
class SubirDocumentoDialog extends ConsumerStatefulWidget {
  const SubirDocumentoDialog({super.key});

  @override
  ConsumerState<SubirDocumentoDialog> createState() => _SubirDocumentoDialogState();
}

class _SubirDocumentoDialogState extends ConsumerState<SubirDocumentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  CategoriaDocumento _categoria = CategoriaDocumento.otros;
  PlatformFile? _archivo;
  bool _subiendo = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _archivo = result.files.single);
  }

  Future<void> _subir() async {
    if (!_formKey.currentState!.validate()) return;
    if (_archivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes adjuntar un archivo PDF.')),
      );
      return;
    }

    setState(() => _subiendo = true);
    try {
      await ref.read(documentoServiceProvider).subirDocumento(
            titulo: _tituloCtrl.text.trim(),
            categoria: _categoria,
            descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
            archivoBytes: _archivo!.bytes!,
            nombreArchivoOriginal: _archivo!.name,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento subido correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir el documento: $e')),
      );
    } finally {
      if (mounted) setState(() => _subiendo = false);
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subir documento', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Documentación institucional de la Corporación de La Raíz',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => Validators.requerido(v, campo: 'El título'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<CategoriaDocumento>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: CategoriaDocumento.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _categoria = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _archivo?.name ?? 'Ningún archivo seleccionado',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _seleccionarArchivo,
                        child: Text(_archivo == null ? 'Elegir PDF' : 'Cambiar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _subiendo ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _subiendo ? null : _subir,
                      child: _subiendo
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Subir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
