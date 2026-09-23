import 'package:cloud_firestore/cloud_firestore.dart';

/// Un local/comercio adherido al beneficio de acceso de Embajador (ej. un
/// bar o venue que da entrada libre a socios Embajador) — agregado
/// 2026-09-23 como parte del sistema de cupón QR (diseño confirmado con la
/// directiva, ver PROYECTO.md sección 9.15). Arranca vacío a propósito: la
/// lista real de locales todavía no está consolidada, se va cargando acá
/// desde el panel admin a medida que se confirmen alianzas reales.
class LocalModel {
  final String id;
  final String nombre;
  final String beneficio;
  final bool activo;

  const LocalModel({
    required this.id,
    required this.nombre,
    required this.beneficio,
    required this.activo,
  });

  factory LocalModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return LocalModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      beneficio: data['beneficio'] as String? ?? '',
      activo: data['activo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'beneficio': beneficio,
        'activo': activo,
      };
}
