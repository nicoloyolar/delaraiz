import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/banda_model.dart';

/// Chip de estado tipo "pill" (punto de color + etiqueta) usado en el
/// listado y en la vista de detalle del dashboard admin.
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});

  final EstadoPostulacion estado;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.estadoColor(estado.name);
    final colorSoft = AppColors.estadoColorSoft(estado.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            estado.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
