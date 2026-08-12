import 'package:flutter/material.dart';

/// Chip tipo "pill" genérico (punto de color + etiqueta), usado para
/// mostrar el estado de cualquier entidad (proyecto, componente, fondo,
/// etc.) con estilo consistente. [EstadoChip] sigue existiendo para el
/// caso específico de postulaciones de bandas.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorSoft = color.withValues(alpha: 0.15);

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
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
