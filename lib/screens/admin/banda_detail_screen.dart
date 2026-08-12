import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_colors.dart';
import '../../models/banda_model.dart';
import '../../providers/providers.dart';
import '../../widgets/estado_chip.dart';

/// Vista de detalle de una postulación: datos completos de la banda,
/// accesos directos a sus redes/portafolio y al Dossier/Rider en PDF, y
/// el control para cambiar su estado (Pendiente / Seleccionada / Rechazada).
class BandaDetailScreen extends ConsumerWidget {
  const BandaDetailScreen({super.key, required this.bandaId});

  final String bandaId;

  Future<void> _abrirEnlace(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandaAsync = ref.watch(bandaDetalleProvider(bandaId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalle de postulación')),
      body: bandaAsync.when(
        data: (banda) {
          if (banda == null) {
            return const Center(child: Text('Esta postulación no existe.'));
          }
          return _DetalleContenido(banda: banda, onAbrirEnlace: _abrirEnlace);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar: $error')),
      ),
    );
  }
}

class _DetalleContenido extends ConsumerStatefulWidget {
  const _DetalleContenido({required this.banda, required this.onAbrirEnlace});

  final BandaModel banda;
  final Future<void> Function(BuildContext, String?) onAbrirEnlace;

  @override
  ConsumerState<_DetalleContenido> createState() => _DetalleContenidoState();
}

class _DetalleContenidoState extends ConsumerState<_DetalleContenido> {
  late EstadoPostulacion _estadoSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.banda.estado;
  }

  String get _iniciales {
    final palabras = widget.banda.nombreGrupo.trim().split(RegExp(r'\s+'));
    return palabras.take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }

  Future<void> _guardarEstado() async {
    setState(() => _guardando = true);
    try {
      await ref.read(bandaServiceProvider).actualizarEstado(
            id: widget.banda.id!,
            nuevoEstado: _estadoSeleccionado,
          );
      // Refresca la vista de detalle y el listado del dashboard.
      ref.invalidate(bandaDetalleProvider(widget.banda.id!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado actualizado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el estado: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final banda = widget.banda;
    final theme = Theme.of(context);
    final colorEstado = AppColors.estadoColor(banda.estado.name);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header tipo "hero" ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorEstado.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _iniciales,
                        style: theme.textTheme.titleLarge?.copyWith(color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(banda.nombreGrupo, style: theme.textTheme.headlineSmall),
                              ),
                              EstadoChip(estado: banda.estado),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              _iconoTexto(Icons.location_on_outlined, banda.comuna),
                              _iconoTexto(Icons.graphic_eq_rounded, banda.generoMusical),
                              if (banda.fechaPostulacion != null)
                                _iconoTexto(
                                  Icons.event_outlined,
                                  'Postulada el ${DateFormat('dd/MM/yyyy HH:mm').format(banda.fechaPostulacion!)}',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _seccion(
                context,
                icono: Icons.groups_outlined,
                titulo: 'Datos de la banda',
                filas: {
                  'Comuna': banda.comuna,
                  'Género musical': banda.generoMusical,
                  'Teléfono': banda.telefonoContacto,
                  'Correo': banda.correoContacto,
                },
              ),
              const SizedBox(height: 16),

              _seccion(
                context,
                icono: Icons.badge_outlined,
                titulo: 'Representante',
                filas: {
                  'Nombre': banda.nombreRepresentante,
                  'RUT': banda.rutRepresentante,
                },
              ),
              const SizedBox(height: 16),

              _tarjetaEnlaces(context, banda),
              const SizedBox(height: 16),

              _tarjetaArchivos(context, banda),
              const SizedBox(height: 16),

              _tarjetaEstado(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconoTexto(IconData icon, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _tarjetaBase(BuildContext context, {required IconData icono, required String titulo, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _seccion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required Map<String, String> filas,
  }) {
    return _tarjetaBase(
      context,
      icono: icono,
      titulo: titulo,
      child: Column(
        children: [
          for (final entry in filas.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.isEmpty ? '—' : entry.value,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaEnlaces(BuildContext context, BandaModel banda) {
    final enlaces = <String, (IconData, String?)>{
      'Spotify': (Icons.music_note_rounded, banda.linkSpotify),
      'YouTube': (Icons.smart_display_outlined, banda.linkYoutube),
      'Instagram': (Icons.camera_alt_outlined, banda.linkInstagram),
      'Material audiovisual': (Icons.perm_media_outlined, banda.linkMaterialAudiovisual),
    };

    return _tarjetaBase(
      context,
      icono: Icons.link_rounded,
      titulo: 'Enlaces',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in enlaces.entries)
            OutlinedButton.icon(
              onPressed: entry.value.$2 == null
                  ? null
                  : () => widget.onAbrirEnlace(context, entry.value.$2),
              icon: Icon(entry.value.$1, size: 16),
              label: Text(entry.key),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaArchivos(BuildContext context, BandaModel banda) {
    return _tarjetaBase(
      context,
      icono: Icons.folder_outlined,
      titulo: 'Archivos adjuntos',
      child: Column(
        children: [
          _filaArchivo(context, 'Dossier', banda.dossierUrl, banda.dossierNombreArchivo),
          const SizedBox(height: 10),
          _filaArchivo(context, 'Rider técnico', banda.riderTecnicoUrl, banda.riderTecnicoNombreArchivo),
        ],
      ),
    );
  }

  Widget _filaArchivo(BuildContext context, String etiqueta, String? url, String? nombre) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url == null ? '$etiqueta: no adjuntado' : '$etiqueta: ${nombre ?? 'archivo.pdf'}',
              style: const TextStyle(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (url != null)
            FilledButton.icon(
              onPressed: () => widget.onAbrirEnlace(context, url),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Ver / Descargar'),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaEstado(BuildContext context) {
    return _tarjetaBase(
      context,
      icono: Icons.tune_rounded,
      titulo: 'Gestión de la postulación',
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<EstadoPostulacion>(
              initialValue: _estadoSeleccionado,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: EstadoPostulacion.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _estadoSeleccionado = value);
              },
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: _guardando ? null : _guardarEstado,
            child: _guardando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
