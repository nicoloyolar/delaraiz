import 'dart:async';

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

  /// Transmite todos los socios, más recientes primero. Si Firestore no
  /// responde (típicamente porque todavía no hay un proyecto de Firebase
  /// real conectado — ver `firebase_options.dart`) o la colección está
  /// vacía, muestra un único socio de ejemplo (Pablo Rifo, plan Amigo,
  /// activo) para que el diseño de la pantalla se pueda revisar igual.
  /// Apenas haya datos reales, el placeholder deja de aparecer solo.
  Stream<List<CredencialModel>> streamSocios() {
    try {
      return _collection
          .orderBy('actualizadoEn', descending: true)
          .snapshots()
          .transform(
            StreamTransformer<QuerySnapshot<Map<String, dynamic>>, List<CredencialModel>>.fromHandlers(
              handleData: (snapshot, sink) {
                if (snapshot.docs.isEmpty) {
                  sink.add([_placeholderPabloRifo]);
                  return;
                }
                sink.add(snapshot.docs.map(CredencialModel.fromFirestore).toList());
              },
              handleError: (error, stackTrace, sink) {
                sink.add([_placeholderPabloRifo]);
              },
            ),
          );
    } catch (_) {
      return Stream.value([_placeholderPabloRifo]);
    }
  }

  /// Dato de ejemplo mientras no hay Firebase real conectado — Pablo Rifo
  /// aportó $5.000 (plan Amigo) en la primera prueba real de Flow (ver
  /// `PROYECTO.md`, sección 5.1, prueba del 2026-08-04). No vive en
  /// Firestore, es puramente de demostración visual.
  static final CredencialModel _placeholderPabloRifo = CredencialModel(
    email: 'pablo.1rifo.1@gmail.com',
    nombre: 'Pablo Rifo (ejemplo)',
    plan: NivelMembresia.amigo,
    estado: EstadoCredencial.activo,
    proximoCobro: DateTime(2026, 9, 4),
    actualizadoEn: DateTime(2026, 8, 4),
  );

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
