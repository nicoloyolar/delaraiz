import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/local_model.dart';

/// CRUD de Locales adheridos al beneficio de acceso de Embajador — agregado
/// 2026-09-23. Escritura solo para admin (ver `firestore.rules`); lectura
/// abierta a cualquier usuario autenticado (el propio socio necesita ver la
/// lista de locales activos para elegir uno al generar su cupón).
class LocalService {
  LocalService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _collectionPath = 'locales';

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection(_collectionPath);

  Stream<List<LocalModel>> streamTodos() {
    return _collection.orderBy('nombre').snapshots().map(
          (snapshot) => snapshot.docs.map(LocalModel.fromFirestore).toList(),
        );
  }

  Stream<List<LocalModel>> streamActivos() {
    return _collection.where('activo', isEqualTo: true).orderBy('nombre').snapshots().map(
          (snapshot) => snapshot.docs.map(LocalModel.fromFirestore).toList(),
        );
  }

  Future<void> crear({required String nombre, required String beneficio}) {
    return _collection.add({'nombre': nombre, 'beneficio': beneficio, 'activo': true});
  }

  Future<void> actualizar(LocalModel local) {
    return _collection.doc(local.id).update(local.toFirestore());
  }

  Future<void> eliminar(String id) {
    return _collection.doc(id).delete();
  }
}
