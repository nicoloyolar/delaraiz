import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de componente/insumo que puede necesitar un proyecto — genérico a
/// propósito, porque cada proyecto (festival musical, recuperación de un
/// espacio, etc.) necesita "cosas" distintas.
enum TipoComponente {
  equipo,
  material,
  servicio,
  otro;

  static TipoComponente fromString(String? value) {
    return TipoComponente.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoComponente.otro,
    );
  }

  String get label {
    switch (this) {
      case TipoComponente.equipo:
        return 'Equipo';
      case TipoComponente.material:
        return 'Material';
      case TipoComponente.servicio:
        return 'Servicio';
      case TipoComponente.otro:
        return 'Otro';
    }
  }
}

enum EstadoComponente {
  pendiente,
  confirmado,
  entregado;

  static EstadoComponente fromString(String? value) {
    return EstadoComponente.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoComponente.pendiente,
    );
  }

  String get label {
    switch (this) {
      case EstadoComponente.pendiente:
        return 'Pendiente';
      case EstadoComponente.confirmado:
        return 'Confirmado';
      case EstadoComponente.entregado:
        return 'Entregado';
    }
  }
}

/// Ítem del listado de "cosas" que necesita un proyecto (subcolección
/// `proyectos/{proyectoId}/componentes`): equipos, materiales, servicios,
/// etc. — el checklist genérico que reemplaza las planillas sueltas.
class ComponenteModel {
  final String? id;
  final String nombre;
  final TipoComponente tipo;
  final EstadoComponente estado;
  final int cantidad;
  final String? responsableId;
  final String? notas;

  const ComponenteModel({
    this.id,
    required this.nombre,
    this.tipo = TipoComponente.otro,
    this.estado = EstadoComponente.pendiente,
    this.cantidad = 1,
    this.responsableId,
    this.notas,
  });

  factory ComponenteModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ComponenteModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      tipo: TipoComponente.fromString(data['tipo'] as String?),
      estado: EstadoComponente.fromString(data['estado'] as String?),
      cantidad: data['cantidad'] as int? ?? 1,
      responsableId: data['responsableId'] as String?,
      notas: data['notas'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'tipo': tipo.name,
      'estado': estado.name,
      'cantidad': cantidad,
      'responsableId': responsableId,
      'notas': notas,
    };
  }
}
