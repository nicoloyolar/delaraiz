import 'package:flutter/material.dart';

import '../app/app_colors.dart';
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
                decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  espacio.tipoTenencia.label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              _fila(Icons.location_on_outlined, '${espacio.direccion}, ${espacio.comuna}'),
              if (espacio.capacidad != null) ...[
                const SizedBox(height: 6),
                _fila(Icons.groups_outlined, 'Capacidad: ${espacio.capacidad}'),
              ],
              const Spacer(),
              const Row(
                children: [
                  Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
