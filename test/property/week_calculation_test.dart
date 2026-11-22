import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:little_bumpy/domain/pregnancy.dart';

void main() {
  group('PregnancyCalculator Property Tests (kiri_check)', () {
    property('Gestational week is strictly bounded between 4 and 42', () {
      forAll(integer(min: -300, max: 300), (offsetDays) {
        final now = DateTime(2026, 11, 22);
        final dueDate = now.add(Duration(days: offsetDays));

        final week = PregnancyCalculator.weekFromDueDate(
          dueDate: dueDate,
          currentDate: now,
        );

        expect(week, greaterThanOrEqualTo(4));
        expect(week, lessThanOrEqualTo(42));
      });
    });

    property('Gestational week never regresses over forward days', () {
      forAll(integer(min: 1, max: 280), (daysUntilDue) {
        final day1 = DateTime(2026, 11, 22);
        final day2 = day1.add(const Duration(days: 7));
        final dueDate = day1.add(Duration(days: daysUntilDue));

        final week1 = PregnancyCalculator.weekFromDueDate(
          dueDate: dueDate,
          currentDate: day1,
        );
        final week2 = PregnancyCalculator.weekFromDueDate(
          dueDate: dueDate,
          currentDate: day2,
        );

        expect(week2, greaterThanOrEqualTo(week1));
      });
    });
  });
}
