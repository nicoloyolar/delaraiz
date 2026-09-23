import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/credencial_model.dart';

/// Servicio para el mantenedor de Socios del panel admin — agregado
/// 2026-08-14. A diferencia de [CredencialService] (que un socio usa para
/// ver SU PROPIA credencial), este lee la colección `credenciales` completa
/// y agrega la capacidad de moderación manual (aprobar/rechazar/bloquear).
///
/// Sigue siendo la misma fuente de verdad: el sitio PHP sincroniza acá cada
/// vez que cambia el estado real de una suscripción en Flow. Este servicio
/// nunca toca esos campos (`estado`, `plan`, `proximoCobro`...) — solo lee,
/// y solo escribe `estadoModeracion` (ver `firestore.rules`, que rechaza
/// cualquier otro campo en la escritura desde el cliente).
class SociosAdminService {
  SociosAdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'credenciales';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  /// Transmite todos los socios, más recientes primero. Una colección vacía
  /// se muestra tal cual (el proyecto real de Firebase ya está conectado
  /// desde el 2026-08-18 — antes de eso, mientras no había backend real,
  /// este método mostraba un socio de ejemplo para poder revisar el diseño;
  /// ya no hace falta). Si el stream de Firestore falla, se propaga el
  /// error (la pantalla ya sabe mostrarlo) en vez de disfrazarlo con datos
  /// falsos.
  Stream<List<CredencialModel>> streamSocios() {
    return _collection
        .orderBy('actualizadoEn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CredencialModel.fromFirestore).toList());
  }

  /// Actualiza SOLO la capa de moderación manual de un socio — nunca su
  /// estado real de Flow. Usa `update` (no `set`/`merge`) a propósito: un
  /// socio real siempre tiene su documento ya creado por el sitio PHP antes
  /// de que un admin pueda moderarlo, y `firestore.rules` solo permite
  /// `update` sobre estos 2 campos (no `create`) — moderar algo que no
  /// existe no es un caso válido.
  Future<void> actualizarEstadoModeracion(String email, EstadoModeracion nuevoEstado) {
    final id = email.trim().toLowerCase();
    return _collection.doc(id).update({
      'estadoModeracion': nuevoEstado.name,
      'estadoModeracionActualizadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Corrige nombre/email de un socio — agregado 2026-09-23 (auditoría de
  /// pre-lanzamiento: antes no había NINGUNA forma de arreglar un typo sin
  /// acceso directo al servidor). A diferencia del resto de este servicio,
  /// esto NO escribe directo a Firestore: el dato real vive en WordPress
  /// (`cdlr_socio`), así que se llama al sitio PHP (mismo patrón HTTP +
  /// token de Firebase que `CuponesService`) para que sea WordPress quien
  /// corrija su propio dato y vuelva a sincronizar Firestore — escribirlo
  /// directo acá se habría perdido en el próximo cobro mensual, que vuelve a
  /// sincronizar desde WordPress y pisa cualquier cambio hecho solo en
  /// Firestore. A propósito NO permite cambiar el plan (ver comentario en
  /// `cdlr_flow_editar_socio()` del lado PHP).
  Future<void> editarDatos({
    required String emailActual,
    required String nombre,
    required String emailNuevo,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No hay sesión iniciada.');
    }
    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw StateError('No se pudo obtener el token de sesión.');
    }

    final response = await http.post(
      Uri.parse('https://corporaciondelaraiz.cl/wp-admin/admin-post.php?action=cdlr_socios_editar'),
      body: {
        'emailActual': emailActual,
        'nombre': nombre,
        'email': emailNuevo,
        'id_token': idToken,
      },
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['success'] != true) {
      final message = (decoded['data'] is Map)
          ? (decoded['data']['message'] as String? ?? 'Error desconocido')
          : 'Error desconocido';
      throw Exception(message);
    }
  }
}
