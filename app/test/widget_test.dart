import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delaraiz/app/app_theme.dart';

void main() {
  testWidgets('AppTheme.dark() builds a valid Material 3 theme', (tester) async {
    // Smoke test simple: no requiere Firebase inicializado (a diferencia de
    // DeLaRaizApp, que sí lo requiere), solo valida que el tema no explote.
    final theme = AppTheme.dark();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.dark);
  });

  test('ProviderContainer se puede crear sin errores', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container, isNotNull);
  });
}
