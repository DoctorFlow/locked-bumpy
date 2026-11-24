import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chooses [day] in the open pregnancy date picker and taps OK.
///
/// The picker opens with no day chosen (a tired parent must not save a week
/// by tapping OK), so a test jumps with the month list, as a parent can:
/// the month's name, then the month, then the day.
Future<void> chooseDateInPicker(WidgetTester tester, DateTime day) async {
  Future<void> tap(Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  await tap(find.byKey(const ValueKey('picker-month')));
  await tap(find.byKey(ValueKey('picker-month-${day.year}-${day.month}')));
  await tap(
    find.byKey(ValueKey('picker-day-${day.year}-${day.month}-${day.day}')),
  );
  await tap(find.byKey(const ValueKey('picker-ok')));
}

/// The date the old picker opened on for a due date (today + 140 days) and a
/// last period (today − 140 days), so earlier expectations still hold.
DateTime dueIn140(DateTime today) =>
    DateTime(today.year, today.month, today.day + 140);
DateTime periodBack140(DateTime today) =>
    DateTime(today.year, today.month, today.day - 140);
