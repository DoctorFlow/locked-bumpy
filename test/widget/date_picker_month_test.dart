import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/pregnancy.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:little_bumpy/presentation/widgets/pregnancy_date_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Date step, item 2: the picker opens on a sensible month, and any month
/// is two taps away. Plus the empty-OK check by touch and by the
/// accessibility tree.

final _today = DateTime(2026, 11, 23);

int _monthsApart(DateTime a, DateTime b) =>
    ((a.year - b.year) * 12 + a.month - b.month).abs();

Future<void> _open(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'is_halloween': true});
  final state = await AppState.load(now: () => _today);
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(AppPalette.halloween),
      home: FirstRunScreen(state: state),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Start'));
  await _tap(tester, find.text('Choose due date'));
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

DateTime _first(DateTime t, bool due) =>
    DateTime(t.year, t.month, t.day + (due ? -7 : -294));
DateTime _last(DateTime t, bool due) =>
    DateTime(t.year, t.month, t.day + (due ? 294 : 0));

void main() {
  group('opening month', () {
    test('each calendar opens on the middle month of its range', () {
      expect(
        pickerOpeningMonth(
          today: _today,
          useDueDate: true,
          first: _first(_today, true),
          last: _last(_today, true),
        ),
        DateTime(2027, 4),
      );
      expect(
        pickerOpeningMonth(
          today: _today,
          useDueDate: false,
          first: _first(_today, false),
          last: _last(_today, false),
        ),
        DateTime(2026, 6),
      );
    });

    test('a chosen day opens on its own month', () {
      expect(
        pickerOpeningMonth(
          today: _today,
          useDueDate: true,
          first: _first(_today, true),
          last: _last(_today, true),
          selected: DateTime(2027, 3, 15),
        ),
        DateTime(2027, 3),
      );
    });

    // Every day of a year, so the day of the month cannot hide a gap.
    test('for weeks 4 to 35 the month is at most four month taps away, and '
        'for weeks 36 to 41 at most five, on any day of the year, both ways', () {
      for (var i = 0; i < 366; i++) {
        final today = DateTime(2026, 1, 1 + i);
        for (final due in [true, false]) {
          final open = pickerOpeningMonth(
            today: today,
            useDueDate: due,
            first: _first(today, due),
            last: _last(today, due),
          );
          for (var week = 4; week <= 41; week++) {
            final dueDate = PregnancyCalculator.dueDateForWeek(
              week: week,
              currentDate: today,
            );
            final target = due
                ? dueDate
                : DateTime(dueDate.year, dueDate.month, dueDate.day - 280);
            expect(
              _monthsApart(open, target),
              lessThanOrEqualTo(week <= 35 ? 4 : 5),
              reason: '$today week $week ${due ? 'due' : 'period'}',
            );
          }
        }
      }
    });

    test('the opening month always lies inside the offered range', () {
      for (var i = 0; i < 366; i++) {
        final today = DateTime(2026, 1, 1 + i);
        for (final due in [true, false]) {
          final first = _first(today, due);
          final last = _last(today, due);
          for (final selected in [
            null,
            DateTime(2020),
            DateTime(2035),
            today,
          ]) {
            final open = pickerOpeningMonth(
              today: today,
              useDueDate: due,
              first: first,
              last: last,
              selected: selected,
            );
            expect(open.isBefore(DateTime(first.year, first.month)), isFalse);
            expect(open.isAfter(DateTime(last.year, last.month)), isFalse);
          }
        }
      }
    });
  });

  testWidgets('the picker opens on April 2027 with no day chosen; the camera '
      'date (15 March 2027) is one Previous-month tap away', (tester) async {
    await _open(tester);
    expect(find.text('April 2027'), findsOneWidget);
    expect(find.text('No day chosen yet'), findsOneWidget);
    await _tap(tester, find.byTooltip('Previous month'));
    expect(find.text('March 2027'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('picker-day-2027-3-15')));
    expect(find.text('15 March 2027'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('picker-ok')));
    expect(find.byType(PregnancyCalendarDialog), findsNothing);
  });

  testWidgets('the month list offers every month in range and reaches any '
      'of them in two taps', (tester) async {
    await _open(tester);
    await _tap(tester, find.byKey(const ValueKey('picker-month')));
    // Due dates from a week back to 42 weeks ahead: Nov 2026 to Sep 2027.
    for (
      var m = DateTime(2026, 11);
      !m.isAfter(DateTime(2027, 9));
      m = DateTime(m.year, m.month + 1)
    ) {
      expect(
        find.byKey(ValueKey('picker-month-${m.year}-${m.month}')),
        findsOneWidget,
        reason: '$m',
      );
    }
    expect(find.byKey(const ValueKey('picker-month-2026-10')), findsNothing);
    expect(find.byKey(const ValueKey('picker-month-2027-10')), findsNothing);
    // Every piece is a 48 px target.
    final piece = tester.getSize(
      find.byKey(const ValueKey('picker-month-2027-1')),
    );
    expect(piece.height, greaterThanOrEqualTo(48));
    await _tap(tester, find.byKey(const ValueKey('picker-month-2026-12')));
    expect(find.text('December 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('picker-day-2026-12-1')), findsOneWidget);
  });

  testWidgets('days before the range cannot be chosen; Previous stops at '
      'the first month', (tester) async {
    await _open(tester);
    await _tap(tester, find.byKey(const ValueKey('picker-month')));
    await _tap(tester, find.byKey(const ValueKey('picker-month-2026-11')));
    // First offered day: 16 Nov 2026 (a week before today).
    await _tap(tester, find.byKey(const ValueKey('picker-day-2026-11-15')));
    expect(find.text('No day chosen yet'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('picker-day-2026-11-16')));
    expect(find.text('16 November 2026'), findsOneWidget);
    final previous = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    expect(previous.onPressed, isNull);
  });

  testWidgets('through the accessibility tree: OK with no day stays open '
      'and says "Pick a day first"; a day then lights OK; Cancel closes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    tester.semantics.tap(find.semantics.byLabel('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(PregnancyCalendarDialog), findsOneWidget);
    expect(find.text(pickADayFirst), findsOneWidget);
    // Said aloud: the line is a live region.
    expect(
      tester
          .getSemantics(find.text(pickADayFirst))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );

    tester.semantics.tap(
      find.semantics.byPredicate(
        (n) =>
            n.label.startsWith('20, ') &&
            n.getSemanticsData().hasAction(SemanticsAction.tap),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(pickADayFirst), findsNothing);
    expect(find.text('20 April 2027'), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(PregnancyCalendarDialog), findsNothing);
    expect(find.text('Choose due date'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('through the accessibility tree: the month list and OK save '
      'the day', (tester) async {
    final handle = tester.ensureSemantics();
    await _open(tester);
    tester.semantics.tap(
      find.semantics.byLabel('April 2027. Choose another month'),
    );
    await tester.pumpAndSettle();
    tester.semantics.tap(find.semantics.byLabel('March 2027'));
    await tester.pumpAndSettle();
    tester.semantics.tap(find.semantics.byLabel('15, Monday, March 15, 2027'));
    await tester.pumpAndSettle();
    tester.semantics.tap(find.semantics.byLabel('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(PregnancyCalendarDialog), findsNothing);
    final next = find.widgetWithText(ElevatedButton, 'Next');
    expect(tester.widget<ElevatedButton>(next).onPressed, isNotNull);
    handle.dispose();
  });
}
