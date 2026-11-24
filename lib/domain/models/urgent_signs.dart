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
    this.groups = const [],
    this.footer,
  });

  /// True when this list is visible only because this is a review build.
  final bool isDraft;

  /// `yyyy-MM-dd`.
  final String lastChecked;
  final String title, intro, action;
  final List<String> signs;
  final List<GuideSource> sources;

  /// The signs in plain groups, most serious first (Amendment 3). Empty
  /// when the file has no `groups`: screens then show the flat [signs].
  /// When present, every sign is in exactly one group, in [signs] order.
  final List<UrgentGroup> groups;

  /// The closing line under the action, or null when the file has none.
  final String? footer;

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
      final groups = <UrgentGroup>[
        for (final g in (row['groups'] as List?) ?? const [])
          UrgentGroup(
            title: (g['title'] as String).trim(),
            signs: List.unmodifiable([
              for (final s in g['signs'] as List) (s as String).trim(),
            ]),
          ),
      ];
      final footer = (row['footer'] as String?)?.trim();
      return UrgentSigns(
        isDraft: verdict == Review.draft,
        lastChecked: row['last_checked'] as String,
        title: (row['title'] as String).trim(),
        intro: (row['intro'] as String).trim(),
        signs: List.unmodifiable([
          for (final s
              in (row['signs'] as List?) ??
                  [for (final g in groups) ...g.signs])
            (s as String).trim(),
        ]),
        groups: List.unmodifiable(groups),
        footer: footer == null || footer.isEmpty ? null : footer,
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
    // Amendment 3: optional groups, each with a title and at least one sign;
    // the flat list (when present too) equals the grouped signs in order.
    final grouped = row['groups'];
    final fromGroups = <Object?>[];
    if (grouped != null) {
      if (grouped is! List || grouped.isEmpty) return 'groups is empty';
      for (var g = 0; g < grouped.length; g++) {
        final group = grouped[g];
        if (group is! Map) return 'group ${g + 1} is not a record';
        final title = group['title'];
        if (title is! String || title.trim().isEmpty) {
          return 'group ${g + 1} has no title';
        }
        final inGroup = group['signs'];
        if (inGroup is! List || inGroup.isEmpty) {
          return 'group ${g + 1} has no signs';
        }
        fromGroups.addAll(inGroup);
      }
    }
    final footer = row['footer'];
    if (footer != null && (footer is! String || footer.trim().isEmpty)) {
      return 'footer is empty';
    }
    final signs = row['signs'] ?? (grouped == null ? null : fromGroups);
    if (signs is! List || signs.isEmpty) return 'signs is empty';
    if (grouped != null) {
      String norm(Object? s) => s is String ? s.trim() : '\u0000';
      if (signs.length != fromGroups.length) {
        return 'signs and groups do not match';
      }
      for (var i = 0; i < signs.length; i++) {
        if (norm(signs[i]) != norm(fromGroups[i])) {
          return 'signs and groups differ at sign ${i + 1}';
        }
      }
    }
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

/// One group of urgent signs under a plain title (Amendment 3).
class UrgentGroup {
  const UrgentGroup({required this.title, required this.signs});
  final String title;
  final List<String> signs;
}
