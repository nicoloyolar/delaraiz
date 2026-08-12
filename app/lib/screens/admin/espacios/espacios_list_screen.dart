import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/providers.dart';
import '../../../widgets/admin_shell.dart';
import '../../../widgets/espacio_card.dart';
import 'espacio_form_dialog.dart';

/// Listado de Espacios recuperados o en gestión por la Corporación.
/// Ruta protegida `/admin/espacios`.
class EspaciosListScreen extends StatelessWidget {
  const EspaciosListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(
      currentRoute: AdminRoute.espacios,
      child: _ContenidoEspacios(),
    );
  }
}

class _ContenidoEspacios extends ConsumerWidget {
  const _ContenidoEspacios();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espaciosAsync = ref.watch(espaciosStreamProvider);

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
                    Text('Espacios', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Espacios físicos recuperados o en gestión para uso cultural',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(context: context, builder: (_) => const EspacioFormDialog()),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo espacio'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: espaciosAsync.when(
              data: (espacios) {
                if (espacios.isEmpty) {
                  return Center(
                    child: Text(
                      'Aún no hay espacios registrados.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columnas = (constraints.maxWidth / 300).floor().clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: espacios.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        mainAxisExtent: 220,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        final espacio = espacios[index];
                        return EspacioCard(
                          espacio: espacio,
                          onTap: () => context.push('/admin/espacios/${espacio.id}'),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar los espacios: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
