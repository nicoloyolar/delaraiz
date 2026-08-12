import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_colors.dart';
import '../../../app/estado_colors.dart';
import '../../../providers/providers.dart';
import '../../../widgets/pill.dart';
import 'proyecto_form_dialog.dart';
import 'tabs/proyecto_actividades_tab.dart';
import 'tabs/proyecto_bandas_tab.dart';
import 'tabs/proyecto_bitacora_tab.dart';
import 'tabs/proyecto_componentes_tab.dart';
import 'tabs/proyecto_equipo_tab.dart';
import 'tabs/proyecto_financiamiento_tab.dart';
import 'tabs/proyecto_info_tab.dart';

/// Vista de detalle de un Proyecto: toda su gestión organizada en tabs
/// (Info, Actividades, Bitácora, Componentes, Equipo, Bandas —solo si
/// aplica— y Financiamiento). Ruta protegida `/admin/proyectos/:id`.
class ProyectoDetailScreen extends ConsumerWidget {
  const ProyectoDetailScreen({super.key, required this.proyectoId});

  final String proyectoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proyectoAsync = ref.watch(proyectoDetalleProvider(proyectoId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: proyectoAsync.when(
        data: (proyecto) {
          if (proyecto == null) {
            return const _ProyectoNoEncontrado();
          }
          return _DetalleContenido(proyectoId: proyectoId, proyecto: proyecto);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar el proyecto: $error')),
      ),
    );
  }
}

class _ProyectoNoEncontrado extends StatelessWidget {
  const _ProyectoNoEncontrado();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proyecto')),
      body: const Center(child: Text('Este proyecto no existe.')),
    );
  }
}

class _DetalleContenido extends StatelessWidget {
  const _DetalleContenido({required this.proyectoId, required this.proyecto});

  final String proyectoId;
  final dynamic proyecto;

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      const Tab(text: 'Info'),
      const Tab(text: 'Actividades'),
      const Tab(text: 'Bitácora'),
      const Tab(text: 'Componentes'),
      const Tab(text: 'Equipo'),
      const Tab(text: 'Bandas'),
      const Tab(text: 'Financiamiento'),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(proyecto.nombre, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Pill(label: proyecto.estado.label, color: EstadoColors.proyecto(proyecto.estado)),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Editar proyecto',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ProyectoFormDialog(proyecto: proyecto),
                ),
              ),
            ],
          ),
          bottom: TabBar(isScrollable: true, tabs: tabs),
        ),
        body: TabBarView(
          children: [
            ProyectoInfoTab(proyecto: proyecto),
            ProyectoActividadesTab(proyectoId: proyectoId),
            ProyectoBitacoraTab(proyectoId: proyectoId),
            ProyectoComponentesTab(proyectoId: proyectoId),
            ProyectoEquipoTab(proyectoId: proyectoId),
            ProyectoBandasTab(proyectoId: proyectoId),
            ProyectoFinanciamientoTab(proyectoId: proyectoId),
          ],
        ),
      ),
    );
  }
}
