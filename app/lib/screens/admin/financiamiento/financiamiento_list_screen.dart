import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/providers.dart';
import '../../../widgets/admin_shell.dart';
import '../../../widgets/fondo_card.dart';
import 'fondo_form_dialog.dart';

/// Listado global de postulaciones a fondos de financiamiento, de todos
/// los proyectos de la Corporación. Ruta protegida `/admin/financiamiento`.
class FinanciamientoListScreen extends StatelessWidget {
  const FinanciamientoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      currentRoute: AdminRoute.financiamiento,
      child: _ContenidoFinanciamiento(),
    );
  }
}

class _ContenidoFinanciamiento extends ConsumerWidget {
  const _ContenidoFinanciamiento();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fondosAsync = ref.watch(postulacionesFondosStreamProvider);
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
                    Text('Financiamiento', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Postulaciones a fondos concursables de todos los proyectos',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(context: context, builder: (_) => const FondoFormDialog()),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva postulación'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: fondosAsync.when(
              data: (fondos) {
                if (fondos.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay postulaciones a fondos registradas.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return proyectosAsync.when(
                  data: (proyectos) {
                    final nombresPorId = {for (final p in proyectos) p.id: p.nombre};
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final columnas = (constraints.maxWidth / 280).floor().clamp(1, 4);
                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: fondos.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnas,
                            mainAxisExtent: 190,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemBuilder: (context, index) {
                            final fondo = fondos[index];
                            return FondoCard(
                              fondo: fondo,
                              nombreProyecto: nombresPorId[fondo.proyectoId] ?? 'Proyecto eliminado',
                              onTap: () => context.push('/admin/financiamiento/${fondo.id}'),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error al cargar proyectos: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar el financiamiento: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
