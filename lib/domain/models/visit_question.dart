import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'need.dart';

/// Where a saved question came from.
enum VisitOrigin {
  /// Typed by the parent, or a suggestion the parent changed into their
  /// own words.
  own,

  /// Picked from a week's chapter page; [VisitQuestion.week] says which week.
  week,

  /// Picked from a need's guide.
  guide,

  /// Picked from the fact card on Today.
  today,
}

/// One question the parent wants to bring to a visit, in full words.
///
/// [need] is set when the question came from a need's guide or Today's fact.
/// [origin] says where it came from; when it is not given, a question with a
/// need came from a guide and one without is the parent's own. [added] is
/// the day it went on the list (null for lists saved before it was kept).
@immutable
class VisitQuestion {
  const VisitQuestion(
    this.text, {
    this.need,
    VisitOrigin? origin,
    this.week,
    this.added,
  }) : origin = origin ?? (need == null ? VisitOrigin.own : VisitOrigin.guide);

  final String text;
  final MaternalNeed? need;
  final VisitOrigin origin;

  /// The pregnancy week the question was picked in, for [VisitOrigin.week].
  final int? week;

  /// The day the question was added, with no time of day.
  final DateTime? added;

  /// True for the parent's own words: typed, or a suggestion they changed.
  bool get isOwnWords => origin == VisitOrigin.own;

  /// The same question, now in the parent's own words.
  VisitQuestion inOwnWords(String words) =>
      VisitQuestion(words, origin: VisitOrigin.own, added: added);

  /// The parent's own words first, then the picked ones; each group keeps
  /// the order the questions were added.
  static List<VisitQuestion> ownFirst(Iterable<VisitQuestion> questions) => [
    ...questions.where((q) => q.isOwnWords),
    ...questions.where((q) => !q.isOwnWords),
  ];

  // Stored forms, all in one preferences list next to the topic names:
  //   current:   q2:{"t":text,"o":origin,"n":need,"w":week,"d":"yyyy-mm-dd"}
  //   earlier:   question:<text>            (typed, or picked from a week)
  //              question@<need>:<text>     (picked from a guide or Today)
  static const _current = 'q2:';
  static const _plain = 'question:';
  static const _tagged = 'question@';

  /// Stored next to the topic names in one preferences list.
  String encode() {
    final day = added;
    return '$_current${jsonEncode({'t': text, 'o': origin.name, if (need != null) 'n': need!.name, if (week != null) 'w': week, if (day != null) 'd': _day(day)})}';
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Returns null for topic names and for anything that is not a question.
  /// Reads every stored form this app has written, so an earlier list loads
  /// exactly as it was saved.
  static VisitQuestion? tryParse(String value) {
    if (value.startsWith(_current)) return _parseCurrent(value);
    if (value.startsWith(_plain)) {
      final text = value.substring(_plain.length).trim();
      return text.isEmpty ? null : VisitQuestion(text);
    }
    if (!value.startsWith(_tagged)) return null;
    final rest = value.substring(_tagged.length);
    final cut = rest.indexOf(':');
    if (cut < 0) return null;
    final text = rest.substring(cut + 1).trim();
    if (text.isEmpty) return null;
    final need = _need(rest.substring(0, cut));
    return VisitQuestion(text, need: need);
  }

  static VisitQuestion? _parseCurrent(String value) {
    Object? data;
    try {
      data = jsonDecode(value.substring(_current.length));
    } on FormatException {
      return null;
    }
    if (data is! Map) return null;
    final raw = data['t'];
    if (raw is! String || raw.trim().isEmpty) return null;
    final need = data['n'] is String ? _need(data['n'] as String) : null;
    VisitOrigin? origin;
    for (final o in VisitOrigin.values) {
      if (o.name == data['o']) origin = o;
    }
    final week = data['w'];
    final day = data['d'];
    final added = day is String ? DateTime.tryParse(day) : null;
    return VisitQuestion(
      raw.trim(),
      need: need,
      origin: origin,
      week: week is int ? week : null,
      added: added == null
          ? null
          : DateTime(added.year, added.month, added.day),
    );
  }

  static MaternalNeed? _need(String name) {
    for (final need in MaternalNeed.values) {
      if (need.name == name) return need;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is VisitQuestion &&
      other.text == text &&
      other.need == need &&
      other.origin == origin &&
      other.week == week &&
      other.added == added;

  @override
  int get hashCode => Object.hash(text, need, origin, week, added);

  @override
  String toString() =>
      'VisitQuestion($text, ${origin.name}, need: ${need?.name}, '
      'week: $week, added: $added)';
}
