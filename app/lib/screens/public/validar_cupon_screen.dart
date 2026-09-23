import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../services/validar_cupon_service.dart';

/// Pantalla pública para validar un cupón de acceso QR de Embajador —
/// agregada 2026-09-23. Sin login: la usa quien recibe a los socios en la
/// puerta de un local, en su propio celular. El QR de la credencial del
/// socio codifica directo la URL de esta pantalla (con el código ya en la
/// query string), así que escanearlo con la cámara nativa del celular
/// (ninguna app especial) ya abre esto con el código prellenado — "escribir
/// el código" (sin escanear nada) también funciona, por si el celular del
/// local no tiene cámara a mano o el QR no se lee bien.
class ValidarCuponScreen extends StatefulWidget {
  const ValidarCuponScreen({super.key, required this.localId, this.codigoInicial});

  final String localId;
  final String? codigoInicial;

  @override
  State<ValidarCuponScreen> createState() => _ValidarCuponScreenState();
}

class _ValidarCuponScreenState extends State<ValidarCuponScreen> {
  late final TextEditingController _codigoCtrl;
  final _service = ValidarCuponService();
  bool _validando = false;
  ValidarCuponResultado? _resultado;

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.codigoInicial ?? '');
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    if (_codigoCtrl.text.trim().isEmpty) return;
    setState(() {
      _validando = true;
      _resultado = null;
    });
    try {
      final resultado = await _service.validar(localId: widget.localId, codigo: _codigoCtrl.text);
      setState(() => _resultado = resultado);
    } catch (e) {
      setState(() => _resultado = ValidarCuponResultado(exito: false, mensaje: 'No se pudo validar: $e'));
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _resultado;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Validar acceso'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 48, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'Escribe o pega el código del cupón que te muestre la persona.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codigoCtrl,
                  textAlign: TextAlign.center,
                  autofocus: widget.codigoInicial == null,
                  decoration: const InputDecoration(labelText: 'Código'),
                  onSubmitted: (_) => _validar(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _validando ? null : _validar,
                  child: _validando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Validar'),
                ),
                if (resultado != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (resultado.exito ? AppColors.seleccionada : AppColors.rechazada).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: resultado.exito ? AppColors.seleccionada : AppColors.rechazada),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          resultado.exito ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: resultado.exito ? AppColors.seleccionada : AppColors.rechazada,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        if (resultado.exito && resultado.socioNombre != null) ...[
                          Text(
                            resultado.socioNombre!,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(resultado.mensaje, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
