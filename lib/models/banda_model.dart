import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado del ciclo de vida de una postulación dentro del proceso de
/// selección de "La Grúa del Rock".
enum EstadoPostulacion {
  pendiente,
  seleccionada,
  rechazada;

  /// Convierte el valor guardado en Firestore (String) al enum.
  /// Si el valor es desconocido o nulo, se asume `pendiente` para no
  /// romper la UI ante datos legacy o mal formados.
  static EstadoPostulacion fromString(String? value) {
    return EstadoPostulacion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoPostulacion.pendiente,
    );
  }

  String get label {
    switch (this) {
      case EstadoPostulacion.pendiente:
        return 'Pendiente';
      case EstadoPostulacion.seleccionada:
        return 'Seleccionada';
      case EstadoPostulacion.rechazada:
        return 'Rechazada';
    }
  }
}

/// Modelo de datos para una postulación de banda a "La Grúa del Rock".
///
/// Se mapea 1:1 con documentos de la colección `bandas_postulaciones`
/// en Firestore. Los archivos (dossier / rider técnico) se suben a
/// Firebase Storage y aquí solo se guarda su URL de descarga pública.
class BandaModel {
  final String? id;

  // Datos de la banda
  final String nombreGrupo;
  final String comuna;
  final String generoMusical;
  final String telefonoContacto;
  final String correoContacto;

  // Representante
  final String nombreRepresentante;
  final String rutRepresentante;

  // Enlaces externos
  final String? linkSpotify;
  final String? linkYoutube;
  final String? linkInstagram;
  final String? linkMaterialAudiovisual;

  // Archivos adjuntos (Firebase Storage)
  final String? dossierUrl;
  final String? dossierNombreArchivo;
  final String? riderTecnicoUrl;
  final String? riderTecnicoNombreArchivo;

  // Gestión interna
  final EstadoPostulacion estado;
  final DateTime? fechaPostulacion;
  final DateTime? fechaActualizacion;

  /// Proyecto (colección `proyectos`) al que pertenece esta postulación —
  /// p. ej. "La Grúa del Rock". Puede venir vacío en documentos legacy
  /// creados antes de que existiera el módulo de Proyectos.
  final String proyectoId;

  const BandaModel({
    this.id,
    required this.nombreGrupo,
    required this.comuna,
    required this.generoMusical,
    required this.telefonoContacto,
    required this.correoContacto,
    required this.nombreRepresentante,
    required this.rutRepresentante,
    this.linkSpotify,
    this.linkYoutube,
    this.linkInstagram,
    this.linkMaterialAudiovisual,
    this.dossierUrl,
    this.dossierNombreArchivo,
    this.riderTecnicoUrl,
    this.riderTecnicoNombreArchivo,
    this.estado = EstadoPostulacion.pendiente,
    this.fechaPostulacion,
    this.fechaActualizacion,
    this.proyectoId = '',
  });

  /// Construye el modelo desde un [DocumentSnapshot] de Firestore.
  factory BandaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BandaModel(
      id: doc.id,
      nombreGrupo: data['nombreGrupo'] as String? ?? '',
      comuna: data['comuna'] as String? ?? '',
      generoMusical: data['generoMusical'] as String? ?? '',
      telefonoContacto: data['telefonoContacto'] as String? ?? '',
      correoContacto: data['correoContacto'] as String? ?? '',
      nombreRepresentante: data['nombreRepresentante'] as String? ?? '',
      rutRepresentante: data['rutRepresentante'] as String? ?? '',
      linkSpotify: data['linkSpotify'] as String?,
      linkYoutube: data['linkYoutube'] as String?,
      linkInstagram: data['linkInstagram'] as String?,
      linkMaterialAudiovisual: data['linkMaterialAudiovisual'] as String?,
      dossierUrl: data['dossierUrl'] as String?,
      dossierNombreArchivo: data['dossierNombreArchivo'] as String?,
      riderTecnicoUrl: data['riderTecnicoUrl'] as String?,
      riderTecnicoNombreArchivo: data['riderTecnicoNombreArchivo'] as String?,
      estado: EstadoPostulacion.fromString(data['estado'] as String?),
      fechaPostulacion: (data['fechaPostulacion'] as Timestamp?)?.toDate(),
      fechaActualizacion: (data['fechaActualizacion'] as Timestamp?)?.toDate(),
      proyectoId: data['proyectoId'] as String? ?? '',
    );
  }

  /// Serializa el modelo a un mapa apto para `set`/`update` en Firestore.
  /// Las fechas se convierten a [FieldValue.serverTimestamp] cuando no
  /// existe un valor previo, garantizando que el reloj lo fije el servidor
  /// y no el cliente (evita inconsistencias por hora local del dispositivo).
  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    return {
      'nombreGrupo': nombreGrupo,
      'comuna': comuna,
      'generoMusical': generoMusical,
      'telefonoContacto': telefonoContacto,
      'correoContacto': correoContacto,
      'nombreRepresentante': nombreRepresentante,
      'rutRepresentante': rutRepresentante,
      'linkSpotify': linkSpotify,
      'linkYoutube': linkYoutube,
      'linkInstagram': linkInstagram,
      'linkMaterialAudiovisual': linkMaterialAudiovisual,
      'dossierUrl': dossierUrl,
      'dossierNombreArchivo': dossierNombreArchivo,
      'riderTecnicoUrl': riderTecnicoUrl,
      'riderTecnicoNombreArchivo': riderTecnicoNombreArchivo,
      'estado': estado.name,
      if (!isUpdate) 'fechaPostulacion': FieldValue.serverTimestamp(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'proyectoId': proyectoId,
    };
  }

  BandaModel copyWith({
    EstadoPostulacion? estado,
    String? dossierUrl,
    String? dossierNombreArchivo,
    String? riderTecnicoUrl,
    String? riderTecnicoNombreArchivo,
    String? proyectoId,
  }) {
    return BandaModel(
      id: id,
      nombreGrupo: nombreGrupo,
      comuna: comuna,
      generoMusical: generoMusical,
      telefonoContacto: telefonoContacto,
      correoContacto: correoContacto,
      nombreRepresentante: nombreRepresentante,
      rutRepresentante: rutRepresentante,
      linkSpotify: linkSpotify,
      linkYoutube: linkYoutube,
      linkInstagram: linkInstagram,
      linkMaterialAudiovisual: linkMaterialAudiovisual,
      dossierUrl: dossierUrl ?? this.dossierUrl,
      dossierNombreArchivo: dossierNombreArchivo ?? this.dossierNombreArchivo,
      riderTecnicoUrl: riderTecnicoUrl ?? this.riderTecnicoUrl,
      riderTecnicoNombreArchivo:
          riderTecnicoNombreArchivo ?? this.riderTecnicoNombreArchivo,
      estado: estado ?? this.estado,
      fechaPostulacion: fechaPostulacion,
      fechaActualizacion: fechaActualizacion,
      proyectoId: proyectoId ?? this.proyectoId,
    );
  }
}
