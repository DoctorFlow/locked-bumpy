import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/pregnancy.dart';

/// The "I know how many weeks" way saves a due date. It must turn back into
/// the very week the parent chose, for every week the app shows.
void main() {
  final days = [
    DateTime(2026, 11, 23),
    DateTime(2026, 12, 31),
    DateTime(2027, 2, 28),
    DateTime(2028, 2, 29),
    // Local clocks change around these days in many places.
    DateTime(2027, 3, 14),
    DateTime(2027, 3, 28),
    DateTime(2027, 11, 7),
  ];

  for (final today in days) {
    test('weeks 4 to 42 round trip on $today', () {
      for (var week = 4; week <= 42; week++) {
        final due = PregnancyCalculator.dueDateForWeek(
          week: week,
          currentDate: today,
        );
        expect(
          PregnancyCalculator.weekFromDueDate(dueDate: due, currentDate: today),
          week,
          reason: 'week $week on $today',
        );
        // A calendar date at midnight, like the date picker's.
        expect(due, DateTime(due.year, due.month, due.day));
        // Today is the first day of that week, so the week holds six more
        // days and then moves on.
        expect(
          PregnancyCalculator.daysFromDueDate(dueDate: due, currentDate: today),
          7 * week,
        );
        final sixLater = DateTime(today.year, today.month, today.day + 6);
        final sevenLater = DateTime(today.year, today.month, today.day + 7);
        expect(
          PregnancyCalculator.weekFromDueDate(
            dueDate: due,
            currentDate: sixLater,
          ),
          week,
        );
        if (week < 42) {
          expect(
            PregnancyCalculator.weekFromDueDate(
              dueDate: due,
              currentDate: sevenLater,
            ),
            week + 1,
          );
        }
      }
    });
  }

  test('week 40 is due today; week 24 matches the camera date', () {
    final today = DateTime(2026, 11, 23);
    expect(
      PregnancyCalculator.dueDateForWeek(week: 40, currentDate: today),
      today,
    );
    expect(
      PregnancyCalculator.dueDateForWeek(week: 24, currentDate: today),
      DateTime(2027, 3, 15),
    );
  });
}
