import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la preferencia de modo claro/oscuro elegida por quien usa la
/// app (agregado 2026-08-24), en `SharedPreferences` — en Web esto vive en
/// el `localStorage` del propio navegador, así que la elección sobrevive a
/// recargar la página o volver más tarde, pero es por dispositivo/navegador
/// (no viaja con la cuenta de Firebase).
class ThemeService {
  static const _key = 'cdlr_theme_mode';

  Future<ThemeMode> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // por defecto: el look de siempre, hasta que alguien elija otro.
    };
  }

  Future<void> guardar(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
