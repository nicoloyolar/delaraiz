import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/banda_model.dart';

/// Servicio de acceso a datos para las postulaciones de bandas.
///
/// Centraliza toda la interacción con Firestore (colección
/// `bandas_postulaciones`) y Firebase Storage (carpeta `dossiers/`),
/// para que las pantallas nunca llamen directamente a los SDK de Firebase.
class BandaService {
  BandaService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _collectionPath = 'bandas_postulaciones';
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  /// Sube un archivo (PDF de dossier o rider técnico) a Firebase Storage
  /// y retorna su URL de descarga pública.
  ///
  /// Se reciben los bytes en memoria (en vez de un `File` de `dart:io`)
  /// porque en Flutter Web no existe sistema de archivos: `file_picker`
  /// entrega el contenido ya cargado en memoria, y este enfoque funciona
  /// igual en móvil.
  Future<String> _subirArchivo({
    required Uint8List bytes,
    required String nombreArchivoOriginal,
    required String bandaId,
    required String carpeta,
  }) async {
    final extension = nombreArchivoOriginal.split('.').last;
    final nombreUnico = '${_uuid.v4()}.$extension';
    final ref = _storage.ref('dossiers/$bandaId/$carpeta/$nombreUnico');

    final metadata = SettableMetadata(
      contentType: extension.toLowerCase() == 'pdf'
          ? 'application/pdf'
          : 'application/octet-stream',
    );

    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  /// Crea una nueva postulación completa: sube los archivos adjuntos (si
  /// vienen) y luego escribe el documento en Firestore.
  ///
  /// Se genera el ID del documento *antes* de subir los archivos para
  /// poder organizarlos en Storage bajo una carpeta `dossiers/{bandaId}/`,
  /// de modo que quede trazable a qué postulación pertenece cada archivo.
  Future<String> crearPostulacion({
    required BandaModel banda,
    required String proyectoId,
    Uint8List? dossierBytes,
    String? dossierNombreArchivo,
    Uint8List? riderTecnicoBytes,
    String? riderTecnicoNombreArchivo,
  }) async {
    final docRef = _collection.doc();

    String? dossierUrl;
    if (dossierBytes != null && dossierNombreArchivo != null) {
      dossierUrl = await _subirArchivo(
        bytes: dossierBytes,
        nombreArchivoOriginal: dossierNombreArchivo,
        bandaId: docRef.id,
        carpeta: 'dossier',
      );
    }

    String? riderUrl;
    if (riderTecnicoBytes != null && riderTecnicoNombreArchivo != null) {
      riderUrl = await _subirArchivo(
        bytes: riderTecnicoBytes,
        nombreArchivoOriginal: riderTecnicoNombreArchivo,
        bandaId: docRef.id,
        carpeta: 'rider',
      );
    }

    final bandaConArchivos = banda.copyWith(
      dossierUrl: dossierUrl,
      dossierNombreArchivo: dossierNombreArchivo,
      riderTecnicoUrl: riderUrl,
      riderTecnicoNombreArchivo: riderTecnicoNombreArchivo,
      proyectoId: proyectoId,
    );

    await docRef.set(bandaConArchivos.toFirestore());
    return docRef.id;
  }

  /// Stream en tiempo real de postulaciones. Si se pasa [proyectoId], solo
  /// trae las postulaciones de ese proyecto (uso normal: tab "Bandas"
  /// dentro del detalle de un proyecto) — sin él, trae todas (uso: KPIs
  /// globales del Resumen).
  ///
  /// El filtro por texto (nombre de grupo / comuna) se aplica en cliente
  /// porque Firestore no soporta búsquedas "contains" nativas sin un
  /// servicio externo (p. ej. Algolia); para el volumen esperado de
  /// postulaciones de una corporación cultural local, esto es suficiente.
  Stream<List<BandaModel>> streamPostulaciones({
    String? proyectoId,
    EstadoPostulacion? filtroEstado,
    String textoBusqueda = '',
  }) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('fechaPostulacion', descending: true);

    if (proyectoId != null) {
      query = query.where('proyectoId', isEqualTo: proyectoId);
    }

    if (filtroEstado != null) {
      query = query.where('estado', isEqualTo: filtroEstado.name);
    }

    return query.snapshots().map((snapshot) {
      final bandas = snapshot.docs.map(BandaModel.fromFirestore).toList();

      if (textoBusqueda.trim().isEmpty) return bandas;

      final termino = textoBusqueda.trim().toLowerCase();
      return bandas.where((b) {
        return b.nombreGrupo.toLowerCase().contains(termino) ||
            b.comuna.toLowerCase().contains(termino) ||
            b.generoMusical.toLowerCase().contains(termino);
      }).toList();
    });
  }

  /// Obtiene una postulación puntual (usado en la vista de detalle si se
  /// navega directo por URL/ID en vez de por el stream del listado).
  Future<BandaModel?> obtenerPostulacion(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return BandaModel.fromFirestore(doc);
  }

  /// Actualiza únicamente el estado de una postulación (Pendiente /
  /// Seleccionada / Rechazada) desde el dashboard admin.
  Future<void> actualizarEstado({
    required String id,
    required EstadoPostulacion nuevoEstado,
  }) async {
    await _collection.doc(id).update({
      'estado': nuevoEstado.name,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });
  }
}
