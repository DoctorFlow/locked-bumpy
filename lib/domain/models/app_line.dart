import 'dart:convert';
import 'content_record.dart';

/// One short app-voice line that lives in `assets/content/app_lines.json`
/// rather than in Dart, so it goes through the same review gate as every
/// other line a parent reads: shown when approved, shown with a Draft tag
/// only in a review build, hidden otherwise.
class AppLine {
  const AppLine({required this.id, required this.text, required this.isDraft});

  final String id;
  final String text;

  /// True when this line is visible only because this is a review build.
  final bool isDraft;
}

/// Reads `app_lines.json`: an array of
/// `{id, status, approved_by, approved_date, text}`.
class AppLines {
  AppLines._();

  static const assetPath = 'assets/content/app_lines.json';

  /// The kind line under "Everything is paused." that points to real support.
  static const pausedSupport = 'paused_support';

  /// The title of the urgent list's last quiet group: signs whose
  /// `from_week` is later than the parent's week.
  static const urgentLaterTitle = 'urgent_later_title';

  /// The Guides screen's heading over the topic guides.
  static const topicGuidesTitle = 'topic_guides_title';

  static const maxWords = 20;

  static final _appBanned = RegExp(
    r'\b(should|must|need to|have to|missed|forgot|failed|weight|diet|'
    r'lesson|learn|teach)\w*\b',
    caseSensitive: false,
  );

  /// The lines the gate lets through, by id. A broken row hides only itself;
  /// an unreadable file hides them all. Never throws.
  static Map<String, AppLine> review(String json, {bool? drafts}) {
    final out = <String, AppLine>{};
    try {
      final rows = jsonDecode(json);
      if (rows is! List) return out;
      for (final row in rows) {
        if (row is! Map) continue;
        final id = row['id'], text = row['text'], status = row['status'];
        final by = row['approved_by'] ?? '', date = row['approved_date'] ?? '';
        if (id is! String || text is! String || status is! String) continue;
        if (by is! String || date is! String) continue;
        final verdict = ContentGate.review(
          status: status,
          reviewer: by,
          date: date,
          rulesPass: ruleIssue(text) == null,
          drafts: drafts,
        );
        if (verdict == Review.hidden || out.containsKey(id)) continue;
        out[id] = AppLine(
          id: id,
          text: text.trim(),
          isDraft: verdict == Review.draft,
        );
      }
    } catch (_) {
      return const {};
    }
    return out;
  }

  /// The first word rule [text] breaks, or null.
  static String? ruleIssue(String text) {
    final t = text.trim();
    if (t.isEmpty) return 'empty';
    if (t.split(RegExp(r'\s+')).length > maxWords) {
      return 'over $maxWords words';
    }
    if (t.contains('—') || t.contains('–')) return 'a dash';
    if (RegExp(r'\d').hasMatch(t)) return 'a digit';
    final app = _appBanned.firstMatch(t);
    if (app != null) return 'uses "${app.group(1)}"';
    final banned = ContentGate.bannedTerm(t);
    if (banned != null) return 'uses "$banned"';
    if (RegExp(r'\bdoctors?\b', caseSensitive: false).hasMatch(t) &&
        !RegExp(r'\bdoctor or midwife\b', caseSensitive: false).hasMatch(t)) {
      return 'doctor without midwife';
    }
    return null;
  }
}
