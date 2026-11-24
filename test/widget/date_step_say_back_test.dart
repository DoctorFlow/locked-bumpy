import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pick_date_helper.dart';

/// Date step, item 3: after any way in, the step says back what the app
/// now holds, before the parent moves on.

final _today = DateTime(2026, 11, 23);
final _sayBack = find.byKey(const ValueKey('date-step-say-back'));

Future<AppState> _open(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  double text = 1,
  bool halloween = true,
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
  await _tap(tester, find.text('Start'));
  return state;
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void _expectOnScreen(WidgetTester tester, Size size) {
  final r = tester.getRect(_sayBack);
  expect(r.top, greaterThanOrEqualTo(0));
  expect(r.bottom, lessThanOrEqualTo(size.height));
}

void main() {
  testWidgets('nothing is said back before a choice', (tester) async {
    await _open(tester);
    expect(_sayBack, findsNothing);
    expect(find.textContaining('Due around'), findsNothing);
  });

  testWidgets('the due-date way: "Week 24. Due around 15 March."', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.text('Choose due date'));
    await chooseDateInPicker(tester, DateTime(2027, 3, 15));
    expect(find.text('15 March 2027'), findsOneWidget);
    expect(find.text('Week 24. Due around 15 March.'), findsOneWidget);
    expect(find.text('You can change this later in Settings.'), findsOneWidget);
    _expectOnScreen(tester, const Size(375, 812));
  });

  testWidgets('the weeks way: week 9 is due around 28 June', (tester) async {
    await _open(tester);
    await _tap(tester, find.text('I know how many weeks'));
    await _tap(tester, find.byKey(const ValueKey('week-tile-9')));
    expect(find.text('Week 9. Due around 28 June.'), findsOneWidget);
    _expectOnScreen(tester, const Size(375, 812));
  });

  testWidgets('the last-period way says the due date it worked out', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, find.text('I know when my last period started'));
    await _tap(tester, find.text('Choose period start date'));
    await chooseDateInPicker(tester, DateTime(2026, 7, 6));
    expect(find.text('Week 20. Due around 12 April.'), findsOneWidget);
  });

  testWidgets('a new choice changes the line; switching ways shows the '
      'line for the way on screen', (tester) async {
    await _open(tester);
    await _tap(tester, find.text('I know how many weeks'));
    await _tap(tester, find.byKey(const ValueKey('week-tile-9')));
    await _tap(tester, find.text('Week 9'));
    await _tap(tester, find.byKey(const ValueKey('week-tile-30')));
    expect(find.text('Week 30. Due around 1 February.'), findsOneWidget);
    await _tap(tester, find.text('I know my due date'));
    expect(_sayBack, findsNothing);
  });

  testWidgets('the line is read aloud when it appears (a live region)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    await _tap(tester, find.text('I know how many weeks'));
    await _tap(tester, find.byKey(const ValueKey('week-tile-9')));
    final data = tester.getSemantics(_sayBack).getSemanticsData();
    expect(data.flagsCollection.isLiveRegion, isTrue);
    expect(data.label, contains('Week 9. Due around 28 June.'));
    handle.dispose();
  });

  for (final halloween in [true, false]) {
    testWidgets('${halloween ? 'Halloween' : 'Everyday'}: at 320 px and 2x '
        'text the line comes into view after a choice', (tester) async {
      const size = Size(320, 568);
      await _open(tester, size: size, text: 2, halloween: halloween);
      await _tap(tester, find.text('I know how many weeks'));
      await _tap(tester, find.byKey(const ValueKey('week-tile-9')));
      expect(tester.takeException(), isNull);
      _expectOnScreen(tester, size);
    });
  }

  test('the words a parent reads keep the house rules', () {
    const lines = [
      'I know my due date',
      'I know how many weeks',
      'I know when my last period started',
      'Pick your week',
      'Choose your week',
      'Week 9. Due around 28 June.',
      'You can change this later in Settings.',
      'No day chosen yet',
      'Pick a day first',
    ];
    final banned = RegExp(
      r'\b(should|must|need to|have to|missed|forgot|failed|weight|diet|'
      r'lesson|learn|teach|congrat\w*)\b|—|!',
      caseSensitive: false,
    );
    for (final line in lines) {
      expect(banned.hasMatch(line), isFalse, reason: line);
    }
  });
}
