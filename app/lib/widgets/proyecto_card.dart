import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_colors.dart';
import '../app/estado_colors.dart';
import '../models/proyecto_model.dart';
import 'pill.dart';

/// Tarjeta resumen de un Proyecto en el grid del listado de Proyectos.
class ProyectoCard extends StatelessWidget {
  const ProyectoCard({super.key, required this.proyecto, required this.onTap});

  final ProyectoModel proyecto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.accentSoft,
        splashColor: AppColors.accentSoft,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_mosaic_outlined, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      proyecto.nombre,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (proyecto.aceptaPostulacionesBandas)
                    const Tooltip(
                      message: 'Postulaciones de bandas abiertas',
                      child: Icon(Icons.campaign_rounded, size: 18, color: AppColors.accent),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Pill(label: proyecto.estado.label, color: EstadoColors.proyecto(proyecto.estado)),
              const SizedBox(height: 12),
              if (proyecto.tipo.isNotEmpty)
                Text(
                  proyecto.tipo,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      proyecto.fechaInicio != null
                          ? DateFormat('dd/MM/yyyy').format(proyecto.fechaInicio!)
                          : '—',
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
