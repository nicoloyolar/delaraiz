import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_colors.dart';
import '../app/estado_colors.dart';
import '../models/postulacion_fondo_model.dart';
import 'pill.dart';

/// Tarjeta resumen de una postulación a fondo en el listado global de
/// Financiamiento.
class FondoCard extends StatelessWidget {
  const FondoCard({super.key, required this.fondo, required this.nombreProyecto, required this.onTap});

  final PostulacionFondoModel fondo;
  final String nombreProyecto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatoMoneda = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

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
              Text(fondo.nombreFondo, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(nombreProyecto, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              Pill(label: fondo.estado.label, color: EstadoColors.fondo(fondo.estado)),
              const Spacer(),
              Text(formatoMoneda.format(fondo.montoSolicitado), style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text('Solicitado', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
