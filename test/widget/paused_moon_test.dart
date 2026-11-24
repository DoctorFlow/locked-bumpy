import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/paused_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Design critique 3: the Halloween moon on Paused was a flat pumpkin disc.
void main() {
  for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
    final look = palette.isHalloween ? 'Halloween' : 'Everyday';
    testWidgets('$look: the Paused moon is a pale paper moon', (t) async {
      SharedPreferences.setMockInitialValues({
        'is_paused': true,
        'is_halloween': palette.isHalloween,
      });
      final state = await AppState.load(now: () => DateTime(2026, 11, 23));
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(palette),
          home: Scaffold(body: PausedScreen(state: state)),
        ),
      );
      await t.pumpAndSettle();
      final moon = t.widget<Container>(
        find.byKey(const ValueKey('paused-moon')),
      );
      final fill = (moon.decoration! as BoxDecoration).color!;
      expect(fill, palette.isHalloween ? palette.moonlight : palette.moon);
      // Never the accent: in Halloween that is the pumpkin orange.
      expect(fill, isNot(palette.accent));
      // Pale: a moon (the pumpkin orange is 0.47).
      expect(fill.computeLuminance(), greaterThan(0.6));
    });
  }
}
