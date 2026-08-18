import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado de la membresía de un socio, reflejado desde el sitio PHP
/// (Flow.cl) hacia Firestore — ver `cdlr_flow_sync_credencial_firestore()`
/// en `web/wp-content/themes/astra-child/inc/flow.php`. El sitio PHP sigue
/// siendo la fuente de verdad real (ahí llega el webhook de Flow); este
/// enum solo interpreta el valor ya sincronizado para mostrarlo en la app.
enum EstadoCredencial {
  activo,
  pendiente,
  moroso,
  cancelado,
  rechazado;

  static EstadoCredencial fromString(String? value) {
    return EstadoCredencial.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoCredencial.pendiente,
    );
  }

  String get label {
    switch (this) {
      case EstadoCredencial.activo:
        return 'Activo';
      case EstadoCredencial.pendiente:
        return 'Pendiente de confirmación';
      case EstadoCredencial.moroso:
        return 'Cobro pendiente';
      case EstadoCredencial.cancelado:
        return 'Cancelado';
      case EstadoCredencial.rechazado:
        return 'No completado';
    }
  }
}

/// Estado de moderación manual de un socio — capa aparte del [EstadoCredencial]
/// real (que viene automático desde Flow vía el sitio PHP). Agregado
/// 2026-08-14 para el mantenedor de Socios del panel admin: casos
/// excepcionales que el cobro automático no cubre (un aporte hecho por
/// fuera de Flow, bloquear a alguien por decisión de la directiva, etc.).
///
/// Nunca lo escribe el sitio PHP — solo el panel admin de esta app (ver
/// `SociosAdminService` y `firestore.rules`, que restringe la escritura del
/// cliente a únicamente estos 2 campos). Por eso conviven sin pisarse: la
/// sincronización de Flow hace `PATCH` solo de los campos que ella controla
/// (`estado`, `plan`, `proximoCobro`...), nunca toca `estadoModeracion`.
enum EstadoModeracion {
  sinRevisar,
  aprobado,
  rechazado,
  bloqueado;

  static EstadoModeracion fromString(String? value) {
    return EstadoModeracion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoModeracion.sinRevisar,
    );
  }

  String get label {
    switch (this) {
      case EstadoModeracion.sinRevisar:
        return 'Sin revisar';
      case EstadoModeracion.aprobado:
        return 'Aprobado';
      case EstadoModeracion.rechazado:
        return 'Rechazado';
      case EstadoModeracion.bloqueado:
        return 'Bloqueado';
    }
  }
}

/// Nivel de membresía — mismos 3 planes de `/membresia/` en el sitio PHP.
enum NivelMembresia {
  amigo,
  colaborador,
  embajador;

  static NivelMembresia fromString(String? value) {
    return NivelMembresia.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NivelMembresia.amigo,
    );
  }

  String get label {
    switch (this) {
      case NivelMembresia.amigo:
        return 'Amigo';
      case NivelMembresia.colaborador:
        return 'Colaborador';
      case NivelMembresia.embajador:
        return 'Embajador';
    }
  }

  /// Aporte mensual en CLP — copiado literal de `/membresia/` en el sitio
  /// PHP (`page-membresia.php`), solo para mostrarlo en el panel admin. Si
  /// cambian los precios ahí, hay que actualizarlos acá también (no hay
  /// una única fuente de verdad compartida todavía entre PHP y Flutter para
  /// este dato puntual).
  int get precioMensual {
    switch (this) {
      case NivelMembresia.amigo:
        return 5000;
      case NivelMembresia.colaborador:
        return 10000;
      case NivelMembresia.embajador:
        return 15000;
    }
  }

  /// Beneficios acumulados del nivel — cada nivel incluye todo lo del
  /// anterior, más los suyos propios (mismo criterio que la página
  /// `/membresia/` del sitio: "Todo lo de Amigo, más..."). Texto copiado
  /// literal de ahí para no desalinear los dos lugares sin querer.
  List<String> get beneficios {
    const amigo = [
      'Credencial digital de miembro',
      'Newsletter exclusivo',
      'Sorteos exclusivos (4 al año)',
      'Reconocimiento digital y en créditos de producciones',
      'Acceso limitado al encuentro anual de miembros',
      '50% de descuento en charlas y seminarios exclusivos (5 al año)',
      '50% de descuento en Sesiones De La Raíz (5 al año)',
    ];
    const colaboradorExtra = [
      'Acceso completo al encuentro anual de miembros',
      'Charlas y seminarios exclusivos sin costo (5 al año)',
      'Acceso gratuito a Sesiones De La Raíz (5 al año)',
      'Derecho a voto para elegir las bandas de La Grúa del Rock',
    ];
    const embajadorExtra = [
      'Acceso a Sesiones De La Raíz + 1 acompañante',
      'Beneficios en locales adheridos',
      'Actividad musical exclusiva para Embajadores',
      'Regalo de aniversario (al cumplir 12 meses y luego cada 12 meses)',
    ];

    switch (this) {
      case NivelMembresia.amigo:
        return amigo;
      case NivelMembresia.colaborador:
        return [...amigo, ...colaboradorExtra];
      case NivelMembresia.embajador:
        return [...amigo, ...colaboradorExtra, ...embajadorExtra];
    }
  }
}

/// Credencial digital de un socio — se mapea 1:1 con un documento de la
/// colección `credenciales` en Firestore, cuyo ID es el correo del socio en
/// minúsculas (mismo correo que usó al postular en `/membresia/`).
///
/// Esta colección NUNCA se escribe desde la app (ver `firestore.rules`,
/// `allow write: if false`) — solo el sitio PHP la actualiza, mediante una
/// cuenta de servicio de Firebase, cada vez que cambia el estado real de la
/// suscripción en Flow.
class CredencialModel {
  final String email;
  final String nombre;
  final NivelMembresia plan;
  final EstadoCredencial estado;
  final EstadoModeracion estadoModeracion;
  final DateTime? proximoCobro;
  final DateTime? actualizadoEn;

  const CredencialModel({
    required this.email,
    required this.nombre,
    required this.plan,
    required this.estado,
    this.estadoModeracion = EstadoModeracion.sinRevisar,
    this.proximoCobro,
    this.actualizadoEn,
  });

  factory CredencialModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CredencialModel(
      email: data['email'] as String? ?? doc.id,
      nombre: data['nombre'] as String? ?? '',
      plan: NivelMembresia.fromString(data['plan'] as String?),
      estado: EstadoCredencial.fromString(data['estado'] as String?),
      estadoModeracion: EstadoModeracion.fromString(data['estadoModeracion'] as String?),
      proximoCobro: (data['proximoCobro'] as Timestamp?)?.toDate(),
      actualizadoEn: (data['actualizadoEn'] as Timestamp?)?.toDate(),
    );
  }
}
