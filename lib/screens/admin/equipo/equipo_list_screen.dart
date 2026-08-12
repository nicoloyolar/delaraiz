import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../models/persona_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/admin_shell.dart';
import 'persona_form_dialog.dart';

/// Directorio de Equipo y Voluntarios de la Corporación. Ruta protegida
/// `/admin/equipo`.
class EquipoListScreen extends StatelessWidget {
  const EquipoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      currentRoute: AdminRoute.equipo,
      child: _ContenidoEquipo(),
    );
  }
}

class _ContenidoEquipo extends ConsumerWidget {
  const _ContenidoEquipo();

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref, PersonaModel persona) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar persona'),
        content: Text('¿Seguro que deseas eliminar a "${persona.nombre}" del directorio?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rechazada),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await ref.read(personaServiceProvider).eliminarPersona(persona.id!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personasAsync = ref.watch(personasStreamProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equipo', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Directorio de equipo y voluntariado de la Corporación',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(context: context, builder: (_) => const PersonaFormDialog()),
                icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                label: const Text('Nueva persona'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (value) => ref.read(textoBusquedaPersonasProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: personasAsync.when(
              data: (personas) {
                if (personas.isEmpty) {
                  return Center(
                    child: Text('Aún no hay personas en el directorio.', style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return ListView.separated(
                  itemCount: personas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final persona = personas[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                            child: Icon(
                              persona.tipo == TipoPersona.equipo ? Icons.badge_outlined : Icons.volunteer_activism_outlined,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(persona.nombre, style: Theme.of(context).textTheme.titleSmall),
                                    if (!persona.activo) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('Inactivo', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  [persona.tipo.label, if (persona.rolInstitucional != null) persona.rolInstitucional!].join(' · '),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                if (persona.correo != null || persona.telefono != null)
                                  Text(
                                    [persona.correo, persona.telefono].where((s) => s != null).join(' · '),
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => showDialog<void>(context: context, builder: (_) => PersonaFormDialog(persona: persona)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            color: AppColors.rechazada,
                            onPressed: () => _confirmarEliminar(context, ref, persona),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar el equipo: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
