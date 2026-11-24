import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chooses [day] in the open pregnancy date picker and taps OK.
///
/// The picker opens with no day chosen (a tired parent must not save a week
/// by tapping OK), so a test types the date in the picker's own input mode.
Future<void> chooseDateInPicker(WidgetTester tester, DateTime day) async {
  await tester.tap(find.byTooltip('Switch to input'));
  await tester.pumpAndSettle();
  final field = find.descendant(
    of: find.byType(DatePickerDialog),
    matching: find.byType(TextField),
  );
  String two(int n) => n.toString().padLeft(2, '0');
  await tester.enterText(
    field,
    '${two(day.month)}/${two(day.day)}/${day.year}',
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

/// The date the old picker opened on for a due date (today + 140 days) and a
/// last period (today − 140 days), so earlier expectations still hold.
DateTime dueIn140(DateTime today) =>
    DateTime(today.year, today.month, today.day + 140);
DateTime periodBack140(DateTime today) =>
    DateTime(today.year, today.month, today.day - 140);
