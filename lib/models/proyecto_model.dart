import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado general del ciclo de vida de un proyecto de la Corporación.
enum EstadoProyecto {
  planificacion,
  enCurso,
  pausado,
  finalizado;

  static EstadoProyecto fromString(String? value) {
    return EstadoProyecto.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoProyecto.planificacion,
    );
  }

  String get label {
    switch (this) {
      case EstadoProyecto.planificacion:
        return 'En planificación';
      case EstadoProyecto.enCurso:
        return 'En curso';
      case EstadoProyecto.pausado:
        return 'Pausado';
      case EstadoProyecto.finalizado:
        return 'Finalizado';
    }
  }
}

/// Modelo de un proyecto de la Corporación de La Raíz (p. ej. "La Grúa del
/// Rock", "Festival de Lagunas"): la entidad central de la plataforma, de
/// la que cuelgan actividades, bitácora, componentes, equipo y —cuando
/// corresponde— postulaciones de bandas y financiamiento.
///
/// Se mapea 1:1 con documentos de la colección `proyectos`.
class ProyectoModel {
  final String? id;

  final String nombre;
  final String tipo;
  final String? descripcion;
  final EstadoProyecto estado;
  final DateTime? fechaInicio;
  final DateTime? fechaTermino;
  final List<String> espacioIds;
  final String? responsableId;

  /// Si es `true`, el formulario público de postulación de bandas (`/`)
  /// acepta postulaciones para este proyecto. Solo debería haber un
  /// proyecto con este valor en `true` a la vez.
  final bool aceptaPostulacionesBandas;

  final double? presupuestoEstimado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProyectoModel({
    this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.estado = EstadoProyecto.planificacion,
    this.fechaInicio,
    this.fechaTermino,
    this.espacioIds = const [],
    this.responsableId,
    this.aceptaPostulacionesBandas = false,
    this.presupuestoEstimado,
    this.createdAt,
    this.updatedAt,
  });

  factory ProyectoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProyectoModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      tipo: data['tipo'] as String? ?? '',
      descripcion: data['descripcion'] as String?,
      estado: EstadoProyecto.fromString(data['estado'] as String?),
      fechaInicio: (data['fechaInicio'] as Timestamp?)?.toDate(),
      fechaTermino: (data['fechaTermino'] as Timestamp?)?.toDate(),
      espacioIds: (data['espacioIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      responsableId: data['responsableId'] as String?,
      aceptaPostulacionesBandas: data['aceptaPostulacionesBandas'] as bool? ?? false,
      presupuestoEstimado: (data['presupuestoEstimado'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    return {
      'nombre': nombre,
      'tipo': tipo,
      'descripcion': descripcion,
      'estado': estado.name,
      'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio!) : null,
      'fechaTermino': fechaTermino != null ? Timestamp.fromDate(fechaTermino!) : null,
      'espacioIds': espacioIds,
      'responsableId': responsableId,
      'aceptaPostulacionesBandas': aceptaPostulacionesBandas,
      'presupuestoEstimado': presupuestoEstimado,
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ProyectoModel copyWith({
    String? nombre,
    String? tipo,
    String? descripcion,
    EstadoProyecto? estado,
    DateTime? fechaInicio,
    DateTime? fechaTermino,
    List<String>? espacioIds,
    String? responsableId,
    bool? aceptaPostulacionesBandas,
    double? presupuestoEstimado,
  }) {
    return ProyectoModel(
      id: id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaTermino: fechaTermino ?? this.fechaTermino,
      espacioIds: espacioIds ?? this.espacioIds,
      responsableId: responsableId ?? this.responsableId,
      aceptaPostulacionesBandas: aceptaPostulacionesBandas ?? this.aceptaPostulacionesBandas,
      presupuestoEstimado: presupuestoEstimado ?? this.presupuestoEstimado,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
