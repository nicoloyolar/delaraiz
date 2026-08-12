import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_colors.dart';
import '../models/banda_model.dart';
import 'estado_chip.dart';

/// Tarjeta resumen de una postulación, usada en el grid del dashboard
/// admin. Al tocarla se navega a la vista de detalle.
class BandaCard extends StatelessWidget {
  const BandaCard({super.key, required this.banda, required this.onTap});

  final BandaModel banda;
  final VoidCallback onTap;

  String get _iniciales {
    final palabras = banda.nombreGrupo.trim().split(RegExp(r'\s+'));
    final letras = palabras.take(2).map((p) => p.isNotEmpty ? p[0] : '').join();
    return letras.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fecha = banda.fechaPostulacion;
    final colorEstado = AppColors.estadoColor(banda.estado.name);

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
                      border: Border.all(color: colorEstado.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _iniciales,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      banda.nombreGrupo,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              EstadoChip(estado: banda.estado),
              const SizedBox(height: 14),
              _filaIcono(theme, Icons.location_on_outlined, banda.comuna),
              const SizedBox(height: 6),
              _filaIcono(theme, Icons.graphic_eq_rounded, banda.generoMusical),
              const SizedBox(height: 6),
              _filaIcono(theme, Icons.person_outline_rounded, banda.nombreRepresentante),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : '—',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaIcono(ThemeData theme, IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
