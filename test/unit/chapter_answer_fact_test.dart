import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/chapter.dart';

import '../chapter_fixtures.dart';

/// Every shipped chapter that names the fact answering its curious question
/// names one that exists in that need's guide (CHAPTER-CONTRACT Amendment 3).
void main() {
  test('shipped answer_fact pointers name a fact in the linked guide', () {
    final chapters =
        jsonDecode(File('assets/content/chapters.json').readAsStringSync())
            as List<dynamic>;
    final guides =
        jsonDecode(File('assets/content/guides.json').readAsStringSync())
            as List<dynamic>;
    final factsByNeed = {
      for (final g in guides.cast<Map<String, dynamic>>())
        g['need'] as String: {
          for (final f in (g['facts'] as List).cast<Map<String, dynamic>>())
            f['id'] as String,
        },
    };
    var pointers = 0;
    for (final c in chapters.cast<Map<String, dynamic>>()) {
      final curious = c['curious'] as Map<String, dynamic>;
      final answer = curious['answer_fact'];
      if (answer == null) continue;
      pointers++;
      expect(
        factsByNeed[curious['need']],
        contains(answer),
        reason: '${c['id']} points at $answer',
      );
      expect(Chapter.fromJson(c).curiousAnswerFact, answer);
    }
    expect(pointers, greaterThan(0));
  });

  test('a record without answer_fact parses with an empty pointer', () {
    expect(Chapter.fromJson(chapterRecord()).curiousAnswerFact, '');
  });
}
