/// App-wide compile-time constants.
/// No magic strings outside this file.
class AppConstants {
  AppConstants._();

  // ── SharedPreferences keys ──────────────────────────────────────────────
  static const String prefsDueDateKey = 'due_date_iso';
  static const String prefsIsHalloweenKey = 'is_halloween';
  static const String prefsIsPausedKey = 'is_paused';

  /// ISO date string (yyyy-MM-dd) of the last day check-ins were saved.
  static const String prefsCheckInDateKey = 'checkin_date';

  /// Comma-separated completed check-in IDs for today.
  static const String prefsCheckInIdsKey = 'checkin_ids';

  // ── Gestational bounds ──────────────────────────────────────────────────
  static const int minWeek = 4;
  static const int maxWeek = 42;
  static const int fullTermDays = 280; // LMP + 280 days = due date

  // ── Medical disclaimer ──────────────────────────────────────────────────
  static const String disclaimer =
      'This app is not medical advice. '
      'If you are worried about anything, call your doctor.';

  // ── Check-in IDs ────────────────────────────────────────────────────────
  static const String checkInNeed = 'need_of_the_day';
  static const String checkInWater = 'water';
  static const String checkInVitamin = 'vitamin';

  // ── Need rotation epoch ─────────────────────────────────────────────────
  /// Monday 2026-11-23 is day 0 of the rotation (IRON).
  static final DateTime rotationEpoch = DateTime(2026, 11, 23);
}
