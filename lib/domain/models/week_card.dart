import 'dart:convert';
import 'content_record.dart';

/// One baby-voice card for a gestational week.
class WeekCard {
  const WeekCard({
    required this.week,
    required this.mode,
    required this.babyLine,
    this.sizeObject,
    required this.status,
    required this.approvedBy,
    required this.approvedDate,
  });

  /// Gestational week number (4–42).
  final int week;

  /// `'everyday'` | `'halloween'` | `'both'`
  final String mode;

  /// 1–2 sentences, baby voice, ~20 words max.
  final String babyLine;

  /// Everyday-object size comparison (e.g. `'blueberry'`).
  /// Null until Karan approves a size line for this week.
  final String? sizeObject;

  /// `'approved'` | `'draft'`
  final String status;

  final String approvedBy;
  final String approvedDate;

  factory WeekCard.fromJson(Map<String, dynamic> j) => WeekCard(
    week: j['week'] as int,
    mode: j['mode'] as String,
    babyLine: j['baby_line'] as String,
    sizeObject: j['size_object'] as String?,
    status: j['status'] as String,
    approvedBy: j['approved_by'] as String? ?? '',
    approvedDate: j['approved_date'] as String? ?? '',
  );

  static List<WeekCard> listFromJsonString(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WeekCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// True for a card that passed the gate only as a review-build draft.
  bool get isDraft => status != 'approved';

  /// The content gate's verdict for this card.
  Review review({bool drafts = ContentGate.draftsByDefault}) =>
      ContentGate.review(
        status: status,
        reviewer: approvedBy,
        date: approvedDate,
        rulesPass:
            babyLine.trim().isNotEmpty &&
            ContentGate.bannedTerm(babyLine) == null &&
            ContentGate.bannedTerm(sizeObject ?? '') == null,
        drafts: drafts,
      );

  /// Returns the first shown card for [week] matching [mode]; in a review
  /// build, a draft card only when no approved card exists for that week.
  /// Cards with `mode == 'both'` match any palette mode.
  static WeekCard? findFor({
    required List<WeekCard> cards,
    required int week,
    required String mode,
    bool drafts = ContentGate.draftsByDefault,
  }) {
    WeekCard? draft;
    for (final c in cards) {
      if (c.week != week) continue;
      if (c.mode != 'both' && c.mode != mode) continue;
      switch (c.review(drafts: drafts)) {
        case Review.shown:
          return c;
        case Review.draft:
          draft ??= c;
        case Review.hidden:
          break;
      }
    }
    return draft;
  }
}
