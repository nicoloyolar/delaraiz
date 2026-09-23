import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_palette.dart';
import '../../../models/evento_model.dart';
import '../../../providers/providers.dart';
import '../../../utils/validators.dart';

/// Diálogo de creación/edición de un evento de la Agenda — agregado
/// 2026-08-18. Mismo esqueleto que ProyectoFormDialog/PersonaFormDialog.
class EventoFormDialog extends ConsumerStatefulWidget {
  const EventoFormDialog({super.key, this.evento, this.proyectoIdInicial, this.fechaInicial});

  final EventoModel? evento;

  /// Preselecciona el proyecto cuando el diálogo se abre desde el filtro ya
  /// aplicado en la Agenda (si hay uno) — evita que el usuario tenga que
  /// elegirlo de nuevo si ya estaba mirando un proyecto puntual.
  final String? proyectoIdInicial;

  /// Preselecciona la fecha cuando el diálogo se abre desde un día ya
  /// elegido en el calendario — ignorado si `evento` no es null (al editar,
  /// siempre manda la fecha real del evento).
  final DateTime? fechaInicial;

  @override
  ConsumerState<EventoFormDialog> createState() => _EventoFormDialogState();
}

class _EventoFormDialogState extends ConsumerState<EventoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _lugarCtrl;
  late final TextEditingController _cupoCtrl;
  late final TextEditingController _notasCtrl;
  final _bandaCtrl = TextEditingController();

  String? _proyectoId;
  late DateTime _fecha;
  late TimeOfDay _hora;
  late EstadoEvento _estado;
  late List<String> _bandas;
  bool _guardando = false;

  bool get _esEdicion => widget.evento != null;

  @override
  void initState() {
    super.initState();
    final e = widget.evento;
    _tituloCtrl = TextEditingController(text: e?.titulo ?? '');
    _lugarCtrl = TextEditingController(text: e?.lugar ?? '');
    _cupoCtrl = TextEditingController(text: e?.cupo?.toString() ?? '');
    _notasCtrl = TextEditingController(text: e?.notas ?? '');
    _proyectoId = e?.proyectoId ?? widget.proyectoIdInicial;
    final fechaInicial = e?.fecha ?? widget.fechaInicial ?? DateTime.now().add(const Duration(days: 7));
    _fecha = DateTime(fechaInicial.year, fechaInicial.month, fechaInicial.day);
    _hora = TimeOfDay(hour: fechaInicial.hour, minute: fechaInicial.minute);
    _estado = e?.estado ?? EstadoEvento.tentativo;
    _bandas = List.of(e?.bandasArtistas ?? const []);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _lugarCtrl.dispose();
    _cupoCtrl.dispose();
    _notasCtrl.dispose();
    _bandaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(context: context, initialTime: _hora);
    if (elegida != null) setState(() => _hora = elegida);
  }

  void _agregarBanda() {
    final nombre = _bandaCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() {
      _bandas.add(nombre);
      _bandaCtrl.clear();
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final service = ref.read(eventoServiceProvider);
      final evento = EventoModel(
        id: widget.evento?.id,
        titulo: _tituloCtrl.text.trim(),
        proyectoId: _proyectoId,
        fecha: DateTime(_fecha.year, _fecha.month, _fecha.day, _hora.hour, _hora.minute),
        lugar: _lugarCtrl.text.trim().isEmpty ? null : _lugarCtrl.text.trim(),
        estado: _estado,
        bandasArtistas: _bandas,
        cupo: int.tryParse(_cupoCtrl.text.trim()),
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );
      if (_esEdicion) {
        await service.actualizarEvento(evento);
      } else {
        await service.crearEvento(evento);
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
    final proyectosAsync = ref.watch(proyectosStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_esEdicion ? 'Editar evento' : 'Nuevo evento', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título', hintText: 'Ej: Cierre de temporada'),
                    validator: (v) => Validators.requerido(v, campo: 'El título'),
                  ),
                  const SizedBox(height: 14),
                  proyectosAsync.when(
                    data: (proyectos) => DropdownButtonFormField<String?>(
                      initialValue: proyectos.any((p) => p.id == _proyectoId) ? _proyectoId : null,
                      decoration: const InputDecoration(
                        labelText: 'Proyecto (opcional)',
                        helperText: 'La agenda es global — no todo evento necesita un proyecto detrás.',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Sin proyecto asociado')),
                        ...proyectos.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.nombre))),
                      ],
                      onChanged: (value) => setState(() => _proyectoId = value),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, st) => Text('Error al cargar proyectos: $e'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _elegirFecha,
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _elegirHora,
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(_hora.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _lugarCtrl,
                    decoration: const InputDecoration(labelText: 'Lugar (opcional)', hintText: 'Ej: Plaza René Schneider'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<EstadoEvento>(
                    initialValue: _estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: EstadoEvento.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _estado = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cupoCtrl,
                    decoration: const InputDecoration(labelText: 'Cupo (opcional)', hintText: 'Ej: 200'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  Text('Bandas / artistas', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bandaCtrl,
                          decoration: const InputDecoration(hintText: 'Nombre de la banda o artista'),
                          onSubmitted: (_) => _agregarBanda(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _agregarBanda,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  if (_bandas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bandas
                          .map((nombre) => InputChip(
                                label: Text(nombre),
                                onDeleted: () => setState(() => _bandas.remove(nombre)),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notasCtrl,
                    decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
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
      ),
    );
  }
}
