import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models/app_line.dart';
import '../domain/models/content_record.dart';
import '../domain/models/guide.dart';
import '../domain/models/held_list.dart';
import '../domain/models/need.dart';
import '../domain/models/week_card.dart';
import 'content_paths.dart';

/// Loads and validates content packs from bundled JSON assets.
///
/// All assets are offline (bundled with the app via `rootBundle`).
/// No network calls, no runtime AI. Results are cached after first load.
/// Every pack passes the one gate in [ContentGate.review]: approved rows
/// always, draft rows only in a review build. A record named in
/// `assets/content/held.json` is marked held and so counts as a draft.
class ContentLoader {
  ContentLoader._();

  static final Map<String, List<ContentRecord>> _cache = {};

  /// Loads the records in [assetPath] (e.g. `'assets/content/today_lines.json'`)
  /// that the gate lets through, approved rows first so a draft can never
  /// take the place of an approved line. Returns cached result on
  /// subsequent calls.
  static Future<List<ContentRecord>> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath]!;
    final raw = await rootBundle.loadString(assetPath);
    final held = await loadHeld();
    final records = [
      for (final r in ContentRecord.listFromJsonString(raw))
        r.withHold(held.holds(assetPath, r.id)),
    ];
    final validated = List<ContentRecord>.unmodifiable([
      ...records.where((r) => ContentGate.reviewRecord(r) == Review.shown),
      ...records.where((r) => ContentGate.reviewRecord(r) == Review.draft),
    ]);
    _cache[assetPath] = validated;
    return validated;
  }

  /// Clears the in-memory cache. Used in tests only.
  static void clearCache() {
    _cache.clear();
    _weekCards = null;
    _guides = null;
    _held = null;
    _appLines = null;
  }

  // A value, not a Future, for the same reason as the hold list below.
  static Map<String, AppLine>? _appLines;

  /// The short app-voice lines in `app_lines.json` that the gate lets
  /// through, by id. A missing or broken file shows none of them.
  static Future<Map<String, AppLine>> loadAppLines() async =>
      _appLines ??= await _readAppLines();

  static Future<Map<String, AppLine>> _readAppLines() async {
    try {
      return AppLines.review(await rootBundle.loadString(AppLines.assetPath));
    } catch (_) {
      return const {};
    }
  }

  /// The app lines already loaded, or null before the first [loadAppLines]
  /// finishes: lets a screen draw them on its first frame.
  static Map<String, AppLine>? get loadedAppLines => _appLines;

  /// Replaces the loaded app lines (null reads the file again). Tests only.
  @visibleForTesting
  static void debugSetAppLines(Map<String, AppLine>? lines) =>
      _appLines = lines;

  // The value, not a Future: a Future completed in one zone can stall an
  // await in another (a widget test's fake clock).
  static HeldList? _held;

  /// The records held back for the physician's re-check. A missing or
  /// broken `held.json` holds nothing at run time; the content tests fail
  /// loudly on it instead.
  static Future<HeldList> loadHeld() async => _held ??= await _readHeld();

  static Future<HeldList> _readHeld() async {
    try {
      return HeldList.parse(await rootBundle.loadString(HeldList.assetPath));
    } catch (_) {
      return HeldList.empty;
    }
  }

  /// Replaces the hold list (null reads the asset again) and drops the
  /// loaded Today lines and week cards so the next load applies it. Tests
  /// only.
  @visibleForTesting
  static void debugSetHeld(HeldList? held) {
    _held = held;
    _cache.clear();
    _weekCards = null;
  }

  static List<WeekCard>? _weekCards;

  static Future<List<WeekCard>> loadWeekCards() async {
    final cached = _weekCards;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(ContentPaths.weekCards);
    final held = await loadHeld();
    return _weekCards = List.unmodifiable([
      for (final c in WeekCard.listFromJsonString(raw))
        c.withHold(held.holds(ContentPaths.weekCards, c.id)),
    ]);
  }

  static Future<Map<MaternalNeed, Guide>>? _guides;

  /// The guides the gate lets through, one per need at most. A broken
  /// record hides only its own guide; an unreadable file hides all six.
  static Future<Map<MaternalNeed, Guide>> loadGuides() =>
      _guides ??= _readGuides();

  /// Replaces the loaded guides with [guides] (null clears). Tests only.
  @visibleForTesting
  static void debugSetGuides(Map<MaternalNeed, Guide>? guides) =>
      _guides = guides == null ? null : Future.value(guides);

  static Future<Map<MaternalNeed, Guide>> _readGuides() async {
    try {
      final raw = await rootBundle.loadString(ContentPaths.guides);
      return Guide.reviewAll(raw);
    } catch (_) {
      return const {};
    }
  }

  // ── Query helpers ─────────────────────────────────────────────────────────

  /// Finds the first record matching [need], [category], and [mode].
  /// [load] puts approved records first, so they win over drafts.
  ///
  /// Mode matching: a record with `mode == 'both'` matches any [mode] value.
  /// Returns `null` if no match is found.
  static ContentRecord? find({
    required List<ContentRecord> records,
    required String need,
    required String category,
    required String mode, // 'everyday' | 'halloween'
  }) {
    for (final r in records) {
      if (r.need != need) continue;
      if (r.category != category) continue;
      if (r.mode != 'both' && r.mode != mode) continue;
      return r;
    }
    return null;
  }

  /// Like [find] but throws [StateError] when no matching record exists.
  static ContentRecord require({
    required List<ContentRecord> records,
    required String need,
    required String category,
    required String mode,
  }) {
    final r = find(
      records: records,
      need: need,
      category: category,
      mode: mode,
    );
    if (r == null) {
      throw StateError(
        'No approved content record for need=$need '
        'category=$category mode=$mode',
      );
    }
    return r;
  }
}
