import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoActividad {
  pendiente,
  enCurso,
  completada;

  static EstadoActividad fromString(String? value) {
    return EstadoActividad.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoActividad.pendiente,
    );
  }

  String get label {
    switch (this) {
      case EstadoActividad.pendiente:
        return 'Pendiente';
      case EstadoActividad.enCurso:
        return 'En curso';
      case EstadoActividad.completada:
        return 'Completada';
    }
  }
}

/// Actividad puntual dentro de un proyecto (subcolección
/// `proyectos/{proyectoId}/actividades`).
class ActividadModel {
  final String? id;
  final String titulo;
  final String? descripcion;
  final DateTime? fechaProgramada;
  final EstadoActividad estado;
  final String? responsableId;
  final DateTime? createdAt;

  const ActividadModel({
    this.id,
    required this.titulo,
    this.descripcion,
    this.fechaProgramada,
    this.estado = EstadoActividad.pendiente,
    this.responsableId,
    this.createdAt,
  });

  factory ActividadModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ActividadModel(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      descripcion: data['descripcion'] as String?,
      fechaProgramada: (data['fechaProgramada'] as Timestamp?)?.toDate(),
      estado: EstadoActividad.fromString(data['estado'] as String?),
      responsableId: data['responsableId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'fechaProgramada': fechaProgramada != null ? Timestamp.fromDate(fechaProgramada!) : null,
      'estado': estado.name,
      'responsableId': responsableId,
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
