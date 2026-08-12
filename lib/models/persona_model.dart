import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoPersona {
  equipo,
  voluntario;

  static TipoPersona fromString(String? value) {
    return TipoPersona.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoPersona.voluntario,
    );
  }

  String get label {
    switch (this) {
      case TipoPersona.equipo:
        return 'Equipo';
      case TipoPersona.voluntario:
        return 'Voluntario';
    }
  }
}

/// Persona del directorio institucional de la Corporación (colección
/// `personas`): equipo interno o voluntariado. `usuarioUid` queda vacío
/// hasta que esa persona reciba una cuenta de acceso al sistema (fase de
/// roles futura); hoy el acceso al panel es un único usuario admin.
class PersonaModel {
  final String? id;
  final String nombre;
  final String? correo;
  final String? telefono;
  final TipoPersona tipo;
  final String? rolInstitucional;
  final bool activo;
  final String? notas;
  final String? usuarioUid;

  const PersonaModel({
    this.id,
    required this.nombre,
    this.correo,
    this.telefono,
    this.tipo = TipoPersona.voluntario,
    this.rolInstitucional,
    this.activo = true,
    this.notas,
    this.usuarioUid,
  });

  factory PersonaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PersonaModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      correo: data['correo'] as String?,
      telefono: data['telefono'] as String?,
      tipo: TipoPersona.fromString(data['tipo'] as String?),
      rolInstitucional: data['rolInstitucional'] as String?,
      activo: data['activo'] as bool? ?? true,
      notas: data['notas'] as String?,
      usuarioUid: data['usuarioUid'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'tipo': tipo.name,
      'rolInstitucional': rolInstitucional,
      'activo': activo,
      'notas': notas,
      'usuarioUid': usuarioUid,
    };
  }
}
