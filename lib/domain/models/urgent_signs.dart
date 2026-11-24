import 'dart:convert';
import 'content_record.dart';
import 'guide.dart';

/// The one shared list of urgent signs (`specs/GUIDE-CONTRACT.md`,
/// Amendment 2). Shown in full in card 5 of every guide and on its own page.
/// Built only through [review], so every field has passed the rules.
class UrgentSigns {
  const UrgentSigns({
    required this.isDraft,
    required this.lastChecked,
    required this.title,
    required this.intro,
    required this.signs,
    required this.action,
    required this.sources,
  });

  /// True when this list is visible only because this is a review build.
  final bool isDraft;

  /// `yyyy-MM-dd`.
  final String lastChecked;
  final String title, intro, action;
  final List<String> signs;
  final List<GuideSource> sources;

  /// Shown in place of the list when the gate hides it, so "When to call"
  /// is never empty. Fixed by the contract; not content.
  static const fallback =
      'If you are worried about yourself or your baby, call your doctor or '
      'midwife now. In an emergency, call emergency services.';

  static const recordId = 'urgent_signs';
  static const maxSignWords = 14;

  /// Reads the file's text. Returns the list the gate lets through, or null
  /// when it is hidden: not approved (outside a review build), a broken
  /// rule, an empty list, or an unreadable file. Never throws.
  static UrgentSigns? review(
    String json, {
    bool drafts = ContentGate.draftsByDefault,
  }) {
    try {
      final row = _recordOf(jsonDecode(json));
      if (row == null) return null;
      final status = row['status'];
      final reviewer = row['approved_by'] ?? '';
      final date = row['approved_date'] ?? '';
      if (status is! String || reviewer is! String || date is! String) {
        return null;
      }
      final verdict = ContentGate.review(
        status: status,
        reviewer: reviewer,
        date: date,
        rulesPass: ruleIssue(row) == null,
        drafts: drafts,
      );
      if (verdict == Review.hidden) return null;
      return UrgentSigns(
        isDraft: verdict == Review.draft,
        lastChecked: row['last_checked'] as String,
        title: (row['title'] as String).trim(),
        intro: (row['intro'] as String).trim(),
        signs: List.unmodifiable([
          for (final s in row['signs'] as List) (s as String).trim(),
        ]),
        action: (row['action'] as String).trim(),
        sources: List.unmodifiable([
          for (final s in row['sources'] as List)
            GuideSource(
              key: s['key'] as String,
              org: s['org'] as String,
              title: s['title'] as String,
              url: s['url'] as String,
            ),
        ]),
      );
    } catch (_) {
      return null;
    }
  }

  /// The file holds one record: the object itself, or an array of one.
  static Map<dynamic, dynamic>? _recordOf(Object? decoded) {
    if (decoded is Map) return decoded;
    if (decoded is List && decoded.length == 1 && decoded.single is Map) {
      return decoded.single as Map;
    }
    return null;
  }

  /// The first rule [row] breaks, or null when every field rule passes.
  /// Review status is not a rule here; [review] asks the gate.
  static String? ruleIssue(Map<dynamic, dynamic> row) {
    if (row['id'] != recordId) return 'id is not "$recordId"';
    final checked = row['last_checked'];
    if (checked is! String || !ContentGate.isCalendarDate(checked)) {
      return 'last_checked is not a date';
    }
    for (final field in ['title', 'intro', 'action']) {
      final v = row[field];
      if (v is! String || v.trim().isEmpty) return '$field is empty';
    }
    final signs = row['signs'];
    if (signs is! List || signs.isEmpty) return 'signs is empty';
    final seen = <String>{};
    for (var i = 0; i < signs.length; i++) {
      final s = signs[i];
      if (s is! String || s.trim().isEmpty) return 'sign ${i + 1} is empty';
      final words = s.trim().split(RegExp(r'\s+')).length;
      if (words > maxSignWords) {
        return 'sign ${i + 1} is over $maxSignWords words';
      }
      if (!seen.add(s.trim().toLowerCase())) return 'sign ${i + 1} repeats';
    }
    final sources = row['sources'];
    if (sources is! List || sources.isEmpty) return 'no sources';
    final keys = <String>{};
    for (final s in sources) {
      if (s is! Map) return 'a source is not a record';
      for (final field in ['key', 'org', 'title', 'url']) {
        final v = s[field];
        if (v is! String || v.trim().isEmpty) return 'a source has no $field';
      }
      if (!keys.add(s['key'] as String)) return 'two sources share a key';
    }
    return null;
  }
}
