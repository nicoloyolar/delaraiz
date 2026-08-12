import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../models/espacio_model.dart';
import '../../../providers/providers.dart';
import '../../../utils/validators.dart';

/// Diálogo de creación/edición de un Espacio recuperado. Al crear, permite
/// adjuntar fotos y documentación legal de una vez; al editar, solo se
/// modifican los datos generales (las fotos/documentos ya subidos se
/// mantienen).
class EspacioFormDialog extends ConsumerStatefulWidget {
  const EspacioFormDialog({super.key, this.espacio});

  final EspacioModel? espacio;

  @override
  ConsumerState<EspacioFormDialog> createState() => _EspacioFormDialogState();
}

class _EspacioFormDialogState extends ConsumerState<EspacioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _comunaCtrl;
  late final TextEditingController _estadoLegalCtrl;
  late final TextEditingController _capacidadCtrl;
  late final TextEditingController _descripcionCtrl;
  late TipoTenencia _tipoTenencia;
  List<PlatformFile> _fotos = [];
  List<PlatformFile> _documentos = [];
  bool _guardando = false;

  bool get _esEdicion => widget.espacio != null;

  @override
  void initState() {
    super.initState();
    final e = widget.espacio;
    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: e?.direccion ?? '');
    _comunaCtrl = TextEditingController(text: e?.comuna ?? '');
    _estadoLegalCtrl = TextEditingController(text: e?.estadoLegal ?? '');
    _capacidadCtrl = TextEditingController(text: e?.capacidad?.toString() ?? '');
    _descripcionCtrl = TextEditingController(text: e?.descripcion ?? '');
    _tipoTenencia = e?.tipoTenencia ?? TipoTenencia.enGestion;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _comunaCtrl.dispose();
    _estadoLegalCtrl.dispose();
    _capacidadCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFotos() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result != null) setState(() => _fotos = result.files);
  }

  Future<void> _elegirDocumentos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null) setState(() => _documentos = result.files);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final service = ref.read(espacioServiceProvider);
      if (_esEdicion) {
        final actualizado = EspacioModel(
          id: widget.espacio!.id,
          nombre: _nombreCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          comuna: _comunaCtrl.text.trim(),
          tipoTenencia: _tipoTenencia,
          estadoLegal: _estadoLegalCtrl.text.trim().isEmpty ? null : _estadoLegalCtrl.text.trim(),
          capacidad: int.tryParse(_capacidadCtrl.text.trim()),
          descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
          fotoUrls: widget.espacio!.fotoUrls,
          documentoUrls: widget.espacio!.documentoUrls,
        );
        await service.actualizarEspacio(actualizado);
      } else {
        await service.crearEspacio(
          EspacioModel(
            nombre: _nombreCtrl.text.trim(),
            direccion: _direccionCtrl.text.trim(),
            comuna: _comunaCtrl.text.trim(),
            tipoTenencia: _tipoTenencia,
            estadoLegal: _estadoLegalCtrl.text.trim().isEmpty ? null : _estadoLegalCtrl.text.trim(),
            capacidad: int.tryParse(_capacidadCtrl.text.trim()),
            descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
          ),
          fotos: [for (final f in _fotos) (bytes: f.bytes!, nombre: f.name)],
          documentos: [for (final d in _documentos) (bytes: d.bytes!, nombre: d.name)],
        );
      }
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_esEdicion ? 'Editar espacio' : 'Nuevo espacio', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre del espacio'),
                          validator: (v) => Validators.requerido(v, campo: 'El nombre'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _direccionCtrl,
                          decoration: const InputDecoration(labelText: 'Dirección'),
                          validator: (v) => Validators.requerido(v, campo: 'La dirección'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _comunaCtrl,
                                decoration: const InputDecoration(labelText: 'Comuna'),
                                validator: (v) => Validators.requerido(v, campo: 'La comuna'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: _capacidadCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Capacidad'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<TipoTenencia>(
                          initialValue: _tipoTenencia,
                          decoration: const InputDecoration(labelText: 'Tipo de tenencia'),
                          items: TipoTenencia.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _tipoTenencia = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _estadoLegalCtrl,
                          decoration: const InputDecoration(labelText: 'Estado legal (opcional)'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descripcionCtrl,
                          decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                          maxLines: 3,
                        ),
                        if (!_esEdicion) ...[
                          const SizedBox(height: 14),
                          _selectorArchivos(
                            icono: Icons.photo_library_outlined,
                            texto: _fotos.isEmpty ? 'Sin fotos seleccionadas' : '${_fotos.length} foto(s) seleccionada(s)',
                            onPressed: _elegirFotos,
                            etiquetaBoton: 'Elegir fotos',
                          ),
                          const SizedBox(height: 10),
                          _selectorArchivos(
                            icono: Icons.description_outlined,
                            texto: _documentos.isEmpty
                                ? 'Sin documentos legales seleccionados'
                                : '${_documentos.length} documento(s) seleccionado(s)',
                            onPressed: _elegirDocumentos,
                            etiquetaBoton: 'Elegir PDFs',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _selectorArchivos({
    required IconData icono,
    required String texto,
    required VoidCallback onPressed,
    required String etiquetaBoton,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icono, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
          OutlinedButton(onPressed: onPressed, child: Text(etiquetaBoton)),
        ],
      ),
    );
  }
}
