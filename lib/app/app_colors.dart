import 'package:flutter/material.dart';

/// Paleta de marca de la Corporación de La Raíz para el panel
/// administrativo: tema oscuro tipo dashboard, con un acento cálido que
/// evoca las luces de escenario de "La Grúa del Rock".
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF16161D);
  static const Color surfaceElevated = Color(0xFF1C1C25);
  static const Color border = Color(0xFF2A2A35);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF9A9AA8);
  static const Color textMuted = Color(0xFF6B6B78);

  // Acento de marca: naranja-rojo encendido (luces de escenario).
  static const Color accent = Color(0xFFFF6A3D);
  static const Color accentSoft = Color(0x26FF6A3D); // 15% opacity

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
