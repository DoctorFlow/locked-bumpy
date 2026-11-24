/// Gestational calculation domain logic.
///
/// Strictly covers weeks 4 through 42 according to project specs.
class PregnancyCalculator {
  /// Standard full-term pregnancy duration from LMP is 280 days (40 weeks).
  static const int fullTermDays = 280;

  /// Two calendar dates can be 23 or 25 hours apart at local midnight.
  static DateTime _civilDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  static int daysFromDueDate({
    required DateTime dueDate,
    required DateTime currentDate,
  }) =>
      fullTermDays +
      _civilDate(currentDate).difference(_civilDate(dueDate)).inDays;

  static DateTime dueDateFromLmp(DateTime lmp) =>
      DateTime(lmp.year, lmp.month, lmp.day + fullTermDays);

  static int weekFromDueDate({
    required DateTime dueDate,
    required DateTime currentDate,
  }) => (daysFromDueDate(dueDate: dueDate, currentDate: currentDate) ~/ 7)
      .clamp(4, 42);

  /// The due date that [weekFromDueDate] turns back into [week] on
  /// [currentDate]: the first day of that week (day 0), so the week holds
  /// for the next six days and then moves on as any other date would.
  /// [week] is kept within 4 to 42, like every week the app shows.
  static DateTime dueDateForWeek({
    required int week,
    required DateTime currentDate,
  }) {
    final w = week.clamp(4, 42);
    return DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day + fullTermDays - 7 * w,
    );
  }

  static int weekFromLmp({
    required DateTime lmpDate,
    required DateTime currentDate,
  }) => weekFromDueDate(
    dueDate: dueDateFromLmp(lmpDate),
    currentDate: currentDate,
  );

  /// Human-readable week format
  static String formatWeekTitle(int week) {
    return 'Week $week';
  }
}
