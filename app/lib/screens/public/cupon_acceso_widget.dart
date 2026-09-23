import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/app_palette.dart';
import '../../models/credencial_model.dart';
import '../../models/cupon_acceso_model.dart';
import '../../models/local_model.dart';
import '../../providers/providers.dart';

/// Sección de "beneficio de acceso" dentro de la credencial — solo para
/// socios Embajador (agregado 2026-09-23, diseño confirmado con la
/// directiva, ver PROYECTO.md sección 9.15/9.25). Sin locales activos
/// todavía, no muestra nada — no tiene sentido ofrecer generar un cupón
/// para ningún lado.
class CuponAccesoSection extends ConsumerWidget {
  const CuponAccesoSection({super.key, required this.credencial});

  final CredencialModel credencial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El check real de seguridad vive en `firestore.rules` (la regla de
    // `create` de `cupones_acceso` exige `estado == 'activo'`) — esto de acá
    // es solo para no mostrarle a alguien cancelado/moroso un botón que de
    // todas formas le va a fallar. Encontrado en la auditoría de
    // "Credencial del Suscriptor", 2026-09-23: antes solo se revisaba el
    // plan, nunca el estado.
    if (credencial.plan != NivelMembresia.embajador || credencial.estado != EstadoCredencial.activo) {
      return const SizedBox.shrink();
    }
    final localesAsync = ref.watch(localesActivosProvider);
    final cuponAsync = ref.watch(cuponVigentePropioProvider);

    return localesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (locales) {
        if (locales.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acceso a locales adheridos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Genera un cupón de acceso de un solo uso, válido por 12 horas.',
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  cuponAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error: $error'),
                    data: (cupon) => cupon != null
                        ? _CuponVigente(cupon: cupon)
                        : _GenerarCupon(credencial: credencial, locales: locales),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CuponVigente extends StatefulWidget {
  const _CuponVigente({required this.cupon});

  final CuponAccesoModel cupon;

  @override
  State<_CuponVigente> createState() => _CuponVigenteState();
}

class _CuponVigenteState extends State<_CuponVigente> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Solo para refrescar la cuenta regresiva en pantalla — el vencimiento
    // real lo decide `expiraEn` (comparado contra la hora real al validar),
    // no este timer.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _tiempoRestante {
    final restante = widget.cupon.expiraEn.difference(DateTime.now());
    if (restante.isNegative) return 'Expirado';
    final horas = restante.inHours;
    final minutos = restante.inMinutes.remainder(60);
    if (horas > 0) return '$horas h $minutos min';
    return '$minutos min';
  }

  @override
  Widget build(BuildContext context) {
    final url = 'https://delaraiz-app.web.app/validar/${widget.cupon.localId}?codigo=${widget.cupon.codigo}';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: QrImageView(data: url, size: 200, backgroundColor: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(widget.cupon.localNombre, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Vence en: $_tiempoRestante',
          style: TextStyle(color: context.colors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _GenerarCupon extends ConsumerStatefulWidget {
  const _GenerarCupon({required this.credencial, required this.locales});

  final CredencialModel credencial;
  final List<LocalModel> locales;

  @override
  ConsumerState<_GenerarCupon> createState() => _GenerarCuponState();
}

class _GenerarCuponState extends ConsumerState<_GenerarCupon> {
  LocalModel? _localElegido;
  bool _generando = false;

  Future<void> _confirmarYGenerar() async {
    final local = _localElegido;
    if (local == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Generar cupón de acceso?'),
        content: Text(
          'Se activa por 12 horas para "${local.nombre}" y no se puede deshacer. '
          'Solo puedes tener un cupón vigente a la vez.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _generando = true);
    try {
      await ref.read(cuponAccesoServiceProvider).crear(
            socioEmail: widget.credencial.email,
            socioNombre: widget.credencial.nombre,
            localId: local.id,
            localNombre: local.nombre,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<LocalModel>(
          initialValue: _localElegido,
          decoration: const InputDecoration(labelText: 'Elige un local'),
          items: widget.locales
              .map((local) => DropdownMenuItem(value: local, child: Text(local.nombre)))
              .toList(),
          onChanged: _generando ? null : (local) => setState(() => _localElegido = local),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: (_generando || _localElegido == null) ? null : _confirmarYGenerar,
          child: _generando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Generar cupón de acceso'),
        ),
      ],
    );
  }
}
