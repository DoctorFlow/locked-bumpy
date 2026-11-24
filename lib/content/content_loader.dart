import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models/content_record.dart';
import '../domain/models/guide.dart';
import '../domain/models/need.dart';
import '../domain/models/week_card.dart';
import 'content_paths.dart';

/// Loads and validates content packs from bundled JSON assets.
///
/// All assets are offline (bundled with the app via `rootBundle`).
/// No network calls, no runtime AI. Results are cached after first load.
/// Every pack passes the one gate in [ContentGate.review]: approved rows
/// always, draft rows only in a review build.
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
    final records = ContentRecord.listFromJsonString(raw);
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
  }

  static List<WeekCard>? _weekCards;

  static Future<List<WeekCard>> loadWeekCards() async {
    final cached = _weekCards;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(ContentPaths.weekCards);
    return _weekCards = List.unmodifiable(WeekCard.listFromJsonString(raw));
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
