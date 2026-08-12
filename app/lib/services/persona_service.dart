import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/persona_model.dart';

/// Servicio de acceso a datos para el directorio de Equipo y Voluntarios
/// de la Corporación (colección `personas`).
class PersonaService {
  PersonaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'personas';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Stream<List<PersonaModel>> streamPersonas({String texto = ''}) {
    return _collection.orderBy('nombre').snapshots().map((snapshot) {
      final personas = snapshot.docs.map(PersonaModel.fromFirestore).toList();
      if (texto.trim().isEmpty) return personas;
      final termino = texto.trim().toLowerCase();
      return personas.where((p) => p.nombre.toLowerCase().contains(termino)).toList();
    });
  }

  Future<PersonaModel?> obtenerPersona(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PersonaModel.fromFirestore(doc);
  }

  /// Trae varias personas por id de una vez (para resolver "responsable"
  /// o "equipo del proyecto" al mostrar nombres en pantalla).
  Future<Map<String, PersonaModel>> obtenerPersonas(List<String> ids) async {
    if (ids.isEmpty) return {};
    final unicos = ids.toSet().toList();
    final docs = await Future.wait(unicos.map((id) => _collection.doc(id).get()));
    return {
      for (final doc in docs)
        if (doc.exists) doc.id: PersonaModel.fromFirestore(doc),
    };
  }

  Future<String> crearPersona(PersonaModel persona) async {
    final docRef = await _collection.add(persona.toFirestore());
    return docRef.id;
  }

  Future<void> actualizarPersona(PersonaModel persona) async {
    await _collection.doc(persona.id).update(persona.toFirestore());
  }

  Future<void> eliminarPersona(String id) async {
    await _collection.doc(id).delete();
  }
}
