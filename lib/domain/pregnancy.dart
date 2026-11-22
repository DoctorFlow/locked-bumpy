/// Gestational calculation domain logic.
///
/// Strictly covers weeks 4 through 42 according to project specs.
class PregnancyCalculator {
  /// Standard full-term pregnancy duration from LMP is 280 days (40 weeks).
  static const int fullTermDays = 280;

  /// Calculates gestational week (clamped between 4 and 42) from a Due Date and current date.
  static int weekFromDueDate({
    required DateTime dueDate,
    required DateTime currentDate,
  }) {
    final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final normalizedCurrent = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final daysRemaining = normalizedDue.difference(normalizedCurrent).inDays;
    final gestationalDays = fullTermDays - daysRemaining;
    final rawWeek = gestationalDays ~/ 7;

    return rawWeek.clamp(4, 42);
  }

  /// Calculates gestational week from Last Menstrual Period (LMP).
  static int weekFromLmp({
    required DateTime lmpDate,
    required DateTime currentDate,
  }) {
    final normalizedLmp = DateTime(lmpDate.year, lmpDate.month, lmpDate.day);
    final normalizedCurrent = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    final gestationalDays = normalizedCurrent.difference(normalizedLmp).inDays;
    final rawWeek = gestationalDays ~/ 7;

    return rawWeek.clamp(4, 42);
  }

  /// Human-readable week format
  static String formatWeekTitle(int week) {
    return 'Week $week';
  }
}
