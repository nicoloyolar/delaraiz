import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/evento_model.dart';

/// Servicio de acceso a datos para la Agenda (colección `eventos`) —
/// agregada 2026-08-18. Mismo patrón que `FondoService`: colección de nivel
/// superior con un filtro opcional por `proyectoId`, para que la misma
/// consulta sirva tanto para la vista global (todos los proyectos) como
/// para un filtro puntual, sin duplicar lógica.
class EventoService {
  EventoService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'eventos';

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection(_collectionPath);

  /// Ordenado por fecha ascendente (agenda: lo próximo primero) — a
  /// diferencia de `streamPostulacionesFondos()`, que ordena por
  /// `createdAt` descendente porque ahí importa qué se creó más reciente,
  /// no cuándo ocurre.
  Stream<List<EventoModel>> streamEventos({String? proyectoId}) {
    Query<Map<String, dynamic>> query = _collection.orderBy('fecha');
    if (proyectoId != null) {
      query = query.where('proyectoId', isEqualTo: proyectoId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map(EventoModel.fromFirestore).toList());
  }

  Future<void> crearEvento(EventoModel evento) {
    return _collection.add(evento.toFirestore());
  }

  Future<void> actualizarEvento(EventoModel evento) {
    return _collection.doc(evento.id).update(evento.toFirestore(isUpdate: true));
  }

  Future<void> eliminarEvento(String id) {
    return _collection.doc(id).delete();
  }
}
