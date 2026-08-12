import 'package:flutter/material.dart';

import '../models/componente_model.dart';
import '../models/postulacion_fondo_model.dart';
import '../models/proyecto_model.dart';
import 'app_colors.dart';

/// Mapeo de color por estado para las entidades nuevas (Proyecto,
/// Componente, Fondo) — centralizado aquí para no duplicar switches de
/// color en cada pantalla/widget que muestra un [Pill].
class EstadoColors {
  EstadoColors._();

  static Color proyecto(EstadoProyecto estado) {
    switch (estado) {
      case EstadoProyecto.planificacion:
        return AppColors.pendiente;
      case EstadoProyecto.enCurso:
        return AppColors.seleccionada;
      case EstadoProyecto.pausado:
        return AppColors.textMuted;
      case EstadoProyecto.finalizado:
        return AppColors.accent;
    }
  }

  static Color componente(EstadoComponente estado) {
    switch (estado) {
      case EstadoComponente.pendiente:
        return AppColors.pendiente;
      case EstadoComponente.confirmado:
        return AppColors.accent;
      case EstadoComponente.entregado:
        return AppColors.seleccionada;
    }
  }

  static Color fondo(EstadoFondo estado) {
    switch (estado) {
      case EstadoFondo.enPreparacion:
        return AppColors.textMuted;
      case EstadoFondo.postulado:
        return AppColors.pendiente;
      case EstadoFondo.enEvaluacion:
        return AppColors.accent;
      case EstadoFondo.aprobado:
        return AppColors.seleccionada;
      case EstadoFondo.rechazado:
        return AppColors.rechazada;
      case EstadoFondo.enEjecucion:
        return AppColors.accent;
      case EstadoFondo.rendido:
        return AppColors.seleccionada;
    }
  }
}
