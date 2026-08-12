import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/proyecto_model.dart';
import '../../../providers/providers.dart';
import '../../../utils/validators.dart';

/// Diálogo de creación/edición de un Proyecto. Si se pasa [proyecto], edita
/// ese proyecto existente; si no, crea uno nuevo.
class ProyectoFormDialog extends ConsumerStatefulWidget {
  const ProyectoFormDialog({super.key, this.proyecto});

  final ProyectoModel? proyecto;

  @override
  ConsumerState<ProyectoFormDialog> createState() => _ProyectoFormDialogState();
}

class _ProyectoFormDialogState extends ConsumerState<ProyectoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _presupuestoCtrl;
  late EstadoProyecto _estado;
  DateTime? _fechaInicio;
  DateTime? _fechaTermino;
  String? _responsableId;
  bool _guardando = false;

  bool get _esEdicion => widget.proyecto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proyecto;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _tipoCtrl = TextEditingController(text: p?.tipo ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _presupuestoCtrl = TextEditingController(
      text: p?.presupuestoEstimado != null ? p!.presupuestoEstimado!.toStringAsFixed(0) : '',
    );
    _estado = p?.estado ?? EstadoProyecto.planificacion;
    _fechaInicio = p?.fechaInicio;
    _fechaTermino = p?.fechaTermino;
    _responsableId = p?.responsableId;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _tipoCtrl.dispose();
    _descripcionCtrl.dispose();
    _presupuestoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: (esInicio ? _fechaInicio : _fechaTermino) ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (fecha == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = fecha;
      } else {
        _fechaTermino = fecha;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final service = ref.read(proyectoServiceProvider);
      final presupuesto = double.tryParse(_presupuestoCtrl.text.trim());

      if (_esEdicion) {
        final actualizado = widget.proyecto!.copyWith(
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipoCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
          estado: _estado,
          fechaInicio: _fechaInicio,
          fechaTermino: _fechaTermino,
          responsableId: _responsableId,
          presupuestoEstimado: presupuesto,
        );
        await service.actualizarProyecto(actualizado);
      } else {
        await service.crearProyecto(ProyectoModel(
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipoCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
          estado: _estado,
          fechaInicio: _fechaInicio,
          fechaTermino: _fechaTermino,
          responsableId: _responsableId,
          presupuestoEstimado: presupuesto,
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el proyecto: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final personasAsync = ref.watch(personasStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_esEdicion ? 'Editar proyecto' : 'Nuevo proyecto', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre del proyecto'),
                          validator: (v) => Validators.requerido(v, campo: 'El nombre'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _tipoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de proyecto',
                            hintText: 'Ej: Festival musical, Recuperación de espacio...',
                          ),
                          validator: (v) => Validators.requerido(v, campo: 'El tipo de proyecto'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _descripcionCtrl,
                          decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<EstadoProyecto>(
                          initialValue: _estado,
                          decoration: const InputDecoration(labelText: 'Estado'),
                          items: EstadoProyecto.values
                              .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _estado = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        personasAsync.when(
                          data: (personas) => DropdownButtonFormField<String?>(
                            initialValue: _responsableId,
                            decoration: const InputDecoration(labelText: 'Responsable (opcional)'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Sin asignar')),
                              for (final persona in personas)
                                DropdownMenuItem(value: persona.id, child: Text(persona.nombre)),
                            ],
                            onChanged: (value) => setState(() => _responsableId = value),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (e, st) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _elegirFecha(esInicio: true),
                                child: Text(
                                  _fechaInicio != null
                                      ? 'Inicio: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}'
                                      : 'Fecha de inicio',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _elegirFecha(esInicio: false),
                                child: Text(
                                  _fechaTermino != null
                                      ? 'Término: ${DateFormat('dd/MM/yyyy').format(_fechaTermino!)}'
                                      : 'Fecha de término',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _presupuestoCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Presupuesto estimado (opcional, CLP)',
                          ),
                        ),
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
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
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
}
