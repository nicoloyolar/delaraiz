import 'package:flutter/material.dart';

/// Paleta de "superficie" (fondo/tarjetas/bordes/texto) sensible al modo
/// claro/oscuro — agregada 2026-08-24 al integrar modo claro a la app.
///
/// A propósito NO viven acá los colores de marca (`AppColors.accent` y
/// derivados) ni los semánticos de estado (`AppColors.pendiente`/
/// `seleccionada`/`rechazada`, ver `estado_colors.dart`): esos NO cambian
/// entre modo claro y oscuro, son identidad de marca / indicadores de UI,
/// no "superficie". Esta paleta solo cubre los roles que sí necesitan un
/// valor distinto según el modo.
///
/// Se consume vía `context.colors.xxx` (extensión al final de este archivo)
/// en vez de un valor estático, para que cada widget se repinte solo cuando
/// cambia el modo (`Theme.of(context)` sí es reactivo; un campo `static
/// const` no lo es).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Paleta original de la app (dashboard oscuro), sin cambios de valores.
  static const dark = AppPalette(
    background: Color(0xFF0D0D0D), // --cdlr-ink del sitio
    surface: Color(0xFF1A1A1A), // mismo gris que usa .cdlr-plan--featured
    surfaceElevated: Color(0xFF232323),
    border: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE0E0E0), // --cdlr-body-dark
    textMuted: Color(0xFF4C5A60), // --cdlr-muted
  );

  /// Paleta clara nueva — mismos tokens de marca que el sitio institucional
  /// (`--cdlr-ink`/`--cdlr-line`), no valores inventados: es literalmente
  /// como se ve el sitio PHP en modo normal (fondo claro, texto oscuro).
  static const light = AppPalette(
    background: Color(0xFFF7F4F1), // cálido, no blanco puro — ecoa --cdlr-line
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0xFFE8DFDA), // --cdlr-line del sitio, literal
    textPrimary: Color(0xFF0D0D0D), // --cdlr-ink del sitio, literal
    textSecondary: Color(0xFF3F3B38),
    textMuted: Color(0xFF6B6560),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Acceso corto: `context.colors.textMuted` en vez de
/// `Theme.of(context).extension<AppPalette>()!.textMuted`.
extension AppPaletteContext on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
