import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/local_model.dart';
import '../../../providers/providers.dart';
import '../../../utils/validators.dart';

/// Crear (o editar) un local adherido al beneficio de acceso de Embajador —
/// agregado 2026-09-23. Sin campo de "activo" acá a propósito: un local
/// nuevo siempre arranca activo (se desactiva después desde el switch de la
/// lista, no tiene sentido crear uno ya inactivo).
class LocalFormDialog extends ConsumerStatefulWidget {
  const LocalFormDialog({super.key, this.local});

  /// `null` = crear uno nuevo. Si viene, es edición.
  final LocalModel? local;

  @override
  ConsumerState<LocalFormDialog> createState() => _LocalFormDialogState();
}

class _LocalFormDialogState extends ConsumerState<LocalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _beneficioCtrl;
  bool _guardando = false;
  String? _error;

  bool get _esEdicion => widget.local != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.local?.nombre ?? '');
    _beneficioCtrl = TextEditingController(text: widget.local?.beneficio ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _beneficioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final service = ref.read(localServiceProvider);
      if (_esEdicion) {
        await service.actualizar(LocalModel(
          id: widget.local!.id,
          nombre: _nombreCtrl.text.trim(),
          beneficio: _beneficioCtrl.text.trim(),
          activo: widget.local!.activo,
        ));
      } else {
        await service.crear(nombre: _nombreCtrl.text.trim(), beneficio: _beneficioCtrl.text.trim());
      }
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
                Text(_esEdicion ? 'Editar local' : 'Nuevo local', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del local'),
                  validator: (v) => Validators.requerido(v, campo: 'El nombre'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _beneficioCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Beneficio',
                    hintText: 'Ej: Entrada liberada para Embajadores',
                  ),
                  validator: (v) => Validators.requerido(v, campo: 'El beneficio'),
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
