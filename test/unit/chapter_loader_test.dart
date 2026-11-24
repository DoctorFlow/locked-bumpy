import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/domain/models/need.dart';

import '../chapter_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<String> rejected(Map<String, dynamic> record) {
    final reasons = <String>[];
    final kept = ChapterLoader.parse(
      chapterJson([record]),
      onRejected: (_, reason) => reasons.add(reason),
    );
    expect(kept.isEmpty, reasons.isNotEmpty);
    return reasons;
  }

  test('a good record parses every contract field', () {
    final chapters = ChapterLoader.parse(chapterJson([chapterRecord()]));
    expect(chapters, hasLength(1));
    final c = chapters.single;
    expect(c.id, 'chapter_16');
    expect((c.fromWeek, c.toWeek), (16, 19));
    expect(c.accent, const Color(0xFF7FB3A0));
    expect(c.knowSourceOrg, 'Test Kite Club');
    expect(c.curiousNeed, MaternalNeed.rest);
    expect(c.isApproved, isTrue);
    expect(
      c.illustrationPath(halloween: true),
      'assets/images/chapter-test-halloween.webp',
    );
    expect(
      c.illustrationPath(halloween: false),
      'assets/images/chapter-test-everyday.webp',
    );
  });

  test('each broken field hides only its own chapter', () {
    final broken = [
      chapterRecord(bumpyLine: List.filled(21, 'paper').join(' ')),
      chapterRecord(knowText: List.filled(41, 'kite').join(' ')),
      chapterRecord(readyText: List.filled(31, 'ribbon').join(' ')),
      chapterRecord(lookForward: List.filled(31, 'picnic').join(' ')),
      chapterRecord(sourceOrg: ''),
      chapterRecord(url: ''),
      chapterRecord(knowText: 'Kites fly best at 3 in the afternoon.'),
      chapterRecord(suggested: 'Which ribbon is brightest'),
      chapterRecord(curious: 'Kite strings can be long'),
      chapterRecord(accent: 'teal'),
      chapterRecord(accent: '#12345'),
      chapterRecord(need: 'KITES'),
      chapterRecord(illustration: 'assets/images/chapter-16.webp'),
      chapterRecord(from: 20, to: 18),
      chapterRecord(from: 40, to: 43),
      chapterRecord(bumpyLine: 'I should fold a kite.'),
      chapterRecord(lookForward: 'Paper boats floating by.'),
    ];
    for (final record in broken) {
      expect(rejected(record), hasLength(1), reason: '$record');
    }
    final mixed = ChapterLoader.parse(
      chapterJson([
        broken.first,
        chapterRecord(id: 'chapter_20', from: 20, to: 23),
      ]),
      onRejected: (_, _) {},
    );
    expect(mixed.map((c) => c.id), ['chapter_20']);
  });

  test('an empty suggested question is allowed', () {
    expect(rejected(chapterRecord(suggested: '')), isEmpty);
  });

  test('a file that is not a list shows no chapters', () {
    expect(ChapterLoader.parse('{}', onRejected: (_, _) {}), isEmpty);
  });

  test('approved shows; a draft shows only in a review build', () {
    final chapters = ChapterLoader.parse(
      chapterJson([
        chapterRecord(),
        chapterRecord(
          id: 'chapter_20',
          from: 20,
          to: 23,
          status: 'draft',
          approvedBy: '',
          approvedDate: '',
        ),
        chapterRecord(
          id: 'chapter_24',
          from: 24,
          to: 27,
          status: 'approved',
          approvedBy: '',
        ),
        chapterRecord(id: 'chapter_28', from: 28, to: 31, status: 'rejected'),
      ]),
    );
    for (final review in [false, true]) {
      expect(
        ChapterLoader.forWeek(chapters, 18, reviewBuild: review)?.id,
        'chapter_16',
      );
      expect(
        ChapterLoader.forWeek(chapters, 21, reviewBuild: review)?.id,
        review ? 'chapter_20' : null,
      );
      expect(ChapterLoader.forWeek(chapters, 25, reviewBuild: review), isNull);
      expect(ChapterLoader.forWeek(chapters, 29, reviewBuild: review), isNull);
      expect(ChapterLoader.forWeek(chapters, 15, reviewBuild: review), isNull);
    }
  });

  test('the shipped chapters file parses', () async {
    final raw = await rootBundle.loadString(ChapterLoader.assetPath);
    final reasons = <String>[];
    ChapterLoader.parse(raw, onRejected: (id, r) => reasons.add('$id: $r'));
    expect(reasons, isEmpty);
  });
}
