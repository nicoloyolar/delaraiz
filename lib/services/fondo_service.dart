import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/postulacion_fondo_model.dart';
import '../models/rendicion_model.dart';

/// Servicio de acceso a datos para las postulaciones a Fondos y
/// Financiamiento (colección `postulaciones_fondos`) y sus rendiciones de
/// gastos asociadas.
class FondoService {
  FondoService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _collectionPath = 'postulaciones_fondos';
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Stream<List<PostulacionFondoModel>> streamPostulacionesFondos({String? proyectoId}) {
    Query<Map<String, dynamic>> query = _collection.orderBy('createdAt', descending: true);
    if (proyectoId != null) {
      query = query.where('proyectoId', isEqualTo: proyectoId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map(PostulacionFondoModel.fromFirestore).toList());
  }

  Future<PostulacionFondoModel?> obtenerPostulacionFondo(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PostulacionFondoModel.fromFirestore(doc);
  }

  Stream<PostulacionFondoModel?> streamPostulacionFondo(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists ? PostulacionFondoModel.fromFirestore(doc) : null,
        );
  }

  Future<String> crearPostulacionFondo(PostulacionFondoModel postulacion) async {
    final docRef = await _collection.add(postulacion.toFirestore());
    return docRef.id;
  }

  Future<void> actualizarPostulacionFondo(PostulacionFondoModel postulacion) async {
    await _collection.doc(postulacion.id).update(postulacion.toFirestore(isUpdate: true));
  }

  Future<void> eliminarPostulacionFondo(String id) async {
    await _collection.doc(id).delete();
  }

  // --- Rendiciones ---

  CollectionReference<Map<String, dynamic>> _rendicionesCollection(String postulacionId) =>
      _collection.doc(postulacionId).collection('rendiciones');

  Stream<List<RendicionModel>> streamRendiciones(String postulacionId) {
    return _rendicionesCollection(postulacionId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(RendicionModel.fromFirestore).toList());
  }

  Future<void> crearRendicion({
    required String postulacionId,
    required RendicionModel rendicion,
    Uint8List? comprobanteBytes,
    String? comprobanteNombreArchivo,
  }) async {
    var rendicionFinal = rendicion;
    if (comprobanteBytes != null && comprobanteNombreArchivo != null) {
      final extension = comprobanteNombreArchivo.split('.').last;
      final ref = _storage.ref('fondos/$postulacionId/rendiciones/${_uuid.v4()}.$extension');
      final task = await ref.putData(comprobanteBytes, SettableMetadata(contentType: 'application/pdf'));
      final url = await task.ref.getDownloadURL();
      rendicionFinal = RendicionModel(
        concepto: rendicion.concepto,
        monto: rendicion.monto,
        categoria: rendicion.categoria,
        fecha: rendicion.fecha,
        comprobanteUrl: url,
      );
    }
    await _rendicionesCollection(postulacionId).add(rendicionFinal.toFirestore());
  }

  Future<void> eliminarRendicion(String postulacionId, String rendicionId) {
    return _rendicionesCollection(postulacionId).doc(rendicionId).delete();
  }
}
