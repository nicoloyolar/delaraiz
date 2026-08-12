import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de tenencia de un espacio recuperado por la Corporación.
enum TipoTenencia {
  propio,
  comodato,
  arriendo,
  enGestion;

  static TipoTenencia fromString(String? value) {
    return TipoTenencia.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoTenencia.enGestion,
    );
  }

  String get label {
    switch (this) {
      case TipoTenencia.propio:
        return 'Propio';
      case TipoTenencia.comodato:
        return 'Comodato';
      case TipoTenencia.arriendo:
        return 'Arriendo';
      case TipoTenencia.enGestion:
        return 'En gestión';
    }
  }
}

/// Espacio físico recuperado o en proceso de recuperación por la
/// Corporación (colección `espacios`). El historial de uso no se guarda
/// aquí: se obtiene consultando `proyectos` cuyo `espacioIds` contenga
/// este espacio.
class EspacioModel {
  final String? id;
  final String nombre;
  final String direccion;
  final String comuna;
  final TipoTenencia tipoTenencia;
  final String? estadoLegal;
  final int? capacidad;
  final String? descripcion;
  final List<String> fotoUrls;
  final List<String> documentoUrls;
  final DateTime? createdAt;

  const EspacioModel({
    this.id,
    required this.nombre,
    required this.direccion,
    required this.comuna,
    this.tipoTenencia = TipoTenencia.enGestion,
    this.estadoLegal,
    this.capacidad,
    this.descripcion,
    this.fotoUrls = const [],
    this.documentoUrls = const [],
    this.createdAt,
  });

  factory EspacioModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return EspacioModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      direccion: data['direccion'] as String? ?? '',
      comuna: data['comuna'] as String? ?? '',
      tipoTenencia: TipoTenencia.fromString(data['tipoTenencia'] as String?),
      estadoLegal: data['estadoLegal'] as String?,
      capacidad: data['capacidad'] as int?,
      descripcion: data['descripcion'] as String?,
      fotoUrls: (data['fotoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      documentoUrls: (data['documentoUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    return {
      'nombre': nombre,
      'direccion': direccion,
      'comuna': comuna,
      'tipoTenencia': tipoTenencia.name,
      'estadoLegal': estadoLegal,
      'capacidad': capacidad,
      'descripcion': descripcion,
      'fotoUrls': fotoUrls,
      'documentoUrls': documentoUrls,
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  EspacioModel copyWith({List<String>? fotoUrls, List<String>? documentoUrls}) {
    return EspacioModel(
      id: id,
      nombre: nombre,
      direccion: direccion,
      comuna: comuna,
      tipoTenencia: tipoTenencia,
      estadoLegal: estadoLegal,
      capacidad: capacidad,
      descripcion: descripcion,
      fotoUrls: fotoUrls ?? this.fotoUrls,
      documentoUrls: documentoUrls ?? this.documentoUrls,
      createdAt: createdAt,
    );
  }
}
