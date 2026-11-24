import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:little_bumpy/presentation/widgets/need_word.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The shipped chapter file, read in a review build: every chapter's curious
/// question opens the guide for the need it names.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final chapters = ChapterLoader.parse(
    File('assets/content/chapters.json').readAsStringSync(),
    onRejected: (id, reason) => fail('$id rejected: $reason'),
  );
  final guides = Guide.reviewAll(
    File('assets/content/guides.json').readAsStringSync(),
    drafts: true,
  );

  tearDown(() {
    ChapterLoader.debugUse(null);
    ContentGate.debugDrafts = null;
    ContentLoader.debugSetGuides(null);
  });

  test('the shipped file has ten chapters, each with a guide behind it', () {
    expect(chapters, hasLength(10));
    for (final chapter in chapters) {
      expect(guides[chapter.curiousNeed], isNotNull, reason: chapter.id);
    }
  });

  for (final chapter in chapters) {
    testWidgets('${chapter.id}: the curious question opens the '
        '${needWord(chapter.curiousNeed)} guide', (t) async {
      final now = DateTime(2026, 11, 24);
      // Mid-week of the chapter's first week.
      final due = now.add(Duration(days: 280 - chapter.fromWeek * 7 - 3));
      ChapterLoader.debugUse(chapters);
      ContentGate.debugDrafts = true;
      ContentLoader.debugSetGuides(guides);
      SharedPreferences.setMockInitialValues({
        'due_date_iso':
            '${due.year}-${'${due.month}'.padLeft(2, '0')}-'
            '${'${due.day}'.padLeft(2, '0')}',
        'is_halloween': false,
      });
      final state = await AppState.load(now: () => now);
      expect(state.currentWeek, chapter.fromWeek);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.text('This Week'));
      await t.pumpAndSettle();
      expect(find.text(chapter.title), findsOneWidget);
      final link = find.text(chapter.curiousQuestion);
      await t.ensureVisible(link);
      await t.pumpAndSettle();
      await t.tap(link);
      await t.pumpAndSettle();
      expect(find.byType(GuideScreen), findsOneWidget);
      expect(
        find.text('${needWord(chapter.curiousNeed)} guide'),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    });
  }
}
