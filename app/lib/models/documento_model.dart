import 'package:cloud_firestore/cloud_firestore.dart';

/// Categorías de documentación institucional de la Corporación (no
/// confundir con los Dossiers/Riders de las bandas postulantes).
enum CategoriaDocumento {
  estatutos,
  actas,
  contratos,
  informes,
  otros;

  static CategoriaDocumento fromString(String? value) {
    return CategoriaDocumento.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CategoriaDocumento.otros,
    );
  }

  String get label {
    switch (this) {
      case CategoriaDocumento.estatutos:
        return 'Estatutos';
      case CategoriaDocumento.actas:
        return 'Actas';
      case CategoriaDocumento.contratos:
        return 'Contratos';
      case CategoriaDocumento.informes:
        return 'Informes';
      case CategoriaDocumento.otros:
        return 'Otros';
    }
  }
}

/// Documento institucional de la Corporación de La Raíz (estatutos,
/// actas de directorio, contratos, informes, etc.), gestionado desde el
/// panel administrativo. Colección `documentos_institucionales`.
class DocumentoModel {
  final String? id;
  final String titulo;
  final CategoriaDocumento categoria;
  final String? descripcion;
  final String archivoUrl;
  final String nombreArchivo;
  final String storagePath;
  final int? tamanoBytes;
  final DateTime? fechaSubida;

  const DocumentoModel({
    this.id,
    required this.titulo,
    required this.categoria,
    this.descripcion,
    required this.archivoUrl,
    required this.nombreArchivo,
    required this.storagePath,
    this.tamanoBytes,
    this.fechaSubida,
  });

  factory DocumentoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return DocumentoModel(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      categoria: CategoriaDocumento.fromString(data['categoria'] as String?),
      descripcion: data['descripcion'] as String?,
      archivoUrl: data['archivoUrl'] as String? ?? '',
      nombreArchivo: data['nombreArchivo'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      tamanoBytes: data['tamanoBytes'] as int?,
      fechaSubida: (data['fechaSubida'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'categoria': categoria.name,
      'descripcion': descripcion,
      'archivoUrl': archivoUrl,
      'nombreArchivo': nombreArchivo,
      'storagePath': storagePath,
      'tamanoBytes': tamanoBytes,
      'fechaSubida': FieldValue.serverTimestamp(),
    };
  }
}
