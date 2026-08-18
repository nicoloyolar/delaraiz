import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/providers.dart';
import '../../../utils/validators.dart';

/// Diálogo de creación de un cupón de descuento — agregado 2026-08-18. No
/// tiene modo edición (a diferencia de PersonaFormDialog/ProyectoFormDialog):
/// una vez creado en Flow, un cupón no se puede editar ahí (solo
/// activar/desactivar de nuestro lado, ver el menú ⋮ en CuponesListScreen).
class CuponFormDialog extends ConsumerStatefulWidget {
  const CuponFormDialog({super.key});

  @override
  ConsumerState<CuponFormDialog> createState() => _CuponFormDialogState();
}

class _CuponFormDialogState extends ConsumerState<CuponFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _descuentoCtrl = TextEditingController(text: '100');
  final _usosMaximosCtrl = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descuentoCtrl.dispose();
    _usosMaximosCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(cuponesServiceProvider).crear(
            codigo: _codigoCtrl.text.trim(),
            percentOff: double.parse(_descuentoCtrl.text.trim()),
            usosMaximos: int.tryParse(_usosMaximosCtrl.text.trim()) ?? 0,
          );
      ref.invalidate(cuponesListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Nuevo cupón', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Se crea de verdad en Flow — quien lo use en /membresia/ paga '
                  'el monto del plan menos el % de descuento.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _codigoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    hintText: 'Ej: DIRECTORIO2026',
                  ),
                  validator: (v) => Validators.requerido(v, campo: 'El código'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descuentoCtrl,
                  decoration: const InputDecoration(
                    labelText: '% de descuento',
                    hintText: '100 = aporte queda en \$0',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0 || n > 100) {
                      return 'Debe ser un número entre 1 y 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usosMaximosCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Usos máximos (opcional)',
                    hintText: 'Ej: 6 — cantidad de directores. Vacío = sin límite',
                  ),
                  keyboardType: TextInputType.number,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
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
                          : const Text('Crear cupón'),
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
