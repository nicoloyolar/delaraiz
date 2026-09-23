import 'dart:convert';

import 'package:http/http.dart' as http;

/// Resultado de intentar validar un cupón de acceso — `mensaje` es siempre
/// para mostrar tal cual en pantalla (viene armado del lado PHP).
class ValidarCuponResultado {
  const ValidarCuponResultado({required this.exito, required this.mensaje, this.socioNombre});

  final bool exito;
  final String mensaje;
  final String? socioNombre;
}

/// Consume un cupón de acceso QR de Embajador — a propósito NO pasa por
/// Firestore directo desde el navegador: quien valida en la puerta de un
/// local no tiene cuenta de Firebase, así que esto llama al sitio PHP (que sí
/// tiene una cuenta de servicio) para hacer la lectura/escritura real. Sin
/// token de admin: cualquiera puede llamar este endpoint, pero sin el código
/// exacto (largo y aleatorio) no hay nada que validar — la seguridad viene
/// del código, no de quién llama.
class ValidarCuponService {
  ValidarCuponService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _url = 'https://corporaciondelaraiz.cl/wp-admin/admin-post.php?action=cdlr_validar_cupon_acceso';

  Future<ValidarCuponResultado> validar({required String localId, required String codigo}) async {
    final response = await _client.post(
      Uri.parse(_url),
      body: {'localId': localId, 'codigo': codigo.trim()},
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    final mensaje = (data is Map ? data['message'] as String? : null) ?? 'Error desconocido.';
    final socioNombre = data is Map ? data['socioNombre'] as String? : null;
    return ValidarCuponResultado(exito: decoded['success'] == true, mensaje: mensaje, socioNombre: socioNombre);
  }
}
