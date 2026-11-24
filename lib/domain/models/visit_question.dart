import 'package:flutter/foundation.dart';
import 'need.dart';

/// One question the parent wants to bring to a visit, in full words.
/// [need] is set when the question came from a need's guide.
@immutable
class VisitQuestion {
  const VisitQuestion(this.text, {this.need});

  final String text;
  final MaternalNeed? need;

  static const _plain = 'question:';
  static const _tagged = 'question@';

  /// Stored next to the topic names in one preferences list.
  String encode() =>
      need == null ? '$_plain$text' : '$_tagged${need!.name}:$text';

  /// Returns null for topic names and for anything that is not a question.
  static VisitQuestion? tryParse(String value) {
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
    final name = rest.substring(0, cut);
    for (final need in MaternalNeed.values) {
      if (need.name == name) return VisitQuestion(text, need: need);
    }
    return VisitQuestion(text);
  }

  @override
  bool operator ==(Object other) =>
      other is VisitQuestion && other.text == text && other.need == need;

  @override
  int get hashCode => Object.hash(text, need);
}
