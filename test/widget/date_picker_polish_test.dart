import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Design critique 3, lane B: the due-date picker.

Future<AppState> _fresh({required bool halloween}) async {
  SharedPreferences.setMockInitialValues({'is_halloween': halloween});
  return AppState.load(now: () => DateTime(2026, 11, 23));
}

Future<void> _pump(WidgetTester tester, AppState state, Size size) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final palette = state.isHalloween
      ? AppPalette.halloween
      : AppPalette.everyday;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(palette),
      home: FirstRunScreen(state: state),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openPicker(WidgetTester tester) async {
  await tester.tap(find.text('Start'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose due date'));
  await tester.pumpAndSettle();
}

final _ok = find.byKey(const ValueKey('picker-ok'));

Material _okMaterial(WidgetTester tester) => tester.widget<Material>(
  find.descendant(of: _ok, matching: find.byType(Material)).first,
);

Color _textColor(WidgetTester tester, String label) =>
    DefaultTextStyle.of(tester.element(find.text(label))).style.color!;

TextDecoration? _decoration(WidgetTester tester, String label) =>
    DefaultTextStyle.of(tester.element(find.text(label))).style.decoration;

Rect _okPiece(WidgetTester tester) => tester.getRect(
  find.descendant(of: _ok, matching: find.byType(Material)).first,
);

void main() {
  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    final palette = halloween ? AppPalette.halloween : AppPalette.everyday;

    testWidgets('$look: before a day is picked OK rests on raised paper; '
        'after a touch it is the accent main button and Cancel is quiet ink', (
      tester,
    ) async {
      await _pump(
        tester,
        await _fresh(halloween: halloween),
        const Size(375, 812),
      );
      await _openPicker(tester);

      // Waiting: a resting button, not a dead link.
      expect(_okMaterial(tester).color, palette.paperRaised);
      expect(_textColor(tester, 'OK').a, lessThan(1));
      expect(_decoration(tester, 'OK'), isNot(TextDecoration.underline));
      // Cancel is never the bright one.
      expect(_textColor(tester, 'Cancel'), palette.ink);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').hitTestable().first);
      await tester.pumpAndSettle();

      expect(_okMaterial(tester).color, palette.accent);
      expect(_textColor(tester, 'OK'), palette.accentText);
      expect(_decoration(tester, 'OK'), isNot(TextDecoration.underline));
      expect(_textColor(tester, 'Cancel'), palette.ink);
      // Cancel is a quiet button, not a link: no underline either.
      expect(_decoration(tester, 'Cancel'), isNot(TextDecoration.underline));
      expect(
        tester.getSize(find.byKey(const ValueKey('picker-cancel'))).height,
        greaterThanOrEqualTo(48),
      );
      final ok = tester.getSize(_ok);
      expect(ok.width, greaterThanOrEqualTo(64));
      expect(ok.height, greaterThanOrEqualTo(48));
      // The accent piece clears the dialog's rounded bottom corner.
      final piece = _okPiece(tester);
      final dialog = tester.getRect(find.byType(Dialog));
      expect(dialog.bottom - piece.bottom, greaterThanOrEqualTo(4));
      expect(dialog.right - piece.right, greaterThanOrEqualTo(8));
    });
  }

  testWidgets('a day picked by a screen reader tap (no pointer) also lights '
      'OK', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, await _fresh(halloween: true), const Size(375, 812));
    await _openPicker(tester);
    expect(_okMaterial(tester).color, AppPalette.halloween.paperRaised);

    tester.semantics.tap(
      find.semantics.byPredicate(
        (n) =>
            n.label.startsWith('20,') &&
            n.getSemanticsData().hasAction(SemanticsAction.tap),
      ),
    );
    await tester.pumpAndSettle();
    expect(_okMaterial(tester).color, AppPalette.halloween.accent);
    expect(_textColor(tester, 'OK'), AppPalette.halloween.accentText);
    handle.dispose();
  });

  for (final width in [320.0, 375.0, 412.0]) {
    testWidgets('the Pause circle sits wholly inside the screen at '
        '${width.toInt()} px', (tester) async {
      final size = Size(width, width == 320 ? 568 : 812);
      await _pump(tester, await _fresh(halloween: true), size);
      await _openPicker(tester);
      final pause = tester.getRect(
        find
            .descendant(
              of: find.byKey(const ValueKey('picker-pause')),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(pause.right, lessThanOrEqualTo(width - 8));
      expect(pause.top, greaterThanOrEqualTo(0));
      // And it does not sit on top of the calendar.
      final dialog = tester.getRect(find.byType(Dialog));
      expect(pause.bottom, lessThanOrEqualTo(dialog.top));
    });
  }
}
