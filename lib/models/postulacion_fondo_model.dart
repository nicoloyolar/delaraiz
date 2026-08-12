import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado del ciclo de vida de una postulación a un fondo concursable.
enum EstadoFondo {
  enPreparacion,
  postulado,
  enEvaluacion,
  aprobado,
  rechazado,
  enEjecucion,
  rendido;

  static EstadoFondo fromString(String? value) {
    return EstadoFondo.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoFondo.enPreparacion,
    );
  }

  String get label {
    switch (this) {
      case EstadoFondo.enPreparacion:
        return 'En preparación';
      case EstadoFondo.postulado:
        return 'Postulado';
      case EstadoFondo.enEvaluacion:
        return 'En evaluación';
      case EstadoFondo.aprobado:
        return 'Aprobado';
      case EstadoFondo.rechazado:
        return 'Rechazado';
      case EstadoFondo.enEjecucion:
        return 'En ejecución';
      case EstadoFondo.rendido:
        return 'Rendido';
    }
  }
}

/// Postulación a un fondo de financiamiento concursable, vinculada a un
/// proyecto de la Corporación (colección `postulaciones_fondos`).
class PostulacionFondoModel {
  final String? id;
  final String nombreFondo;
  final String? institucion;
  final String proyectoId;
  final double montoSolicitado;
  final double? montoAprobado;
  final EstadoFondo estado;
  final DateTime? fechaPostulacion;
  final DateTime? fechaResolucion;
  final DateTime? plazoRendicion;
  final List<String> documentoUrls;
  final String? notas;

  const PostulacionFondoModel({
    this.id,
    required this.nombreFondo,
    this.institucion,
    required this.proyectoId,
    required this.montoSolicitado,
    this.montoAprobado,
    this.estado = EstadoFondo.enPreparacion,
    this.fechaPostulacion,
    this.fechaResolucion,
    this.plazoRendicion,
    this.documentoUrls = const [],
    this.notas,
  });

  factory PostulacionFondoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PostulacionFondoModel(
      id: doc.id,
      nombreFondo: data['nombreFondo'] as String? ?? '',
      institucion: data['institucion'] as String?,
      proyectoId: data['proyectoId'] as String? ?? '',
      montoSolicitado: (data['montoSolicitado'] as num?)?.toDouble() ?? 0,
      montoAprobado: (data['montoAprobado'] as num?)?.toDouble(),
      estado: EstadoFondo.fromString(data['estado'] as String?),
      fechaPostulacion: (data['fechaPostulacion'] as Timestamp?)?.toDate(),
      fechaResolucion: (data['fechaResolucion'] as Timestamp?)?.toDate(),
      plazoRendicion: (data['plazoRendicion'] as Timestamp?)?.toDate(),
      documentoUrls: (data['documentoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      notas: data['notas'] as String?,
    );
  }

  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    return {
      'nombreFondo': nombreFondo,
      'institucion': institucion,
      'proyectoId': proyectoId,
      'montoSolicitado': montoSolicitado,
      'montoAprobado': montoAprobado,
      'estado': estado.name,
      'fechaPostulacion': fechaPostulacion != null ? Timestamp.fromDate(fechaPostulacion!) : null,
      'fechaResolucion': fechaResolucion != null ? Timestamp.fromDate(fechaResolucion!) : null,
      'plazoRendicion': plazoRendicion != null ? Timestamp.fromDate(plazoRendicion!) : null,
      'documentoUrls': documentoUrls,
      'notas': notas,
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
