import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/pregnancy.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Date step, item 1: "I know how many weeks" beside "I know my due date".

final _today = DateTime(2026, 11, 23);

Future<AppState> _fresh({bool halloween = true}) async {
  SharedPreferences.setMockInitialValues({'is_halloween': halloween});
  return AppState.load(now: () => _today);
}

Future<AppState> _open(
  WidgetTester tester, {
  bool halloween = true,
  Size size = const Size(375, 812),
  double text = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final state = await _fresh(halloween: halloween);
  final palette = halloween ? AppPalette.halloween : AppPalette.everyday;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(palette),
      home: FirstRunScreen(state: state),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Start'));
  return state;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await _tap(tester, find.text('Next'));
  }
  final enter = find.text('Meet Bumpy');
  await tester.ensureVisible(enter);
  await tester.pumpAndSettle();
  await tester.tap(enter);
  // Outside the app shell the screen keeps its saving spinner turning.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('choosing the weeks way opens the week grid at once, and one '
      'tap on a week fills the step', (tester) async {
    await _open(tester);
    await _tap(tester, find.text('I know how many weeks'));
    expect(find.text('Pick your week'), findsOneWidget);
    for (var n = 4; n <= 42; n++) {
      expect(find.byKey(ValueKey('week-tile-$n')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('week-tile-3')), findsNothing);
    expect(find.byKey(const ValueKey('week-tile-43')), findsNothing);

    await _tap(tester, find.byKey(const ValueKey('week-tile-9')));
    expect(find.text('Pick your week'), findsNothing);
    expect(find.text('Week 9'), findsOneWidget);
    final next = find.widgetWithText(ElevatedButton, 'Next');
    expect(tester.widget<ElevatedButton>(next).onPressed, isNotNull);

    // The piece opens the grid again, with week 9 marked by fill and tick.
    await _tap(tester, find.text('Week 9'));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('week-tile-9'))),
      isNotNull,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('week-tile-9')),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip('Close'));
    expect(find.text('Week 9'), findsOneWidget);
  });

  testWidgets('Close with no week leaves the step waiting, Next held', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.text('I know how many weeks'));
    await _tap(tester, find.byTooltip('Close'));
    expect(find.text('Choose your week'), findsOneWidget);
    final next = find.widgetWithText(ElevatedButton, 'Next');
    expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
  });

  for (final week in [4, 9, 24, 42]) {
    testWidgets('week $week saves the same kind of value the date way saves: '
        'a due date that reads back as week $week', (tester) async {
      final state = await _open(tester);
      await _tap(tester, find.text('I know how many weeks'));
      await _tap(tester, find.byKey(ValueKey('week-tile-$week')));
      await _finish(tester);
      expect(state.isFirstRun, isFalse);
      expect(
        state.dueDate,
        PregnancyCalculator.dueDateForWeek(week: week, currentDate: _today),
      );
      expect(state.currentWeek, week);
      final reloaded = await AppState.load(now: () => _today);
      expect(reloaded.dueDate, state.dueDate);
      expect(reloaded.currentWeek, week);
    });
  }

  testWidgets('switching ways keeps each choice; Next follows the shown way', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.text('I know how many weeks'));
    await _tap(tester, find.byKey(const ValueKey('week-tile-12')));
    await _tap(tester, find.text('I know my due date'));
    expect(find.text('Choose due date'), findsOneWidget);
    final next = find.widgetWithText(ElevatedButton, 'Next');
    expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
    // Back to weeks: no second grid, the week is still there.
    await _tap(tester, find.text('I know how many weeks'));
    expect(find.text('Pick your week'), findsNothing);
    expect(find.text('Week 12'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(next).onPressed, isNotNull);
  });

  for (final halloween in [true, false]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    testWidgets('$look: the way choice and the week grid hold at 320 px and '
        '2x text, every tile at least 48 x 48', (tester) async {
      await _open(
        tester,
        halloween: halloween,
        size: const Size(320, 568),
        text: 2,
      );
      expect(tester.takeException(), isNull);
      for (final label in [
        'I know my due date',
        'I know how many weeks',
        'I know when my last period started',
      ]) {
        final r = tester.getRect(find.text(label));
        expect(r.left, greaterThanOrEqualTo(0), reason: label);
        expect(r.right, lessThanOrEqualTo(320), reason: label);
      }
      await _tap(tester, find.text('I know how many weeks'));
      expect(tester.takeException(), isNull);
      for (final n in [4, 9, 10, 42]) {
        final tile = find.byKey(ValueKey('week-tile-$n'));
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        final r = tester.getRect(tile);
        expect(r.width, greaterThanOrEqualTo(48), reason: 'week $n');
        expect(r.height, greaterThanOrEqualTo(48), reason: 'week $n');
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(320));
        // The number sits whole inside its tile.
        final text = tester.getRect(
          find.descendant(of: tile, matching: find.text('$n')),
        );
        expect(
          r.contains(text.topLeft) &&
              r.contains(text.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
        );
      }
      await _tap(tester, find.byKey(const ValueKey('week-tile-42')));
      expect(find.text('Week 42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a screen reader can pick a week: each tile is a button '
      'named "Week N"', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    await _tap(tester, find.text('I know how many weeks'));
    final node = find.semantics.byLabel('Week 20');
    expect(node, findsOne);
    tester.semantics.tap(node);
    await tester.pumpAndSettle();
    expect(find.text('Week 20'), findsOneWidget);
    expect(find.text('Pick your week'), findsNothing);
    handle.dispose();
  });
}
