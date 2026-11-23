import 'package:flutter/foundation.dart';
import '../../core/services/prefs_service.dart';
import '../pregnancy.dart';
import 'need.dart';
import 'need_rotation.dart';

/// Central app state. Loaded from [PrefsService] at startup.
/// Preferences and check-ins are saved on-device. Dress-up lasts for the day
/// or until the app closes.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this._now)
    : _dueDate = _prefs.dueDate,
      _isHalloween = _prefs.isHalloween,
      _isPaused = _prefs.isPaused,
      _nickname = _prefs.nickname {
    _day = _now();
    _completedCheckIns = _prefs.loadTodayCheckIns(_day);
  }

  final PrefsService _prefs;
  final DateTime Function() _now;

  // ── Onboarding ───────────────────────────────────────────────────────────

  DateTime? _dueDate;
  DateTime? get dueDate => _dueDate;
  bool get isFirstRun => _dueDate == null;

  Future<void> saveDueDate(DateTime date) async {
    refreshDay();
    _dueDate = date;
    notifyListeners();
    await _prefs.saveDueDate(date);
  }

  // ── Nickname ─────────────────────────────────────────────────────────────

  String _nickname;

  /// The name the mother chose for the baby. Empty string = no nickname set.
  String get nickname => _nickname;

  /// Display name: nickname if set, otherwise 'Little Bumpy'.
  String get babyDisplayName => _nickname.isEmpty ? 'Little Bumpy' : _nickname;

  Future<void> saveNickname(String value) async {
    _nickname = value.trim();
    notifyListeners();
    await _prefs.saveNickname(_nickname);
  }

  // ── Mode ─────────────────────────────────────────────────────────────────

  bool _isHalloween;
  bool get isHalloween => _isHalloween;

  MaternalNeed? _costumeOverride;
  MaternalNeed? get costumeOverride => _costumeOverride;

  void setCostumeOverride(MaternalNeed? need) {
    if (refreshDay() || isFirstRun || isPaused || !isHalloween) return;
    final next = need == todayNeed ? null : need;
    if (next == _costumeOverride) return;
    _costumeOverride = next;
    notifyListeners();
  }

  Future<void> toggleMode() async {
    _isHalloween = !_isHalloween;
    notifyListeners();
    await _prefs.saveIsHalloween(_isHalloween);
  }

  // ── Pause ────────────────────────────────────────────────────────────────

  bool _isPaused;
  bool get isPaused => _isPaused;

  Future<void> togglePause() async {
    _isPaused = !_isPaused;
    if (!_isPaused) refreshDay();
    notifyListeners();
    await _prefs.saveIsPaused(_isPaused);
  }

  // ── Tab ──────────────────────────────────────────────────────────────────

  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  // ── Daily check-ins ──────────────────────────────────────────────────────

  late DateTime _day;
  DateTime get today => _day;

  int? get currentWeek => _dueDate == null
      ? null
      : PregnancyCalculator.weekFromDueDate(
          dueDate: _dueDate!,
          currentDate: today,
        );

  int get daysTogetherCount {
    if (_dueDate == null) return 0;
    final days = PregnancyCalculator.daysFromDueDate(
      dueDate: _dueDate!,
      currentDate: today,
    );
    return days < 0 ? 0 : days;
  }

  late Set<String> _completedCheckIns;
  Set<String> get completedCheckIns => Set.unmodifiable(_completedCheckIns);

  bool isChecked(String id) => _completedCheckIns.contains(id);

  MaternalNeed get todayNeed => NeedRotation.forDate(_day);

  List<MaternalNeed> get dailyCheckIns => NeedRotation.checkIns(todayNeed);

  /// True when all 3 check-ins are ticked.
  bool get allChecked => dailyCheckIns.every((need) => isChecked(need.name));

  bool refreshDay() {
    final now = _now();
    if (now.year == _day.year &&
        now.month == _day.month &&
        now.day == _day.day) {
      return false;
    }
    _day = now;
    _costumeOverride = null;
    _completedCheckIns = _prefs.loadTodayCheckIns(now);
    notifyListeners();
    return true;
  }

  Duration get timeToMidnight {
    final now = _now();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }

  Future<void> toggleCheckIn(String id) async {
    if (refreshDay() ||
        isPaused ||
        !dailyCheckIns.any((need) => need.name == id)) {
      return;
    }
    final next = Set<String>.from(_completedCheckIns);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    _completedCheckIns = next;
    notifyListeners(); // immediate — UI rebuilds before persistence completes
    await _prefs.saveTodayCheckIns(_day, _completedCheckIns);
  }

  /// Clears today's check-ins and unpauses. Used by Start Fresh.
  Future<void> clearTodayCheckIns() async {
    _day = _now();
    _completedCheckIns = {};
    _costumeOverride = null;
    _isPaused = false;
    _currentTab = 0;
    notifyListeners();
    await _prefs.saveTodayCheckIns(_day, {});
    await _prefs.saveIsPaused(false);
  }

  /// Wipes all data and returns the app to First Run. Used by Erase.
  Future<void> eraseAll() async {
    _dueDate = null;
    _nickname = '';
    _isHalloween = true;
    _isPaused = false;
    _currentTab = 0;
    _completedCheckIns = {};
    _costumeOverride = null;
    notifyListeners();
    await _prefs.clearAll();
  }

  // ── Factory ───────────────────────────────────────────────────────────────

  static Future<AppState> load({DateTime Function() now = DateTime.now}) async {
    final prefs = await PrefsService.create();
    return AppState._(prefs, now);
  }
}
