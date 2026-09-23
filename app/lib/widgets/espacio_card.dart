import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_palette.dart';
import '../models/espacio_model.dart';

/// Tarjeta resumen de un Espacio recuperado en el grid del listado.
class EspacioCard extends StatelessWidget {
  const EspacioCard({super.key, required this.espacio, required this.onTap});

  final EspacioModel espacio;
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
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.location_city_outlined, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(espacio.nombre, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: context.colors.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  espacio.tipoTenencia.label,
                  style: TextStyle(fontSize: 12, color: context.colors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              _fila(context, Icons.location_on_outlined, '${espacio.direccion}, ${espacio.comuna}'),
              if (espacio.capacidad != null) ...[
                const SizedBox(height: 6),
                _fila(context, Icons.groups_outlined, 'Capacidad: ${espacio.capacidad}'),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 16, color: context.colors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(BuildContext context, IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 15, color: context.colors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
