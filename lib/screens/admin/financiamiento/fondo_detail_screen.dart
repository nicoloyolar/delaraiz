import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_colors.dart';
import '../../../app/estado_colors.dart';
import '../../../models/postulacion_fondo_model.dart';
import '../../../models/rendicion_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/pill.dart';

/// Vista de detalle de una postulación a fondo: datos generales, estado
/// editable y las rendiciones de gastos asociadas. Ruta protegida
/// `/admin/financiamiento/:id`.
class FondoDetailScreen extends ConsumerWidget {
  const FondoDetailScreen({super.key, required this.fondoId});

  final String fondoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fondoAsync = ref.watch(fondoDetalleProvider(fondoId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Postulación a fondo')),
      body: fondoAsync.when(
        data: (fondo) {
          if (fondo == null) return const Center(child: Text('Esta postulación no existe.'));
          return _DetalleContenido(fondo: fondo);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar: $error')),
      ),
    );
  }
}

class _DetalleContenido extends ConsumerStatefulWidget {
  const _DetalleContenido({required this.fondo});

  final PostulacionFondoModel fondo;

  @override
  ConsumerState<_DetalleContenido> createState() => _DetalleContenidoState();
}

class _DetalleContenidoState extends ConsumerState<_DetalleContenido> {
  late EstadoFondo _estadoSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.fondo.estado;
  }

  Future<void> _guardarEstado() async {
    setState(() => _guardando = true);
    try {
      final actualizado = PostulacionFondoModel(
        id: widget.fondo.id,
        nombreFondo: widget.fondo.nombreFondo,
        institucion: widget.fondo.institucion,
        proyectoId: widget.fondo.proyectoId,
        montoSolicitado: widget.fondo.montoSolicitado,
        montoAprobado: widget.fondo.montoAprobado,
        estado: _estadoSeleccionado,
        fechaPostulacion: widget.fondo.fechaPostulacion,
        fechaResolucion: widget.fondo.fechaResolucion,
        plazoRendicion: widget.fondo.plazoRendicion,
        documentoUrls: widget.fondo.documentoUrls,
        notas: widget.fondo.notas,
      );
      await ref.read(fondoServiceProvider).actualizarPostulacionFondo(actualizado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fondo = widget.fondo;
    final theme = Theme.of(context);
    final formatoMoneda = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);
    final rendicionesAsync = ref.watch(rendicionesStreamProvider(fondo.id!));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(fondo.nombreFondo, style: theme.textTheme.headlineSmall)),
                        Pill(label: fondo.estado.label, color: EstadoColors.fondo(fondo.estado)),
                      ],
                    ),
                    if (fondo.institucion != null) ...[
                      const SizedBox(height: 6),
                      Text(fondo.institucion!, style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _metric('Monto solicitado', formatoMoneda.format(fondo.montoSolicitado)),
                        _metric('Monto aprobado', fondo.montoAprobado != null ? formatoMoneda.format(fondo.montoAprobado) : '—'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _tarjeta(
                context,
                icono: Icons.tune_rounded,
                titulo: 'Estado de la postulación',
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<EstadoFondo>(
                        initialValue: _estadoSeleccionado,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        items: EstadoFondo.values.map((e) => DropdownMenuItem(value: e, child: Text(e.label))).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _estadoSeleccionado = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _guardando ? null : _guardarEstado,
                      child: _guardando
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _tarjeta(
                context,
                icono: Icons.receipt_long_outlined,
                titulo: 'Rendiciones de gastos',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    rendicionesAsync.when(
                      data: (rendiciones) {
                        if (rendiciones.isEmpty) {
                          return const Text('Aún no hay gastos rendidos.', style: TextStyle(color: AppColors.textSecondary));
                        }
                        final totalRendido = rendiciones.fold<double>(0, (acc, r) => acc + r.monto);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total rendido: ${formatoMoneda.format(totalRendido)}', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 12),
                            for (final rendicion in rendiciones) _filaRendicion(context, ref, fondo.id!, rendicion, formatoMoneda),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => Text('Error al cargar rendiciones: $e'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _RendicionFormDialog(postulacionId: fondo.id!),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agregar rendición'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }

  Widget _tarjeta(BuildContext context, {required IconData icono, required String titulo, required Widget child}) {
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

  Widget _filaRendicion(BuildContext context, WidgetRef ref, String postulacionId, RendicionModel rendicion, NumberFormat formato) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rendicion.concepto, style: const TextStyle(color: AppColors.textPrimary)),
                  if (rendicion.fecha != null)
                    Text(DateFormat('dd/MM/yyyy').format(rendicion.fecha!), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(formato.format(rendicion.monto), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            if (rendicion.comprobanteUrl != null)
              IconButton(
                icon: const Icon(Icons.receipt_outlined, size: 18),
                tooltip: 'Ver comprobante',
                onPressed: () async {
                  final uri = Uri.tryParse(rendicion.comprobanteUrl!);
                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: AppColors.rechazada,
              onPressed: () => ref.read(fondoServiceProvider).eliminarRendicion(postulacionId, rendicion.id!),
            ),
          ],
        ),
      ),
    );
  }
}

class _RendicionFormDialog extends ConsumerStatefulWidget {
  const _RendicionFormDialog({required this.postulacionId});

  final String postulacionId;

  @override
  ConsumerState<_RendicionFormDialog> createState() => _RendicionFormDialogState();
}

class _RendicionFormDialogState extends ConsumerState<_RendicionFormDialog> {
  final _conceptoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  PlatformFile? _comprobante;
  bool _guardando = false;

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirComprobante() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _comprobante = result.files.single);
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_montoCtrl.text.trim());
    if (_conceptoCtrl.text.trim().isEmpty || monto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa el concepto y el monto.')));
      return;
    }
    setState(() => _guardando = true);
    try {
      await ref.read(fondoServiceProvider).crearRendicion(
            postulacionId: widget.postulacionId,
            rendicion: RendicionModel(concepto: _conceptoCtrl.text.trim(), monto: monto),
            comprobanteBytes: _comprobante?.bytes,
            comprobanteNombreArchivo: _comprobante?.name,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agregar rendición', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(controller: _conceptoCtrl, decoration: const InputDecoration(labelText: 'Concepto del gasto')),
              const SizedBox(height: 14),
              TextField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monto (CLP)'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _comprobante?.name ?? 'Comprobante (opcional)',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton(onPressed: _elegirComprobante, child: const Text('Elegir PDF')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _guardando ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
