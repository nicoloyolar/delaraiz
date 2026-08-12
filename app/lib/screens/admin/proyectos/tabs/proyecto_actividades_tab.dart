import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_colors.dart';
import '../../../../models/actividad_model.dart';
import '../../../../providers/providers.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/pill.dart';

Color _colorActividad(EstadoActividad estado) {
  switch (estado) {
    case EstadoActividad.pendiente:
      return AppColors.pendiente;
    case EstadoActividad.enCurso:
      return AppColors.accent;
    case EstadoActividad.completada:
      return AppColors.seleccionada;
  }
}

/// Tab "Actividades": tareas puntuales del proyecto con fecha, responsable
/// y estado.
class ProyectoActividadesTab extends ConsumerWidget {
  const ProyectoActividadesTab({super.key, required this.proyectoId});

  final String proyectoId;

  Future<void> _abrirFormulario(BuildContext context, WidgetRef ref, {ActividadModel? actividad}) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ActividadFormDialog(proyectoId: proyectoId, actividad: actividad),
    );
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(proyectoServiceProvider).eliminarActividad(proyectoId, id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actividadesAsync = ref.watch(actividadesStreamProvider(proyectoId));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _abrirFormulario(context, ref),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva actividad'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: actividadesAsync.when(
              data: (actividades) {
                if (actividades.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay actividades registradas.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: actividades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final actividad = actividades[index];
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
                                Text(actividad.titulo, style: Theme.of(context).textTheme.titleSmall),
                                if (actividad.descripcion != null && actividad.descripcion!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(actividad.descripcion!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                                if (actividad.fechaProgramada != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(actividad.fechaProgramada!),
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Pill(label: actividad.estado.label, color: _colorActividad(actividad.estado)),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _abrirFormulario(context, ref, actividad: actividad),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: AppColors.rechazada,
                            onPressed: () => _eliminar(context, ref, actividad.id!),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error al cargar actividades: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActividadFormDialog extends ConsumerStatefulWidget {
  const _ActividadFormDialog({required this.proyectoId, this.actividad});

  final String proyectoId;
  final ActividadModel? actividad;

  @override
  ConsumerState<_ActividadFormDialog> createState() => _ActividadFormDialogState();
}

class _ActividadFormDialogState extends ConsumerState<_ActividadFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late EstadoActividad _estado;
  DateTime? _fecha;
  bool _guardando = false;

  bool get _esEdicion => widget.actividad != null;

  @override
  void initState() {
    super.initState();
    final a = widget.actividad;
    _tituloCtrl = TextEditingController(text: a?.titulo ?? '');
    _descripcionCtrl = TextEditingController(text: a?.descripcion ?? '');
    _estado = a?.estado ?? EstadoActividad.pendiente;
    _fecha = a?.fechaProgramada;
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (fecha != null) setState(() => _fecha = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final service = ref.read(proyectoServiceProvider);
      final actividad = ActividadModel(
        id: widget.actividad?.id,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
        estado: _estado,
        fechaProgramada: _fecha,
      );
      if (_esEdicion) {
        await service.actualizarActividad(widget.proyectoId, actividad);
      } else {
        await service.crearActividad(widget.proyectoId, actividad);
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
                Text(_esEdicion ? 'Editar actividad' : 'Nueva actividad', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => Validators.requerido(v, campo: 'El título'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descripcionCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: _elegirFecha,
                  child: Text(_fecha != null ? DateFormat('dd/MM/yyyy').format(_fecha!) : 'Fecha programada (opcional)'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<EstadoActividad>(
                  initialValue: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: EstadoActividad.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _estado = value);
                  },
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
