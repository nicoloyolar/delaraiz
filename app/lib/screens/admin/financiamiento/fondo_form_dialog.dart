import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/postulacion_fondo_model.dart';
import '../../../providers/providers.dart';
import '../../../utils/validators.dart';

/// Diálogo de creación de una postulación a un fondo de financiamiento.
/// Si [proyectoIdFijo] viene dado (se abre desde el tab "Financiamiento"
/// de un proyecto), el proyecto queda preseleccionado y no editable.
class FondoFormDialog extends ConsumerStatefulWidget {
  const FondoFormDialog({super.key, this.proyectoIdFijo});

  final String? proyectoIdFijo;

  @override
  ConsumerState<FondoFormDialog> createState() => _FondoFormDialogState();
}

class _FondoFormDialogState extends ConsumerState<FondoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreFondoCtrl = TextEditingController();
  final _institucionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  String? _proyectoId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _proyectoId = widget.proyectoIdFijo;
  }

  @override
  void dispose() {
    _nombreFondoCtrl.dispose();
    _institucionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proyectoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el proyecto al que corresponde esta postulación.')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await ref.read(fondoServiceProvider).crearPostulacionFondo(
            PostulacionFondoModel(
              nombreFondo: _nombreFondoCtrl.text.trim(),
              institucion: _institucionCtrl.text.trim().isEmpty ? null : _institucionCtrl.text.trim(),
              proyectoId: _proyectoId!,
              montoSolicitado: double.tryParse(_montoCtrl.text.trim()) ?? 0,
            ),
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
    final proyectosAsync = ref.watch(proyectosStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva postulación a fondo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                if (widget.proyectoIdFijo == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: proyectosAsync.when(
                      data: (proyectos) => DropdownButtonFormField<String>(
                        initialValue: _proyectoId,
                        decoration: const InputDecoration(labelText: 'Proyecto'),
                        items: proyectos.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))).toList(),
                        onChanged: (value) => setState(() => _proyectoId = value),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, st) => Text('Error: $e'),
                    ),
                  ),
                TextFormField(
                  controller: _nombreFondoCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del fondo'),
                  validator: (v) => Validators.requerido(v, campo: 'El nombre del fondo'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _institucionCtrl,
                  decoration: const InputDecoration(labelText: 'Institución financiadora (opcional)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto solicitado (CLP)'),
                  validator: (v) => Validators.requerido(v, campo: 'El monto solicitado'),
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
      ),
    );
  }
}
