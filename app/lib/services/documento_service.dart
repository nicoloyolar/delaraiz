import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/documento_model.dart';

/// Servicio de acceso a datos para la documentación institucional de la
/// Corporación (estatutos, actas, contratos, informes). A diferencia de
/// los Dossiers de bandas, esta colección es de uso exclusivamente
/// interno: solo la directiva autenticada puede leer y escribir.
class DocumentoService {
  DocumentoService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _collectionPath = 'documentos_institucionales';
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  /// Sube un documento (PDF) al panel institucional: primero el archivo
  /// a Storage y luego los metadatos a Firestore.
  Future<String> subirDocumento({
    required String titulo,
    required CategoriaDocumento categoria,
    String? descripcion,
    required Uint8List archivoBytes,
    required String nombreArchivoOriginal,
  }) async {
    final docRef = _collection.doc();
    final extension = nombreArchivoOriginal.split('.').last;
    final nombreUnico = '${_uuid.v4()}.$extension';
    final storagePath = 'documentos_institucionales/${docRef.id}/$nombreUnico';

    final ref = _storage.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: extension.toLowerCase() == 'pdf' ? 'application/pdf' : 'application/octet-stream',
    );
    final task = await ref.putData(archivoBytes, metadata);
    final url = await task.ref.getDownloadURL();

    final documento = DocumentoModel(
      titulo: titulo,
      categoria: categoria,
      descripcion: descripcion,
      archivoUrl: url,
      nombreArchivo: nombreArchivoOriginal,
      storagePath: storagePath,
      tamanoBytes: archivoBytes.length,
    );

    await docRef.set(documento.toFirestore());
    return docRef.id;
  }

  /// Stream en tiempo real de documentos, con filtro opcional por
  /// categoría y búsqueda de texto por título (aplicada en cliente).
  Stream<List<DocumentoModel>> streamDocumentos({
    CategoriaDocumento? categoria,
    String texto = '',
  }) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('fechaSubida', descending: true);

    if (categoria != null) {
      query = query.where('categoria', isEqualTo: categoria.name);
    }

    return query.snapshots().map((snapshot) {
      final documentos = snapshot.docs.map(DocumentoModel.fromFirestore).toList();

      if (texto.trim().isEmpty) return documentos;

      final termino = texto.trim().toLowerCase();
      return documentos.where((d) => d.titulo.toLowerCase().contains(termino)).toList();
    });
  }

  /// Elimina un documento: primero el archivo en Storage y luego el
  /// registro en Firestore.
  Future<void> eliminarDocumento(DocumentoModel documento) async {
    if (documento.storagePath.isNotEmpty) {
      await _storage.ref(documento.storagePath).delete();
    }
    await _collection.doc(documento.id).delete();
  }
}
