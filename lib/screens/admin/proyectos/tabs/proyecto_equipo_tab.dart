import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_colors.dart';
import '../../../../models/proyecto_miembro_model.dart';
import '../../../../providers/providers.dart';

/// Tab "Equipo": personas del directorio institucional asignadas a este
/// proyecto, con el rol que cumplen específicamente en él.
class ProyectoEquipoTab extends ConsumerWidget {
  const ProyectoEquipoTab({super.key, required this.proyectoId});

  final String proyectoId;

  Future<void> _quitar(BuildContext context, WidgetRef ref, String miembroId) async {
    try {
      await ref.read(proyectoServiceProvider).quitarMiembro(proyectoId, miembroId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo quitar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipoAsync = ref.watch(equipoProyectoStreamProvider(proyectoId));
    final personasAsync = ref.watch(personasStreamProvider);

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
                builder: (_) => _AgregarMiembroDialog(proyectoId: proyectoId),
              ),
              icon: const Icon(Icons.person_add_alt_rounded, size: 18),
              label: const Text('Agregar al equipo'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: equipoAsync.when(
              data: (miembros) {
                if (miembros.isEmpty) {
                  return const Center(
                    child: Text('Aún no hay personas asignadas a este proyecto.', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return personasAsync.when(
                  data: (personas) {
                    final personasPorId = {for (final p in personas) p.id: p};
                    return ListView.separated(
                      itemCount: miembros.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final miembro = miembros[index];
                        final persona = personasPorId[miembro.personaId];
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
                                    Text(persona?.nombre ?? 'Persona eliminada', style: Theme.of(context).textTheme.titleSmall),
                                    Text(miembro.rolEnProyecto, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: AppColors.rechazada,
                                onPressed: () => _quitar(context, ref, miembro.id!),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error al cargar personas: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error al cargar el equipo: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgregarMiembroDialog extends ConsumerStatefulWidget {
  const _AgregarMiembroDialog({required this.proyectoId});

  final String proyectoId;

  @override
  ConsumerState<_AgregarMiembroDialog> createState() => _AgregarMiembroDialogState();
}

class _AgregarMiembroDialogState extends ConsumerState<_AgregarMiembroDialog> {
  final _rolCtrl = TextEditingController();
  String? _personaId;
  bool _guardando = false;

  @override
  void dispose() {
    _rolCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_personaId == null || _rolCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una persona y su rol en el proyecto.')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(proyectoServiceProvider).agregarMiembro(
            widget.proyectoId,
            ProyectoMiembroModel(personaId: _personaId!, rolEnProyecto: _rolCtrl.text.trim()),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo agregar: $e')));
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agregar al equipo del proyecto', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              personasAsync.when(
                data: (personas) {
                  if (personas.isEmpty) {
                    return const Text(
                      'Aún no hay personas en el directorio. Crea una desde la sección "Equipo".',
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _personaId,
                    decoration: const InputDecoration(labelText: 'Persona'),
                    items: personas.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))).toList(),
                    onChanged: (value) => setState(() => _personaId = value),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _rolCtrl,
                decoration: const InputDecoration(labelText: 'Rol en este proyecto', hintText: 'Ej: Coordinador técnico'),
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
                        : const Text('Agregar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
