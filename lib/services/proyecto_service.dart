import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/actividad_model.dart';
import '../models/bitacora_entry_model.dart';
import '../models/componente_model.dart';
import '../models/proyecto_miembro_model.dart';
import '../models/proyecto_model.dart';

/// Servicio de acceso a datos para los Proyectos de la Corporación —la
/// entidad central de la plataforma— y sus subcolecciones: actividades,
/// bitácora de avances, componentes (checklist de "cosas") y equipo
/// asignado. Centraliza toda la interacción con Firestore/Storage para
/// que las pantallas nunca llamen directamente a los SDK de Firebase.
class ProyectoService {
  ProyectoService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _collectionPath = 'proyectos';
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  // --- Proyecto ---

  Stream<List<ProyectoModel>> streamProyectos() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ProyectoModel.fromFirestore).toList());
  }

  Future<ProyectoModel?> obtenerProyecto(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ProyectoModel.fromFirestore(doc);
  }

  Stream<ProyectoModel?> streamProyecto(String id) {
    return _collection.doc(id).snapshots().map(
          (doc) => doc.exists ? ProyectoModel.fromFirestore(doc) : null,
        );
  }

  /// El proyecto (si existe) con las postulaciones de bandas abiertas al
  /// público — usado por el formulario público para saber a qué proyecto
  /// asociar las postulaciones que reciba.
  Stream<ProyectoModel?> streamProyectoConPostulacionesAbiertas() {
    return _collection
        .where('aceptaPostulacionesBandas', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : ProyectoModel.fromFirestore(snapshot.docs.first));
  }

  Future<String> crearProyecto(ProyectoModel proyecto) async {
    final docRef = await _collection.add(proyecto.toFirestore());
    return docRef.id;
  }

  Future<void> actualizarProyecto(ProyectoModel proyecto) async {
    await _collection.doc(proyecto.id).update(proyecto.toFirestore(isUpdate: true));
  }

  Future<void> eliminarProyecto(String id) async {
    await _collection.doc(id).delete();
  }

  /// Activa las postulaciones públicas de bandas para [proyectoId] y
  /// desactiva cualquier otro proyecto que las tuviera activas, para
  /// garantizar que solo haya un formulario público abierto a la vez.
  Future<void> establecerProyectoConPostulacionesAbiertas(String proyectoId) async {
    final abiertos = await _collection.where('aceptaPostulacionesBandas', isEqualTo: true).get();
    final batch = _firestore.batch();
    for (final doc in abiertos.docs) {
      if (doc.id != proyectoId) {
        batch.update(doc.reference, {'aceptaPostulacionesBandas': false});
      }
    }
    batch.update(_collection.doc(proyectoId), {'aceptaPostulacionesBandas': true});
    await batch.commit();
  }

  Future<void> cerrarPostulacionesBandas(String proyectoId) async {
    await _collection.doc(proyectoId).update({'aceptaPostulacionesBandas': false});
  }

  // --- Actividades ---

  CollectionReference<Map<String, dynamic>> _actividadesCollection(String proyectoId) =>
      _collection.doc(proyectoId).collection('actividades');

  Stream<List<ActividadModel>> streamActividades(String proyectoId) {
    return _actividadesCollection(proyectoId)
        .orderBy('fechaProgramada')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ActividadModel.fromFirestore).toList());
  }

  Future<void> crearActividad(String proyectoId, ActividadModel actividad) {
    return _actividadesCollection(proyectoId).add(actividad.toFirestore());
  }

  Future<void> actualizarActividad(String proyectoId, ActividadModel actividad) {
    return _actividadesCollection(proyectoId)
        .doc(actividad.id)
        .update(actividad.toFirestore(isUpdate: true));
  }

  Future<void> eliminarActividad(String proyectoId, String actividadId) {
    return _actividadesCollection(proyectoId).doc(actividadId).delete();
  }

  // --- Bitácora ---

  CollectionReference<Map<String, dynamic>> _bitacoraCollection(String proyectoId) =>
      _collection.doc(proyectoId).collection('bitacora');

  Stream<List<BitacoraEntryModel>> streamBitacora(String proyectoId) {
    return _bitacoraCollection(proyectoId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BitacoraEntryModel.fromFirestore).toList());
  }

  Future<List<String>> _subirFotos({
    required List<Uint8List> fotosBytes,
    required String proyectoId,
  }) async {
    final urls = <String>[];
    for (final bytes in fotosBytes) {
      final ref = _storage.ref('proyectos/$proyectoId/bitacora/${_uuid.v4()}.jpg');
      final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> crearEntradaBitacora({
    required String proyectoId,
    required String texto,
    String? autorNombre,
    List<Uint8List> fotosBytes = const [],
  }) async {
    final fotoUrls = fotosBytes.isEmpty
        ? <String>[]
        : await _subirFotos(fotosBytes: fotosBytes, proyectoId: proyectoId);

    final entrada = BitacoraEntryModel(texto: texto, autorNombre: autorNombre, fotoUrls: fotoUrls);
    await _bitacoraCollection(proyectoId).add(entrada.toFirestore());
  }

  Future<void> eliminarEntradaBitacora(String proyectoId, String entradaId) {
    return _bitacoraCollection(proyectoId).doc(entradaId).delete();
  }

  // --- Componentes ---

  CollectionReference<Map<String, dynamic>> _componentesCollection(String proyectoId) =>
      _collection.doc(proyectoId).collection('componentes');

  Stream<List<ComponenteModel>> streamComponentes(String proyectoId) {
    return _componentesCollection(proyectoId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ComponenteModel.fromFirestore).toList());
  }

  Future<void> crearComponente(String proyectoId, ComponenteModel componente) {
    return _componentesCollection(proyectoId).add(componente.toFirestore());
  }

  Future<void> actualizarComponente(String proyectoId, ComponenteModel componente) {
    return _componentesCollection(proyectoId).doc(componente.id).update(componente.toFirestore());
  }

  Future<void> eliminarComponente(String proyectoId, String componenteId) {
    return _componentesCollection(proyectoId).doc(componenteId).delete();
  }

  // --- Equipo del proyecto ---

  CollectionReference<Map<String, dynamic>> _equipoCollection(String proyectoId) =>
      _collection.doc(proyectoId).collection('equipo');

  Stream<List<ProyectoMiembroModel>> streamEquipoProyecto(String proyectoId) {
    return _equipoCollection(proyectoId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ProyectoMiembroModel.fromFirestore).toList());
  }

  Future<void> agregarMiembro(String proyectoId, ProyectoMiembroModel miembro) {
    return _equipoCollection(proyectoId).add(miembro.toFirestore());
  }

  Future<void> quitarMiembro(String proyectoId, String miembroId) {
    return _equipoCollection(proyectoId).doc(miembroId).delete();
  }
}
