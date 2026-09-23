import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_palette.dart';

/// Tema visual centralizado de la app: Material 3, con la tipografía y
/// paleta reales de la Corporación de La Raíz — Oswald para títulos y
/// Montserrat para el cuerpo, mismo criterio que `--font-display`/
/// `--font-body` del sitio institucional (unificado 2026-08-12, antes la
/// app usaba Manrope sola, sin relación con la marca real). Pensado como
/// un dashboard premium, no un formulario genérico de Material por defecto.
///
/// `dark()`/`light()` (2026-08-24) comparten toda la construcción vía
/// `_build()` — la única diferencia real entre ambos modos es qué
/// [AppPalette] se registra como `ThemeExtension`. El acento de marca, los
/// colores semánticos de estado y el radio de 16px NO cambian entre modos
/// a propósito (ver `AppPalette` para el porqué).
class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);

  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.accent,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      outline: palette.border,
      error: AppColors.rechazada,
    );

    final baseTextTheme =
        brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    // Montserrat como base (cuerpo) y Oswald superpuesto en los estilos de
    // título/encabezado — mismo reparto que el sitio PHP (Oswald mayúsculas
    // condensadas para títulos, Montserrat para todo lo demás).
    final bodyTextTheme = GoogleFonts.montserratTextTheme(baseTextTheme);
    final displayTextTheme = GoogleFonts.oswaldTextTheme(baseTextTheme);
    final textTheme = bodyTextTheme.copyWith(
      headlineSmall: displayTextTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
        letterSpacing: 0.2,
      ),
      titleLarge: displayTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      titleMedium: displayTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleSmall: displayTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      bodyLarge: bodyTextTheme.bodyLarge?.copyWith(color: palette.textPrimary),
      bodyMedium: bodyTextTheme.bodyMedium?.copyWith(color: palette.textSecondary),
      bodySmall: bodyTextTheme.bodySmall?.copyWith(color: palette.textMuted),
      labelLarge: bodyTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      dividerColor: palette.border,
      splashFactory: InkRipple.splashFactory,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceElevated,
        hintStyle: TextStyle(color: palette.textMuted),
        labelStyle: TextStyle(color: palette.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          // 16px: mismo --radius que usan las tarjetas del sitio (premium.css).
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          // Píldora (999px): mismo lenguaje que .cdlr-btn del sitio, no un
          // rectángulo con esquinas redondeadas.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(palette.surfaceElevated),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceElevated,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
