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
    this.isHeld = false,
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

  /// True when `assets/content/held.json` holds this card back for the
  /// physician's re-check: the gate then treats it as a draft, whatever its
  /// stamp says. Set by the loader, never read from the card itself.
  final bool isHeld;

  /// The card's id in `held.json` and the review sheet: `week-<n>`, or
  /// `week-<n>-<mode>` for a card made for one look only.
  String get id => mode == 'both' ? 'week-$week' : 'week-$week-$mode';

  /// This card with [held] as its hold. The stamp is left as it is.
  WeekCard withHold(bool held) => held == isHeld
      ? this
      : WeekCard(
          week: week,
          mode: mode,
          babyLine: babyLine,
          sizeObject: sizeObject,
          status: status,
          approvedBy: approvedBy,
          approvedDate: approvedDate,
          isHeld: held,
        );

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

  /// True for a card that passed the gate only as a review-build draft
  /// (a held card included).
  bool get isDraft => status != 'approved' || isHeld;

  /// The content gate's verdict for this card.
  Review review({bool? drafts}) => ContentGate.review(
    status: isHeld ? 'draft' : status,
    reviewer: approvedBy,
    date: approvedDate,
    rulesPass:
        babyLine.trim().isNotEmpty &&
        ContentGate.bannedTerm(babyLine) == null &&
        ContentGate.bannedTerm(sizeObject ?? '') == null,
    drafts: drafts,
  );

  /// Returns the first shown card for [week] matching [mode]; in a review
  /// build, a draft (or held) card only when no approved card exists for
  /// that week. A normal build returns null for a week whose only card is
  /// held, the same as a week with no approved card.
  /// Cards with `mode == 'both'` match any palette mode.
  static WeekCard? findFor({
    required List<WeekCard> cards,
    required int week,
    required String mode,
    bool? drafts,
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
