import 'package:flutter/material.dart';

/// Paleta de marca de la Corporación de La Raíz, unificada 2026-08-12 con la
/// paleta real del sitio institucional
/// (web/wp-content/themes/astra-child/assets/css/header.css) — antes esta
/// paleta era propia de la app (tipo dashboard, #0B0B0F/#FF6A3D),
/// desconectada de la marca real. Ver design-system/tokens.json (fuente de
/// verdad) y design-system/brand.css (espejo para el sitio PHP).
///
/// Los colores semánticos de estado (pendiente/seleccionada/rechazada) NO se
/// tocaron a propósito: son indicadores de UI, no identidad de marca.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0D0D0D); // --cdlr-ink del sitio
  static const Color surface = Color(0xFF1A1A1A); // mismo gris que usa .cdlr-plan--featured
  static const Color surfaceElevated = Color(0xFF232323);
  static const Color border = Color(0xFF2A2A2A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0); // --cdlr-body-dark
  static const Color textMuted = Color(0xFF4C5A60); // --cdlr-muted

  // Acento de marca: el naranjo real de la Corporación (--cdlr-accent).
  static const Color accent = Color(0xFFFF4500);
  static const Color accentHover = Color(0xFFDF3513); // --cdlr-accent-2
  static const Color accentInk = Color(0xFFB23A06); // --cdlr-accent-ink
  static const Color accentSoft = Color(0x26FF4500); // 15% opacity

  // Colores semánticos de estado de postulación.
  static const Color pendiente = Color(0xFFFFC107);
  static const Color pendienteSoft = Color(0x26FFC107);
  static const Color seleccionada = Color(0xFF2ED573);
  static const Color seleccionadaSoft = Color(0x262ED573);
  static const Color rechazada = Color(0xFFFF4757);
  static const Color rechazadaSoft = Color(0x26FF4757);

  static Color estadoColor(String estadoName) {
    switch (estadoName) {
      case 'seleccionada':
        return seleccionada;
      case 'rechazada':
        return rechazada;
      default:
        return pendiente;
    }
  }

  static Color estadoColorSoft(String estadoName) {
    switch (estadoName) {
      case 'seleccionada':
        return seleccionadaSoft;
      case 'rechazada':
        return rechazadaSoft;
      default:
        return pendienteSoft;
    }
  }
}
