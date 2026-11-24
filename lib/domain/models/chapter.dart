import 'dart:ui' show Color;

import 'content_record.dart';
import 'need.dart';

/// Thrown when one chapter record breaks the chapter contract. The loader
/// catches it and hides only that chapter.
class ChapterFormatException implements Exception {
  const ChapterFormatException(this.id, this.reason);

  final String id;
  final String reason;

  @override
  String toString() => 'ChapterFormatException: "$id" $reason';
}

/// One storybook chapter: a stretch of weeks with its own picture, colour
/// and title (specs/CHAPTER-CONTRACT.md, with Amendment 1).
///
/// Nothing here counts, scores or remembers that a chapter was read.
class Chapter {
  const Chapter({
    required this.id,
    required this.fromWeek,
    required this.toWeek,
    required this.status,
    required this.approvedBy,
    required this.approvedDate,
    required this.title,
    required this.accent,
    required this.illustration,
    required this.bumpyLine,
    required this.knowText,
    required this.knowSourceOrg,
    required this.knowSourceTitle,
    required this.knowUrl,
    required this.readyText,
    required this.suggestedQuestion,
    required this.lookForward,
    required this.curiousQuestion,
    required this.curiousNeed,
    this.curiousAnswerFact = '',
  });

  static const int bumpyLineWords = 20;
  static const int knowWords = 40;
  static const int readyWords = 30;
  static const int lookForwardWords = 30;

  final String id;
  final int fromWeek;
  final int toWeek;

  /// `'draft'` | `'needs_fix'` | `'approved'` | `'rejected'`
  final String status;
  final String approvedBy;
  final String approvedDate;

  final String title;
  final Color accent;

  /// Base name, e.g. `chapter-20`. See [illustrationPath].
  final String illustration;

  final String bumpyLine;
  final String knowText;
  final String knowSourceOrg;
  final String knowSourceTitle;
  final String knowUrl;
  final String readyText;

  /// Empty when the chapter offers no question for the visit list.
  final String suggestedQuestion;
  final String lookForward;
  final String curiousQuestion;
  final MaternalNeed curiousNeed;

  /// The id of the guide fact that answers [curiousQuestion] (Amendment 3),
  /// e.g. `water-f6`. Empty when the record names none; the guide then opens
  /// at its top. Never shown.
  final String curiousAnswerFact;

  /// Approved means a reviewer and a real review date are both written down.
  bool get isApproved =>
      status == 'approved' &&
      ContentGate.hasDatedReview(approvedBy, approvedDate);

  bool get isDraft => status == 'draft';

  /// The shared content gate's verdict ([ContentGate.review]). Every field
  /// rule was checked when the record was parsed, so only review status and
  /// the build decide: `shown`, `draft` (review build only) or `hidden`.
  Review review({bool? drafts}) => ContentGate.review(
    status: status,
    reviewer: approvedBy,
    date: approvedDate,
    rulesPass: true,
    drafts: drafts,
  );

  bool contains(int week) => week >= fromWeek && week <= toWeek;

  /// The picture for the current look. The page falls back to an accent
  /// paper panel with Bumpy when the file is not bundled.
  String illustrationPath({required bool halloween}) =>
      'assets/images/$illustration-${halloween ? 'halloween' : 'everyday'}.webp';

  static final RegExp _accent = RegExp(r'^#([0-9a-fA-F]{6})$');
  static final RegExp _baseName = RegExp(r'^[a-z0-9][a-z0-9-]*$');
  static final RegExp _digit = RegExp(r'[0-9]');

  /// Words that never reach a parent anywhere in a chapter (factory rule 4).
  static const List<String> _neverWords = [
    'missed',
    'kick',
    'floating',
    'potion',
  ];

