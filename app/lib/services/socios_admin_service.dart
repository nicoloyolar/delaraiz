import 'package:cloud_firestore/cloud_firestore.dart';

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
}
