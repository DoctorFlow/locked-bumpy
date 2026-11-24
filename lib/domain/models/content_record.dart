import 'dart:convert';

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

  /// Validates [record]. Throws [ContentGateException] on first violation.
  static void validate(ContentRecord record) {
    final issue = _reviewIssue(record);
    if (issue != null) throw ContentGateException(record, issue);
  }

  static bool canDisplay(ContentRecord record) => _reviewIssue(record) == null;

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

  static bool hasDatedReview(String reviewer, String date) {
    if (reviewer.trim().isEmpty || date.length != 10) return false;
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
