import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../../core/build_flags.dart';

/// The three outcomes of the content gate.
enum Review { shown, draft, hidden }

/// A single baby-voice or app-voice content line, loaded from a JSON bundle.
///
/// Every field is required. The [ContentGate] validates this record before
/// it is ever returned to any widget.
class ContentRecord {
  const ContentRecord({
    required this.id,
    required this.category,
    required this.need,
    required this.mode,
    required this.tone,
    required this.text,
    required this.status,
    required this.approvedBy,
    required this.approvedDate,
  });

  /// Unique identifier, e.g. `'iron_greeting_hw_01'`.
  final String id;

  /// `'greeting'` | `'thank_you'` | `'goodbye'`
  final String category;

  /// `'IRON'` | `'BRAIN'` | `'BONES'` | `'WATER'` | `'REST'` | `'VITAMIN'` | `'ALL'`
  final String need;

  /// `'everyday'` | `'halloween'` | `'both'`
  final String mode;

  /// `'gentle'` | `'cheeky'` | `'both'`
  final String tone;

  /// The displayed text. Must pass the content gate.
  final String text;

  /// `'draft'` | `'needs_fix'` | `'approved'` | `'rejected'`
  final String status;

  final String approvedBy;
  final String approvedDate;

  /// True for a record that passed the gate only as a review-build draft.
  bool get isDraft => status != 'approved';

  factory ContentRecord.fromJson(Map<String, dynamic> j) => ContentRecord(
    id: j['id'] as String,
    category: j['category'] as String,
    need: j['need'] as String,
    mode: j['mode'] as String,
    tone: j['tone'] as String,
    text: j['text'] as String,
    status: j['status'] as String,
    approvedBy: j['approved_by'] as String? ?? '',
    approvedDate: j['approved_date'] as String? ?? '',
  );

  static List<ContentRecord> listFromJsonString(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ContentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Thrown when a [ContentRecord] fails gate validation.
class ContentGateException implements Exception {
  const ContentGateException(this.record, this.reason);

  final ContentRecord record;
  final String reason;

  @override
  String toString() => 'ContentGateException: record "${record.id}" — $reason';
}

/// Validates a single [ContentRecord].
///
/// Throws [ContentGateException] if:
/// - `status != 'approved'`
/// - `text` contains any word from the banned list
class ContentGate {
  ContentGate._();

  // Full banned-word list from voice.md steering.
  static const List<String> _banned = [
    'forgot',
    'missed',
    'should',
    'must',
    'sad',
    'let down',
    'wrong',
    'lazy',
    'streak',
    'failed',
    'risk',
    'danger',
    'harm',
    'if you don\'t',
    'kick',
    'kicked',
    'kick counter',
    'move',
    'moving',
    'roll',
    'wriggle',
    'hear',
    'hearing',
    'felt',
    'tickle',
    'death',
    'died',
    'dying',
    'dead',
    'blood',
    'decay',
    'grave',
    'bite',
    'biting',
    'undead',
    'zombie brains',
    'floating',
    'fading',
    'gone',
    'potion',
    'spell',
    'witch brew',
    'partner',
    'husband',
    'father',
    'weight',
    'shape',
    'bump size',
    'stretch marks',
    'cravings',
  ];

  /// Whether drafts may be shown, unless a caller says otherwise. Only true in
  /// a review build (see `build_flags.dart`); tests pass `drafts:` instead.
  static const bool draftsByDefault = kReviewBuild;

  /// Widget tests set this to act as a review build (true) or a release
  /// (false) for every kind of content at once; null means the build flag.
  @visibleForTesting
  static bool? debugDrafts;

  /// Whether this build shows drafts: the one switch for Today lines, week
  /// cards, chapters and guides when a caller does not pass `drafts:`.
  static bool get showsDrafts => debugDrafts ?? draftsByDefault;

  /// The one content gate for Today lines, week cards, chapters and guides.
  ///
  /// - [Review.shown]: approved, with a non-empty reviewer and a real date,
  ///   and [rulesPass].
  /// - [Review.draft]: status `draft`, [rulesPass], and [drafts] is true
  ///   (a review build; [showsDrafts] when not given).
  /// - [Review.hidden]: everything else, including approved rows that break
  ///   a rule.
  static Review review({
    required String status,
    required String reviewer,
    required String date,
    required bool rulesPass,
    bool? drafts,
  }) {
    if (!rulesPass) return Review.hidden;
    if (status == 'approved') {
      return hasDatedReview(reviewer, date) ? Review.shown : Review.hidden;
    }
    if ((drafts ?? showsDrafts) && status == 'draft') return Review.draft;
    return Review.hidden;
  }

  /// [review] for one Today line.
  static Review reviewRecord(ContentRecord record, {bool? drafts}) => review(
    status: record.status,
    reviewer: record.approvedBy,
    date: record.approvedDate,
    rulesPass: record.text.trim().isNotEmpty && bannedTerm(record.text) == null,
    drafts: drafts,
  );

  /// Validates [record]. Throws [ContentGateException] on first violation.
  static void validate(ContentRecord record) {
    final issue = _reviewIssue(record);
    if (issue != null) throw ContentGateException(record, issue);
  }

  /// True only for a record a parent may see in a release build.
  static bool canDisplay(ContentRecord record) =>
      reviewRecord(record, drafts: false) == Review.shown;

  static String? _reviewIssue(ContentRecord record) {
    if (record.status != 'approved') {
      return 'status is "${record.status}", expected "approved"';
    }
    if (!hasDatedReview(record.approvedBy, record.approvedDate)) {
      return 'missing reviewer or invalid review date';
    }
    final banned = bannedTerm(record.text);
    return banned == null ? null : 'text contains banned term "$banned"';
  }

  /// Approved needs a non-empty reviewer and a real `yyyy-MM-dd` date.
  static bool hasDatedReview(String reviewer, String date) =>
      reviewer.trim().isNotEmpty && isCalendarDate(date);

  /// True for a real `yyyy-MM-dd` date (2024-02-29 yes, 2025-02-29 no).
  static bool isCalendarDate(String date) {
    if (date.length != 10) return false;
    final parsed = DateTime.tryParse('${date}T00:00:00Z');
    return parsed != null && parsed.toIso8601String().split('T').first == date;
  }

  /// One pattern per banned entry. Each entry matches as a whole word or
  /// phrase, case-insensitive, so "hear" blocks "hears" but not "heart", and
  /// "move" blocks "moved" but not "remove". Simple endings (-s, -es, -d,
  /// -ed, -ing) are still blocked. Spaces in a phrase match any whitespace.
  static final List<(String, RegExp)> _bannedPatterns = [
    for (final term in _banned)
      (
        term,
        RegExp(
          r'\b' +
              term.split(' ').map(RegExp.escape).join(r'\s+') +
              r'(?:s|es|d|ed|ing)?\b',
          caseSensitive: false,
        ),
      ),
  ];

  /// Returns the first banned entry found in [text], or null when clean.
  static String? bannedTerm(String text) {
    for (final (term, pattern) in _bannedPatterns) {
      if (pattern.hasMatch(text)) return term;
    }
    return null;
  }

  /// Validates all [records]. Returns them unchanged if all pass.
  /// Throws [ContentGateException] on the first failure.
  static List<ContentRecord> validateAll(List<ContentRecord> records) {
    for (final r in records) {
      validate(r);
    }
    return records;
  }
}
