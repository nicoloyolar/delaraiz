import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado de confirmación de un evento — agregado 2026-08-18. Mismo
/// problema real que ya se vio en el sitio público (backlog #5: "no dejar
/// una promesa sin contenido real" con la 2ª temporada de La Grúa del Rock)
/// pero ahora resuelto desde el origen: una fecha "tentativa" queda
/// marcada como tal en vez de mezclarse con las confirmadas.
enum EstadoEvento {
  confirmado,
  tentativo,
  cancelado;

  static EstadoEvento fromString(String? value) {
    return EstadoEvento.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoEvento.tentativo,
    );
  }

  String get label {
    switch (this) {
      case EstadoEvento.confirmado:
        return 'Confirmado';
      case EstadoEvento.tentativo:
        return 'Tentativo';
      case EstadoEvento.cancelado:
        return 'Cancelado';
    }
  }
}

/// Un evento puntual de la agenda (una fecha de La Grúa del Rock, un día del
/// Festival de las 7 Lagunas, etc.) — colección `eventos`, de nivel superior
/// (no subcolección de `proyectos`, mismo criterio que
/// `postulaciones_fondos`): la agenda existe primero que nada para verse
/// cruzada entre todos los proyectos, así que una consulta global simple
/// (con filtro opcional por `proyectoId`) es más natural que tener que
/// consultar cada subcolección de cada proyecto por separado.
///
/// El proyecto es OPCIONAL (`proyectoId` nullable) — a pedido del usuario,
/// la Agenda es una agenda global de la Corporación, no algo que dependa de
/// que exista un Proyecto formal cargado en el sistema. Un evento puede
/// quedar suelto (ej. una actividad puntual que no calza con ninguna línea
/// de proyecto) o ligado a uno si corresponde.
///
/// No hay que confundirlo con `ActividadModel` (subcolección
/// `proyectos/{id}/actividades`) — esa es una tarea interna de gestión del
/// equipo (pendiente/en curso/completada, con un responsable, y SIEMPRE
/// dentro de un proyecto), mientras que un Evento es la fecha real de cara
/// al público (con lugar, line-up, cupo), exista o no un proyecto detrás.
class EventoModel {
  final String? id;
  final String titulo;
  final String? proyectoId;
  final DateTime fecha;
  final String? lugar;
  final EstadoEvento estado;
  final List<String> bandasArtistas;
  final int? cupo;
  final String? notas;
  final DateTime? createdAt;

  const EventoModel({
    this.id,
    required this.titulo,
    this.proyectoId,
    required this.fecha,
    this.lugar,
    this.estado = EstadoEvento.tentativo,
    this.bandasArtistas = const [],
    this.cupo,
    this.notas,
    this.createdAt,
  });

  factory EventoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return EventoModel(
      id: doc.id,
      titulo: data['titulo'] as String? ?? '',
      proyectoId: data['proyectoId'] as String?,
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lugar: data['lugar'] as String?,
      estado: EstadoEvento.fromString(data['estado'] as String?),
      bandasArtistas: (data['bandasArtistas'] as List<dynamic>?)?.cast<String>() ?? const [],
      cupo: (data['cupo'] as num?)?.toInt(),
      notas: data['notas'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isUpdate = false}) {
    return {
      'titulo': titulo,
      'proyectoId': proyectoId,
      'fecha': Timestamp.fromDate(fecha),
      'lugar': lugar,
      'estado': estado.name,
      'bandasArtistas': bandasArtistas,
      'cupo': cupo,
      'notas': notas,
      if (!isUpdate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
