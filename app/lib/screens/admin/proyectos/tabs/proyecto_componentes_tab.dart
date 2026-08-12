import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_colors.dart';
import '../../../../app/estado_colors.dart';
import '../../../../models/componente_model.dart';
import '../../../../providers/providers.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/pill.dart';

/// Tab "Componentes": el checklist genérico de "cosas" que necesita el
/// proyecto (equipos, materiales, servicios) — reemplaza las planillas
/// sueltas que se usaban antes por proyecto.
class ProyectoComponentesTab extends ConsumerWidget {
  const ProyectoComponentesTab({super.key, required this.proyectoId});

  final String proyectoId;

  Future<void> _eliminar(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(proyectoServiceProvider).eliminarComponente(proyectoId, id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  Future<void> _cambiarEstado(WidgetRef ref, ComponenteModel componente, EstadoComponente nuevo) async {
    final actualizado = ComponenteModel(
      id: componente.id,
      nombre: componente.nombre,
      tipo: componente.tipo,
      estado: nuevo,
      cantidad: componente.cantidad,
      responsableId: componente.responsableId,
      notas: componente.notas,
    );
    await ref.read(proyectoServiceProvider).actualizarComponente(proyectoId, actualizado);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentesAsync = ref.watch(componentesStreamProvider(proyectoId));

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
                builder: (_) => _ComponenteFormDialog(proyectoId: proyectoId),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuevo componente'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: componentesAsync.when(
              data: (componentes) {
                if (componentes.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay componentes registrados.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: componentes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final componente = componentes[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${componente.nombre}  ×${componente.cantidad}', style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(componente.tipo.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                if (componente.notas != null && componente.notas!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(componente.notas!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<EstadoComponente>(
                            initialValue: componente.estado,
                            onSelected: (nuevo) => _cambiarEstado(ref, componente, nuevo),
                            itemBuilder: (context) => EstadoComponente.values
                                .map((e) => PopupMenuItem(value: e, child: Text(e.label)))
                                .toList(),
                            child: Pill(label: componente.estado.label, color: EstadoColors.componente(componente.estado)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: AppColors.rechazada,
                            onPressed: () => _eliminar(context, ref, componente.id!),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error al cargar componentes: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponenteFormDialog extends ConsumerStatefulWidget {
  const _ComponenteFormDialog({required this.proyectoId});

  final String proyectoId;

  @override
  ConsumerState<_ComponenteFormDialog> createState() => _ComponenteFormDialogState();
}

class _ComponenteFormDialogState extends ConsumerState<_ComponenteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _notasCtrl = TextEditingController();
  TipoComponente _tipo = TipoComponente.otro;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ref.read(proyectoServiceProvider).crearComponente(
            widget.proyectoId,
            ComponenteModel(
              nombre: _nombreCtrl.text.trim(),
              tipo: _tipo,
              cantidad: int.tryParse(_cantidadCtrl.text.trim()) ?? 1,
              notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
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
                Text('Nuevo componente', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => Validators.requerido(v, campo: 'El nombre'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TipoComponente>(
                        initialValue: _tipo,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: TipoComponente.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _tipo = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        controller: _cantidadCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cant.'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notasCtrl,
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                  maxLines: 2,
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
