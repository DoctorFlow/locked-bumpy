import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:little_bumpy/presentation/widgets/pregnancy_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Date step, item 4: day numbers are never cut at 2x text and 320 px.
/// Real fonts are loaded: the test font draws every digit 1 em wide, which
/// would make a fit test meaningless.

final _today = DateTime(2026, 11, 23);

Future<void> _open(
  WidgetTester tester, {
  required bool halloween,
  required double text,
  Size size = const Size(320, 568),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({'is_halloween': halloween});
  final state = await AppState.load(now: () => _today);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(halloween ? AppPalette.halloween : AppPalette.everyday),
      home: FirstRunScreen(state: state),
    ),
  );
  await tester.pumpAndSettle();
  for (final label in ['Start', 'Choose due date']) {
    final f = find.text(label);
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }
  // The picker opens on April 2027 (the middle of its range); the checks
  // below use May 2027, which needs six rows of days.
  final next = find.byTooltip('Next month');
  await tester.ensureVisible(next);
  await tester.pumpAndSettle();
  await tester.tap(next);
  await tester.pumpAndSettle();
}

/// Every day number of the shown month sits whole inside its own cell,
/// and inside the screen's width.
void _expectWholeNumbers(
  WidgetTester tester,
  DateTime month, {
  required bool fullSize,
  required double width,
}) {
  final days = DateUtils.getDaysInMonth(month.year, month.month);
  for (var d = 1; d <= days; d++) {
    final cell = tester.getRect(
      find.byKey(ValueKey('picker-day-${month.year}-${month.month}-$d')),
    );
    final numberFinder = find.byKey(ValueKey('picker-day-number-$d'));
    final number = tester.getRect(numberFinder);
    expect(cell.left, greaterThanOrEqualTo(0), reason: 'day $d');
    expect(cell.right, lessThanOrEqualTo(width), reason: 'day $d');
    expect(number.left, greaterThanOrEqualTo(cell.left - 0.01));
    expect(number.right, lessThanOrEqualTo(cell.right + 0.01));
    expect(number.top, greaterThanOrEqualTo(cell.top - 0.01));
    expect(number.bottom, lessThanOrEqualTo(cell.bottom + 0.01));
    final paragraph = tester.renderObject<RenderParagraph>(numberFinder);
    expect(paragraph.didExceedMaxLines, isFalse);
    if (fullSize) {
      // At 2x the numbers keep their full size: nothing shrunk to fit.
      expect(number.height, closeTo(paragraph.size.height, 0.5));
      expect(number.width, closeTo(paragraph.size.width, 0.5));
    }
    expect(cell.height, greaterThanOrEqualTo(48));
  }
}

void main() {
  setUpAll(() async {
    Future<void> face(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }

    await face('Fraunces', ['Fraunces.ttf']);
    await face('Atkinson Hyperlegible', [
      'AtkinsonHyperlegible-Regular.ttf',
      'AtkinsonHyperlegible-Bold.ttf',
    ]);
  });

  for (final halloween in [true, false]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    testWidgets('$look: at 320 px and 2x text every day number is whole and '
        'full size; the days scroll and OK stays on screen', (tester) async {
      await _open(tester, halloween: halloween, text: 2);
      expect(tester.takeException(), isNull);
      expect(find.byType(PregnancyCalendarDialog), findsOneWidget);

      // Rows grow with the text: taller than the 48 px rows at 1x (the
      // touch piece sits 2 px inside its row).
      final cell = tester.getRect(
        find.byKey(const ValueKey('picker-day-2027-5-1')),
      );
      expect(cell.height + 4, greaterThan(48));

      // Every number, scrolling each into view, in the opening month and
      // in the month with 31 days that needs six rows (May 2027 already
      // does: it starts on a Saturday).
      for (var d = 1; d <= 31; d++) {
        await tester.ensureVisible(
          find.byKey(ValueKey('picker-day-2027-5-$d')),
        );
        await tester.pumpAndSettle();
      }
      _expectWholeNumbers(
        tester,
        DateTime(2027, 5),
        fullSize: true,
        width: 320,
      );

      final ok = tester.getRect(find.byKey(const ValueKey('picker-ok')));
      expect(ok.bottom, lessThanOrEqualTo(568));
      expect(ok.top, greaterThanOrEqualTo(0));
      expect(ok.height, greaterThanOrEqualTo(48));

      // Choosing a day at 2x still works, and the header says it.
      await tester.ensureVisible(
        find.byKey(const ValueKey('picker-day-2027-5-28')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker-day-2027-5-28')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('picker-ok')));
      await tester.pumpAndSettle();
      expect(find.byType(PregnancyCalendarDialog), findsNothing);
      expect(find.text('28 May 2027'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$look: at 3x text numbers are drawn smaller, never cut', (
      tester,
    ) async {
      await _open(tester, halloween: halloween, text: 3);
      expect(tester.takeException(), isNull);
      _expectWholeNumbers(
        tester,
        DateTime(2027, 5),
        fullSize: false,
        width: 320,
      );
    });

    testWidgets('$look: the month list holds at 320 px and 2x text', (
      tester,
    ) async {
      await _open(tester, halloween: halloween, text: 2);
      await tester.tap(find.byKey(const ValueKey('picker-month')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final piece = find.byKey(const ValueKey('picker-month-2027-9'));
      await tester.ensureVisible(piece);
      await tester.pumpAndSettle();
      final r = tester.getRect(piece);
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
      expect(r.height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('landscape 568 x 320 at 2x text: no overflow, OK in reach', (
    tester,
  ) async {
    await _open(tester, halloween: true, text: 2, size: const Size(568, 320));
    expect(tester.takeException(), isNull);
    final ok = tester.getRect(find.byKey(const ValueKey('picker-ok')));
    expect(ok.bottom, lessThanOrEqualTo(320));
  });
}
