import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/cupon_model.dart';

/// Servicio del panel de Cupones — a diferencia de casi todos los otros
/// servicios de la app, este NO habla con Firestore directo: el cupón real
/// vive en Flow, y solo el sitio PHP tiene las credenciales para llamar a su
/// API (`inc/flow.php`). Este servicio llama al sitio PHP por HTTP, pasando
/// el ID token de Firebase del admin logueado como parámetro `id_token` del
/// formulario — el sitio lo verifica ahí
/// (`cdlr_flow_verificar_admin_request()`) sin necesitar ningún secreto
/// compartido embebido en el código de la app.
///
/// Va en el body, NO en el header "Authorization": un header custom obliga
/// al navegador a mandar antes una petición OPTIONS de "preflight" de CORS,
/// y LiteSpeed en el hosting del sitio bloquea OPTIONS con 403 a nivel de
/// servidor (confirmado el 2026-08-18 probando contra producción). Yendo en
/// el body, la petición cuenta como "simple" para CORS y nunca dispara el
/// preflight bloqueado.
class CuponesService {
  CuponesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://corporaciondelaraiz.cl/wp-admin/admin-post.php';

  Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No hay sesión iniciada.');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw StateError('No se pudo obtener el token de sesión.');
    }
    return token;
  }

  Future<T> _post<T>(
    String action,
    Map<String, String> body,
    T Function(dynamic data) onSuccess,
  ) async {
    final idToken = await _idToken();
    final response = await _client.post(
      Uri.parse('$_baseUrl?action=$action'),
      body: {...body, 'id_token': idToken},
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      final message = (decoded['data'] is Map)
          ? (decoded['data']['message'] as String? ?? 'Error desconocido')
          : 'Error desconocido';
      throw Exception(message);
    }
    return onSuccess(decoded['data']);
  }

  Future<List<CuponModel>> listar() {
    return _post('cdlr_cupones_listar', {}, (data) {
      final lista = (data as List).cast<Map<String, dynamic>>();
      return lista.map(CuponModel.fromJson).toList();
    });
  }

  Future<CuponModel> crear({
    required String codigo,
    required double percentOff,
    int usosMaximos = 0,
    String expira = '',
  }) {
    return _post(
      'cdlr_cupones_crear',
      {
        'codigo': codigo,
        'percentOff': percentOff.toString(),
        'usosMaximos': usosMaximos.toString(),
        'expira': expira,
      },
      (data) => CuponModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<CuponModel> cambiarEstado(int id, bool activo) {
    return _post(
      'cdlr_cupones_toggle',
      {'id': id.toString(), 'activo': activo.toString()},
      (data) => CuponModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Elimina el cupón por completo — a diferencia de [cambiarEstado], que
  /// solo lo apaga, este ya no vuelve a aparecer en el listado.
  Future<void> eliminar(int id) {
    return _post<void>('cdlr_cupones_eliminar', {'id': id.toString()}, (_) {});
  }
}
