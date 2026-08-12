import 'package:cloud_firestore/cloud_firestore.dart';

/// Entrada de bitácora/avance dentro de un proyecto (subcolección
/// `proyectos/{proyectoId}/bitacora`): un registro de texto con fecha y
/// fotos opcionales, usado para dejar trazabilidad del avance real del
/// proyecto en el tiempo.
class BitacoraEntryModel {
  final String? id;
  final String texto;
  final String? autorNombre;
  final List<String> fotoUrls;
  final DateTime? fecha;

  const BitacoraEntryModel({
    this.id,
    required this.texto,
    this.autorNombre,
    this.fotoUrls = const [],
    this.fecha,
  });

  factory BitacoraEntryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BitacoraEntryModel(
      id: doc.id,
      texto: data['texto'] as String? ?? '',
      autorNombre: data['autorNombre'] as String?,
      fotoUrls: (data['fotoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      fecha: (data['fecha'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    return {
      'texto': texto,
      'autorNombre': autorNombre,
      'fotoUrls': fotoUrls,
      if (!isUpdate) 'fecha': FieldValue.serverTimestamp(),
    };
  }
}