  static int wordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Parses and validates one record. `art_brief` is read by the art maker
  /// only and is ignored here.
  factory Chapter.fromJson(Map<String, dynamic> j) {
    final id = j['id'] is String ? j['id'] as String : '?';
    Never broken(String reason) => throw ChapterFormatException(id, reason);

    String text(Map<String, dynamic> map, String key, {bool required = true}) {
      final value = map[key];
      if (value == null && !required) return '';
      if (value is! String) broken('$key is missing');
      final clean = value.trim();
      if (required && clean.isEmpty) broken('$key is empty');
      return clean;
    }

    Map<String, dynamic> block(String key) {
      final value = j[key];
      if (value is! Map<String, dynamic>) broken('$key is missing');
      return value;
    }

    int week(String key) {
      final value = j[key];
      if (value is! int) broken('$key is not a whole number');
      return value;
    }

    void limit(String key, String value, int words) {
      if (wordCount(value) > words) broken('$key is over $words words');
    }

    void question(String key, String value) {
      if (!value.endsWith('?')) broken('$key does not end with "?"');
    }

    if (id == '?' || id.trim().isEmpty) broken('id is missing');
    final fromWeek = week('from_week');
    final toWeek = week('to_week');
    if (fromWeek < 4 || toWeek > 42 || fromWeek > toWeek) {
      broken('week range $fromWeek to $toWeek is outside 4 to 42');
    }

    final accentMatch = _accent.firstMatch(text(j, 'accent'));
    if (accentMatch == null) broken('accent is not a #RRGGBB colour');
    final accent = Color(0xFF000000 | int.parse(accentMatch[1]!, radix: 16));

    final illustration = text(j, 'illustration');
    if (!_baseName.hasMatch(illustration)) {
      broken('illustration must be a base name such as chapter-20');
    }

    final bumpyLine = text(j, 'bumpy_line');
    limit('bumpy_line', bumpyLine, bumpyLineWords);
    final banned = ContentGate.bannedTerm(bumpyLine);
    if (banned != null) broken('bumpy_line uses "$banned"');

    final know = block('know');
    final knowText = text(know, 'text');
    limit('know.text', knowText, knowWords);
    if (_digit.hasMatch(knowText)) broken('know.text contains a digit');
    final sourceOrg = text(know, 'source_org');
    final url = text(know, 'url');
    if (!url.startsWith('https://')) broken('know.url is not https');

    final ready = block('ready');
    final readyText = text(ready, 'text');
    limit('ready.text', readyText, readyWords);
    final suggested = text(ready, 'suggested_question', required: false);
    if (suggested.isNotEmpty) question('ready.suggested_question', suggested);

    final lookForward = text(block('look_forward'), 'text');
    limit('look_forward.text', lookForward, lookForwardWords);

    final curious = block('curious');
    final curiousQuestion = text(curious, 'question');
    question('curious.question', curiousQuestion);
    final needName = text(curious, 'need');
    final need = MaternalNeed.values
        .where((n) => n.needName == needName)
        .firstOrNull;
    if (need == null) broken('curious.need "$needName" is not a need');
    // Only a pointer: a wrong or unknown id simply opens the guide at its
    // top, so it never hides the chapter.
    final answerFact = curious['answer_fact'] is String
        ? (curious['answer_fact'] as String).trim()
        : '';

    final title = text(j, 'title');
    for (final shown in [
      title,
      bumpyLine,
      knowText,
      readyText,
      suggested,
      lookForward,
      curiousQuestion,
    ]) {
      final lower = shown.toLowerCase();
      for (final word in _neverWords) {
        if (RegExp('\\b$word').hasMatch(lower)) broken('uses "$word"');
      }
    }

    return Chapter(
      id: id,
      fromWeek: fromWeek,
      toWeek: toWeek,
      status: text(j, 'status'),
      approvedBy: text(j, 'approved_by', required: false),
      approvedDate: text(j, 'approved_date', required: false),
      title: title,
      accent: accent,
      illustration: illustration,
      bumpyLine: bumpyLine,
      knowText: knowText,
      knowSourceOrg: sourceOrg,
      knowSourceTitle: text(know, 'source_title', required: false),
      knowUrl: url,
      readyText: readyText,
      suggestedQuestion: suggested,
      lookForward: lookForward,
      curiousQuestion: curiousQuestion,
      curiousNeed: need,
      curiousAnswerFact: answerFact,
    );
  }
}
