import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import '../../domain/models/need_rotation.dart';

/// Thin wrapper around [SharedPreferences].
/// All data stays on-device — zero network calls, zero serialisation to any
/// remote destination.
class PrefsService {
  PrefsService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService._(prefs);
  }

  // ── Due date ─────────────────────────────────────────────────────────────

  DateTime? get dueDate {
    final raw = _prefs.getString(AppConstants.prefsDueDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveDueDate(DateTime date) =>
      _prefs.setString(AppConstants.prefsDueDateKey, _isoDate(date));

  // ── Mode & pause ─────────────────────────────────────────────────────────

  SkinTone get skinTone =>
      SkinTone.fromPreference(_prefs.getString(AppConstants.prefsSkinToneKey));

  Future<void> saveSkinTone(SkinTone tone) =>
      _prefs.setString(AppConstants.prefsSkinToneKey, tone.name);

  bool get isHalloween =>
      _prefs.getBool(AppConstants.prefsIsHalloweenKey) ?? true;

  Future<void> saveIsHalloween(bool value) =>
      _prefs.setBool(AppConstants.prefsIsHalloweenKey, value);

  bool get isPaused => _prefs.getBool(AppConstants.prefsIsPausedKey) ?? false;

  Future<void> saveIsPaused(bool value) =>
      _prefs.setBool(AppConstants.prefsIsPausedKey, value);

  // ── Nickname ─────────────────────────────────────────────────────────────

  /// Empty string means the mother hasn't set a nickname.
  String get nickname => _prefs.getString(AppConstants.prefsNicknameKey) ?? '';

  Future<void> saveNickname(String value) =>
      _prefs.setString(AppConstants.prefsNicknameKey, value.trim());

  // ── Daily check-ins ──────────────────────────────────────────────────────

  /// Returns the saved check-in IDs for today; clears them if the saved date
  /// is before today (a new day started).
  Set<String> loadTodayCheckIns(DateTime date) {
    final today = _isoDate(date);
    final current = _prefs.getStringList(AppConstants.prefsDailyNeedsKey);
    if (current != null) {
      return current.isNotEmpty && current.first == today
          ? current.skip(1).toSet()
          : {};
    }
    // Earlier builds saved tile positions. Decode what those tiles actually
    // said: on Water and Rest days two old tiles could mean the same thing.
    final savedDate = _prefs.getString(AppConstants.prefsCheckInDateKey);
    if (savedDate != today) return {};
    final slots = (_prefs.getString(AppConstants.prefsCheckInIdsKey) ?? '')
        .split(',');
    final need = NeedRotation.forDate(date);
    return {
      if (slots.contains(AppConstants.checkInNeed)) need.name,
      if (slots.contains(AppConstants.checkInWater)) MaternalNeed.water.name,
      if (slots.contains(AppConstants.checkInVitamin))
        NeedRotation.thirdCheckIn(need) == MaternalNeed.rest
            ? MaternalNeed.rest.name
            : MaternalNeed.vitamin.name,
    };
  }

  Future<void> saveTodayCheckIns(DateTime date, Set<String> ids) async {
    await _prefs.setStringList(AppConstants.prefsDailyNeedsKey, [
      _isoDate(date),
      ...ids,
    ]);
  }

  // ── Nuclear erase ────────────────────────────────────────────────────────

  /// Clears Little Bumpy's current and legacy keys on this device.
  Future<void> clearAll() async {
    const ownedKeys = [
      AppConstants.prefsDueDateKey,
      AppConstants.prefsSkinToneKey,
      AppConstants.prefsIsHalloweenKey,
      AppConstants.prefsIsPausedKey,
      AppConstants.prefsNicknameKey,
      AppConstants.prefsDailyNeedsKey,
      AppConstants.prefsCheckInDateKey,
      AppConstants.prefsCheckInIdsKey,
    ];
    await Future.wait([
      for (final key in ownedKeys)
        if (_prefs.containsKey(key)) _prefs.remove(key),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
