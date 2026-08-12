import 'package:cloud_firestore/cloud_firestore.dart';

/// Rol de acceso al sistema. Hoy solo existe `admin` (todo el equipo con
/// cuenta tiene acceso total); el enum ya queda listo para agregar roles
/// más granulares (coordinador de proyecto, voluntario) sin tener que
/// migrar el modelo de datos.
enum RolUsuario {
  admin;

  static RolUsuario fromString(String? value) {
    return RolUsuario.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RolUsuario.admin,
    );
  }

  String get label => switch (this) { RolUsuario.admin => 'Administrador' };
}

/// Perfil de acceso interno de un usuario autenticado (colección
/// `usuarios`, id del documento = uid de Firebase Auth). Se crea al dar de
/// alta manualmente una cuenta en la Consola de Firebase.
class UsuarioModel {
  final String uid;
  final String? nombre;
  final String? correo;
  final RolUsuario rol;
  final bool activo;

  const UsuarioModel({
    required this.uid,
    this.nombre,
    this.correo,
    this.rol = RolUsuario.admin,
    this.activo = true,
  });

  factory UsuarioModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UsuarioModel(
      uid: doc.id,
      nombre: data['nombre'] as String?,
      correo: data['correo'] as String?,
      rol: RolUsuario.fromString(data['rol'] as String?),
      activo: data['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol.name,
      'activo': activo,
    };
  }
}
