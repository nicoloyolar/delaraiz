import 'package:cloud_firestore/cloud_firestore.dart';

/// Asignación de una persona del directorio institucional a un proyecto
/// (subcolección `proyectos/{proyectoId}/equipo`), con el rol que cumple
/// específicamente en ese proyecto (puede ser distinto de su rol general
/// en la Corporación).
class ProyectoMiembroModel {
  final String? id;
  final String personaId;
  final String rolEnProyecto;

  const ProyectoMiembroModel({
    this.id,
    required this.personaId,
    required this.rolEnProyecto,
  });

  factory ProyectoMiembroModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProyectoMiembroModel(
      id: doc.id,
      personaId: data['personaId'] as String? ?? '',
      rolEnProyecto: data['rolEnProyecto'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personaId': personaId,
      'rolEnProyecto': rolEnProyecto,
    };
  }
}
