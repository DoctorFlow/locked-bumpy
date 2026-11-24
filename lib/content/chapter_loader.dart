import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/models/chapter.dart';
import '../domain/models/content_record.dart';

/// Loads the storybook chapters from `assets/content/chapters.json`.
///
/// Each record is checked on its own: a broken record hides only that
/// chapter, and the weeks it would have covered show the plain weekly card.
class ChapterLoader {
  ChapterLoader._();

  static const String assetPath = 'assets/content/chapters.json';

  static List<Chapter>? _cache;

  /// Every well-formed record, whatever its review status. Never throws.
  static Future<List<Chapter>> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString(assetPath);
      return _cache = parse(raw);
    } catch (error) {
      debugPrint('Chapters not loaded: $error');
      return _cache = const [];
    }
  }

  /// Parses [raw]. Records that break the contract are left out and reported
  /// to [onRejected] (or the debug log) with the reason.
  static List<Chapter> parse(
    String raw, {
    void Function(String id, String reason)? onRejected,
  }) {
    final report =
        onRejected ??
        (id, reason) => debugPrint('Chapter "$id" hidden: $reason');
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      report('*', 'the file is not a list');
      return const [];
    }
    final chapters = <Chapter>[];
    for (final entry in decoded) {
      try {
        if (entry is! Map<String, dynamic>) {
          throw const ChapterFormatException('?', 'record is not an object');
        }
        chapters.add(Chapter.fromJson(entry));
      } on ChapterFormatException catch (error) {
        report(error.id, error.reason);
      } catch (error) {
        report('?', '$error');
      }
    }
    return List.unmodifiable(chapters);
  }

  /// Whether [chapter] may be shown to a parent in this build. The same
  /// three-outcome gate as Today lines, week cards and guides: `shown`
  /// always, `draft` only in a review build (with a Draft tag).
  static bool isVisible(Chapter chapter, {bool? drafts}) =>
      chapter.review(drafts: drafts) != Review.hidden;

  /// The visible chapter whose range holds [week], or null. An approved
  /// chapter wins over a draft for the same week.
  static Chapter? forWeek(List<Chapter> chapters, int week, {bool? drafts}) {
    Chapter? draft;
    for (final chapter in chapters) {
      if (!chapter.contains(week)) continue;
      switch (chapter.review(drafts: drafts)) {
        case Review.shown:
          return chapter;
        case Review.draft:
          draft ??= chapter;
        case Review.hidden:
          break;
      }
    }
    return draft;
  }

  /// Replaces the loaded chapters (tests), or clears them when null.
  @visibleForTesting
  static void debugUse(List<Chapter>? chapters) => _cache = chapters;
}
