import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/providers.dart';
import '../../../widgets/admin_shell.dart';
import '../../../widgets/proyecto_card.dart';
import 'proyecto_form_dialog.dart';

/// Listado de todos los Proyectos de la Corporación — la puerta de
/// entrada a la gestión de cada iniciativa (La Grúa del Rock, Festival de
/// Lagunas, etc.). Ruta protegida `/admin/proyectos`.
class ProyectosListScreen extends StatelessWidget {
  const ProyectosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      currentRoute: AdminRoute.proyectos,
      child: _ContenidoProyectos(),
    );
  }
}

class _ContenidoProyectos extends ConsumerWidget {
  const _ContenidoProyectos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectosAsync = ref.watch(proyectosStreamProvider);

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
                    Text('Proyectos', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Cada iniciativa de la Corporación, con sus actividades, bitácora, '
                      'componentes, equipo y financiamiento propios.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ProyectoFormDialog(),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo proyecto'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: proyectosAsync.when(
              data: (proyectos) {
                if (proyectos.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay proyectos creados. Comienza creando el primero.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columnas = (constraints.maxWidth / 300).floor().clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: proyectos.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        mainAxisExtent: 210,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final proyecto = proyectos[index];
                        return ProyectoCard(
                          proyecto: proyecto,
                          onTap: () => context.push('/admin/proyectos/${proyecto.id}'),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar los proyectos: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
