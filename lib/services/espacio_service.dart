import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/espacio_model.dart';
import '../models/proyecto_model.dart';

/// Servicio de acceso a datos para los Espacios recuperados por la
/// Corporación (colección `espacios`), incluida la subida de fotos y
/// documentación legal a Storage.
class EspacioService {
  EspacioService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _collectionPath = 'espacios';
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Stream<List<EspacioModel>> streamEspacios() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(EspacioModel.fromFirestore).toList());
  }

  Future<EspacioModel?> obtenerEspacio(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return EspacioModel.fromFirestore(doc);
  }

  Stream<EspacioModel?> streamEspacio(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists ? EspacioModel.fromFirestore(doc) : null,
        );
  }

  /// Proyectos que usan (o usaron) este espacio — el "historial de uso" se
  /// deriva de esta consulta en vez de duplicarse en el espacio.
  Stream<List<ProyectoModel>> streamProyectosDelEspacio(String espacioId) {
    return _firestore
        .collection('proyectos')
        .where('espacioIds', arrayContains: espacioId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ProyectoModel.fromFirestore).toList());
  }

  Future<String> _subirArchivo({
    required Uint8List bytes,
    required String nombreArchivoOriginal,
    required String espacioId,
    required String carpeta,
  }) async {
    final extension = nombreArchivoOriginal.split('.').last;
    final ref = _storage.ref('espacios/$espacioId/$carpeta/${_uuid.v4()}.$extension');
    final contentType = carpeta == 'fotos' ? 'image/jpeg' : 'application/pdf';
    final task = await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return task.ref.getDownloadURL();
  }

  Future<String> crearEspacio(
    EspacioModel espacio, {
    List<({Uint8List bytes, String nombre})> fotos = const [],
    List<({Uint8List bytes, String nombre})> documentos = const [],
  }) async {
    final docRef = _collection.doc();

    final fotoUrls = <String>[];
    for (final foto in fotos) {
      fotoUrls.add(await _subirArchivo(
        bytes: foto.bytes,
        nombreArchivoOriginal: foto.nombre,
        espacioId: docRef.id,
        carpeta: 'fotos',
      ));
    }

    final documentoUrls = <String>[];
    for (final documento in documentos) {
      documentoUrls.add(await _subirArchivo(
        bytes: documento.bytes,
        nombreArchivoOriginal: documento.nombre,
        espacioId: docRef.id,
        carpeta: 'documentos',
      ));
    }

    final espacioConArchivos = espacio.copyWith(fotoUrls: fotoUrls, documentoUrls: documentoUrls);
    await docRef.set(espacioConArchivos.toFirestore());
    return docRef.id;
  }

  Future<void> actualizarEspacio(EspacioModel espacio) async {
    await _collection.doc(espacio.id).update(espacio.toFirestore(isUpdate: true));
  }

  Future<void> eliminarEspacio(String id) async {
    await _collection.doc(id).delete();
  }
}
