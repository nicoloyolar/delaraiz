import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_colors.dart';
import '../models/documento_model.dart';

IconData _iconoCategoria(CategoriaDocumento categoria) {
  switch (categoria) {
    case CategoriaDocumento.estatutos:
      return Icons.gavel_rounded;
    case CategoriaDocumento.actas:
      return Icons.description_outlined;
    case CategoriaDocumento.contratos:
      return Icons.handshake_outlined;
    case CategoriaDocumento.informes:
      return Icons.bar_chart_rounded;
    case CategoriaDocumento.otros:
      return Icons.folder_outlined;
  }
}

String _formatearTamano(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(1)} MB';
}

/// Tarjeta de un documento institucional en el grid de "Documentación".
class DocumentoCard extends StatelessWidget {
  const DocumentoCard({
    super.key,
    required this.documento,
    required this.onDescargar,
    required this.onEliminar,
  });

  final DocumentoModel documento;
  final VoidCallback onDescargar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fecha = documento.fechaSubida;

    return Card(
      clipBehavior: Clip.antiAlias,
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
                  child: Icon(_iconoCategoria(documento.categoria), color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    documento.titulo,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                documento.categoria.label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            if (documento.descripcion != null && documento.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                documento.descripcion!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if (fecha != null) DateFormat('dd/MM/yyyy').format(fecha),
                      _formatearTamano(documento.tamanoBytes),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDescargar,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Descargar'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.rechazada,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
