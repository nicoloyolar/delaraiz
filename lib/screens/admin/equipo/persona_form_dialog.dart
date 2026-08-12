import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/persona_model.dart';
import '../../../providers/providers.dart';
import '../../../utils/validators.dart';

/// Diálogo de creación/edición de una persona del directorio (equipo o
/// voluntariado) de la Corporación.
class PersonaFormDialog extends ConsumerStatefulWidget {
  const PersonaFormDialog({super.key, this.persona});

  final PersonaModel? persona;

  @override
  ConsumerState<PersonaFormDialog> createState() => _PersonaFormDialogState();
}

class _PersonaFormDialogState extends ConsumerState<PersonaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _rolCtrl;
  late final TextEditingController _notasCtrl;
  late TipoPersona _tipo;
  late bool _activo;
  bool _guardando = false;

  bool get _esEdicion => widget.persona != null;

  @override
  void initState() {
    super.initState();
    final p = widget.persona;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _correoCtrl = TextEditingController(text: p?.correo ?? '');
    _telefonoCtrl = TextEditingController(text: p?.telefono ?? '');
    _rolCtrl = TextEditingController(text: p?.rolInstitucional ?? '');
    _notasCtrl = TextEditingController(text: p?.notas ?? '');
    _tipo = p?.tipo ?? TipoPersona.voluntario;
    _activo = p?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _rolCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final service = ref.read(personaServiceProvider);
      final persona = PersonaModel(
        id: widget.persona?.id,
        nombre: _nombreCtrl.text.trim(),
        correo: _correoCtrl.text.trim().isEmpty ? null : _correoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
        tipo: _tipo,
        rolInstitucional: _rolCtrl.text.trim().isEmpty ? null : _rolCtrl.text.trim(),
        activo: _activo,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        usuarioUid: widget.persona?.usuarioUid,
      );
      if (_esEdicion) {
        await service.actualizarPersona(persona);
      } else {
        await service.crearPersona(persona);
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
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_esEdicion ? 'Editar persona' : 'Nueva persona', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) => Validators.requerido(v, campo: 'El nombre'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _correoCtrl,
                  decoration: const InputDecoration(labelText: 'Correo (opcional)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TipoPersona>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: TipoPersona.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _tipo = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _rolCtrl,
                  decoration: const InputDecoration(labelText: 'Rol institucional (opcional)', hintText: 'Ej: Coordinadora de cultura'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notasCtrl,
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: _activo,
                  onChanged: (value) => setState(() => _activo = value),
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
}
