import 'package:flutter/material.dart';
import 'pause_button.dart';

Future<DateTime?> pickPregnancyDate(
  BuildContext context, {
  required DateTime today,
  required bool useDueDate,
  required VoidCallback onPause,
  DateTime? selected,
}) {
  DateTime offset(int days) =>
      DateTime(today.year, today.month, today.day + days);
  final first = offset(useDueDate ? -7 : -294);
  final last = offset(useDueDate ? 294 : 0);
  // A first choice opens on this month with no day chosen, so OK cannot save
  // a week the parent never picked (OK with nothing chosen returns null).
  // A saved date opens selected; older saves may fall outside the interval
  // offered for a new choice.
  final candidate = selected;
  final initial = candidate == null
      ? null
      : candidate.isBefore(first)
      ? first
      : candidate.isAfter(last)
      ? last
      : candidate;
  return showDialog<DateTime>(
    context: context,
    builder: (dialog) {
      final size = MediaQuery.sizeOf(dialog);
      final short = size.width > size.height && size.height < 480;
      final calendar = DatePickerDialog(
        currentDate: today,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        helpText: useDueDate
            ? 'Pick your due date'
            : 'Pick your last period start',
        insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
      final pause = Material(
        color: Theme.of(dialog).colorScheme.surface,
        shape: const CircleBorder(),
        child: PauseButton(
          onPressed: onPause,
          color: Theme.of(dialog).colorScheme.onSurface,
        ),
      );
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: short ? 640 : 420),
          child: short
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: calendar),
                    pause,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(alignment: Alignment.centerRight, child: pause),
                    Flexible(child: calendar),
                  ],
                ),
        ),
      );
    },
  );
}
