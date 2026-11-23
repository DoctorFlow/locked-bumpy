import 'package:flutter/material.dart';

Future<DateTime?> pickPregnancyDate(
  BuildContext context, {
  required DateTime today,
  required bool useDueDate,
  DateTime? selected,
}) {
  DateTime offset(int days) =>
      DateTime(today.year, today.month, today.day + days);
  final first = offset(useDueDate ? -7 : -294);
  final last = offset(useDueDate ? 294 : 0);
  final candidate = selected ?? offset(useDueDate ? 140 : -140);
  // Older saves may fall outside the interval offered for a new choice.
  final initial = candidate.isBefore(first)
      ? first
      : candidate.isAfter(last)
      ? last
      : candidate;
  return showDatePicker(
    context: context,
    currentDate: today,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    helpText: useDueDate ? 'Pick your due date' : 'Pick your last period start',
  );
}
