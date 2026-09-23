import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado real del cupón de acceso — `vigente` es un estado "de base de
/// datos" que puede estar desactualizado (el cupón vence 12h después de
/// `generadoEn` sin que nada lo marque activamente como `expirado`) — ver
/// [CuponAccesoModel.estaVigente], que es la verdad real a usar en la UI.
enum EstadoCuponAcceso {
  vigente,
  usado;

  static EstadoCuponAcceso fromString(String? value) {
    return EstadoCuponAcceso.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoCuponAcceso.usado,
    );
  }
}

/// Cupón de acceso de un solo uso para el beneficio de Embajador ("acceso a
/// locales adheridos") — agregado 2026-09-23, diseño confirmado con la
/// directiva (PROYECTO.md sección 9.15/9.25).
///
/// Se genera desde `/credencial` (el propio socio, solo si es Embajador),
/// dura 12h, y se consume "a ciegas" desde la pantalla pública de validación
/// (`/validar/:localSlug`) que corre en el celular de quien reciba al socio
/// en el local — esa validación pasa por el sitio PHP (cuenta de servicio),
/// nunca escribe directo a Firestore desde el navegador del validador (ver
/// `firestore.rules`: solo el propio socio puede leer/crear su cupón).
class CuponAccesoModel {
  final String codigo;
  final String socioEmail;
  final String socioNombre;
  final String localId;
  final String localNombre;
  final DateTime generadoEn;
  final DateTime expiraEn;
  final EstadoCuponAcceso estado;

  const CuponAccesoModel({
    required this.codigo,
    required this.socioEmail,
    required this.socioNombre,
    required this.localId,
    required this.localNombre,
    required this.generadoEn,
    required this.expiraEn,
    required this.estado,
  });

  /// La verdad real de si este cupón todavía sirve — `estado == vigente` en
  /// la base no basta, porque nada marca activamente un cupón como
  /// "expirado" cuando pasan las 12h (sería un cron/función aparte, no
  /// justificado para algo que ya se puede calcular al vuelo).
  bool get estaVigente =>
      estado == EstadoCuponAcceso.vigente && expiraEn.isAfter(DateTime.now());

  factory CuponAccesoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CuponAccesoModel(
      codigo: doc.id,
      socioEmail: data['socioEmail'] as String? ?? '',
      socioNombre: data['socioNombre'] as String? ?? '',
      localId: data['localId'] as String? ?? '',
      localNombre: data['localNombre'] as String? ?? '',
      generadoEn: (data['generadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiraEn: (data['expiraEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estado: EstadoCuponAcceso.fromString(data['estado'] as String?),
    );
  }
}
