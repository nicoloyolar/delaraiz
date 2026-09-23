import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_palette.dart';
import '../../../app/estado_colors.dart';
import '../../../models/evento_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/pill.dart';
import 'evento_form_dialog.dart';

/// Agenda de eventos — agregada 2026-08-18, a pedido del usuario para
/// juntar en un solo lugar las fechas de todos los proyectos (La Grúa del
/// Rock, Festival de las 7 Lagunas, etc.), en vez de tener que entrar a
/// cada proyecto por separado. Rediseñada el mismo día con un calendario
/// mensual interactivo (antes era solo una lista cronológica) — se hace
/// clic en un día para ver/crear eventos ahí mismo.
///
/// El `AdminShell` (sidebar) lo provee el `ShellRoute` en `app_router.dart`.
/// Ruta protegida `/admin/agenda`.
class AgendaListScreen extends ConsumerWidget {
  const AgendaListScreen({super.key});

  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _confirmarEliminar(BuildContext context, WidgetRef ref, EventoModel evento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Seguro que deseas eliminar "${evento.titulo}"?'),
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
      await ref.read(eventoServiceProvider).eliminarEvento(evento.id!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventosAsync = ref.watch(eventosStreamProvider);
    final proyectosAsync = ref.watch(proyectosStreamProvider);
    final filtroProyecto = ref.watch(filtroProyectoAgendaProvider);
    final diaSeleccionado = ref.watch(diaSeleccionadoAgendaProvider);

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
                    Text('Agenda', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Fechas de todos los proyectos en un solo lugar — haz clic en un día para ver o crear eventos ahí.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => EventoFormDialog(proyectoIdInicial: filtroProyecto, fechaInicial: diaSeleccionado),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo evento'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 300,
            child: proyectosAsync.when(
              data: (proyectos) => DropdownButtonFormField<String?>(
                initialValue: filtroProyecto,
                decoration: const InputDecoration(labelText: 'Proyecto', isDense: true),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Todos los proyectos')),
                  ...proyectos.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.nombre))),
                ],
                onChanged: (value) => ref.read(filtroProyectoAgendaProvider.notifier).state = value,
              ),
              loading: () => const SizedBox(height: 48),
              error: (e, st) => Text('Error: $e'),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: eventosAsync.when(
              data: (eventos) {
                final eventosPorDia = <DateTime, List<EventoModel>>{};
                for (final e in eventos) {
                  eventosPorDia.putIfAbsent(_soloFecha(e.fecha), () => []).add(e);
                }

                return proyectosAsync.when(
                  data: (proyectos) {
                    final nombresPorId = {for (final p in proyectos) p.id: p.nombre};
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final calendario = _CalendarioAgenda(eventosPorDia: eventosPorDia);
                        final listaDia = _ListaDelDia(
                          eventos: eventosPorDia[_soloFecha(diaSeleccionado)] ?? const [],
                          nombresPorId: nombresPorId,
                          onEditar: (evento) =>
                              showDialog<void>(context: context, builder: (_) => EventoFormDialog(evento: evento)),
                          onEliminar: (evento) => _confirmarEliminar(context, ref, evento),
                        );

                        if (constraints.maxWidth < 900) {
                          return Column(
                            children: [
                              calendario,
                              const SizedBox(height: 20),
                              Expanded(child: listaDia),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 380, child: calendario),
                            const SizedBox(width: 24),
                            Expanded(child: listaDia),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error al cargar proyectos: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error al cargar la agenda: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

/// El calendario mensual en sí — envuelve `TableCalendar` con el tema
/// oscuro de la app y un puntito de color bajo los días que tienen algún
/// evento (`eventLoader`).
class _CalendarioAgenda extends ConsumerWidget {
  const _CalendarioAgenda({required this.eventosPorDia});

  final Map<DateTime, List<EventoModel>> eventosPorDia;

  List<EventoModel> _eventosDelDia(DateTime dia) => eventosPorDia[DateTime(dia.year, dia.month, dia.day)] ?? const [];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaSeleccionado = ref.watch(diaSeleccionadoAgendaProvider);
    final diaEnFoco = ref.watch(diaEnFocoAgendaProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: TableCalendar<EventoModel>(
        locale: 'es',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: diaEnFoco,
        currentDay: DateTime.now(),
        selectedDayPredicate: (day) => isSameDay(day, diaSeleccionado),
        eventLoader: _eventosDelDia,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        onDaySelected: (seleccionado, enFoco) {
          ref.read(diaSeleccionadoAgendaProvider.notifier).state = seleccionado;
          ref.read(diaEnFocoAgendaProvider.notifier).state = enFoco;
        },
        onPageChanged: (enFoco) => ref.read(diaEnFocoAgendaProvider.notifier).state = enFoco,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: context.colors.textSecondary),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: context.colors.textSecondary),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600, fontSize: 11.5),
          weekendStyle: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w600, fontSize: 11.5),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: context.colors.textSecondary),
          weekendTextStyle: TextStyle(color: context.colors.textSecondary),
          todayDecoration: BoxDecoration(
            border: Border.all(color: AppColors.accent, width: 1.4),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
          selectedDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          markerSize: 5,
          markersAnchor: 1.35,
        ),
      ),
    );
  }
}

/// Lista de eventos del día seleccionado en el calendario.
class _ListaDelDia extends StatelessWidget {
  const _ListaDelDia({
    required this.eventos,
    required this.nombresPorId,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<EventoModel> eventos;
  final Map<String?, String> nombresPorId;
  final void Function(EventoModel) onEditar;
  final void Function(EventoModel) onEliminar;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final diaSeleccionado = ref.watch(diaSeleccionadoAgendaProvider);
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat("EEEE d 'de' MMMM", 'es').format(diaSeleccionado),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            if (eventos.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No hay eventos este día.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textMuted),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: eventos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    return _FilaEvento(
                      evento: evento,
                      nombreProyecto: evento.proyectoId == null ? null : (nombresPorId[evento.proyectoId] ?? 'Proyecto eliminado'),
                      onEditar: () => onEditar(evento),
                      onEliminar: () => onEliminar(evento),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FilaEvento extends StatelessWidget {
  const _FilaEvento({
    required this.evento,
    required this.nombreProyecto,
    required this.onEditar,
    required this.onEliminar,
  });

  final EventoModel evento;
  final String? nombreProyecto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_outlined, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(evento.titulo, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Pill(label: evento.estado.label, color: EstadoColors.evento(evento.estado)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(evento.fecha),
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (nombreProyecto != null) _filaIcono(context, Icons.auto_awesome_mosaic_outlined, nombreProyecto!),
                    if (evento.lugar != null && evento.lugar!.isNotEmpty) _filaIcono(context, Icons.location_on_outlined, evento.lugar!),
                    if (evento.cupo != null) _filaIcono(context, Icons.confirmation_number_outlined, 'Cupo: ${evento.cupo}'),
                  ],
                ),
                if (evento.bandasArtistas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: evento.bandasArtistas
                        .map((nombre) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(nombre, style: TextStyle(fontSize: 11.5, color: context.colors.textSecondary)),
                            ))
                        .toList(),
                  ),
                ],
                if (evento.notas != null && evento.notas!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(evento.notas!, style: TextStyle(color: context.colors.textMuted, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEditar,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.rechazada,
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }

  Widget _filaIcono(BuildContext context, IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.colors.textMuted),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(color: context.colors.textMuted, fontSize: 12.5)),
      ],
    );
  }
}
