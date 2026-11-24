import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/content/content_paths.dart';
import 'package:little_bumpy/content/urgent_loader.dart';
import 'package:little_bumpy/core/constants/app_constants.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/urgent_signs.dart';
import 'package:little_bumpy/domain/models/week_card.dart';

/// Whatever a review build shows as a draft, a normal build hides: checked
/// against the shipped chapters and guides, not fixtures.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ContentGate.debugDrafts = null;
    ContentLoader.clearCache();
  });

  test(
    'with the review flag off, no shipped chapter or guide draft shows',
    () async {
      ContentGate.debugDrafts = false;
      expect(ContentGate.showsDrafts, isFalse);

      final chapters = ChapterLoader.parse(
        await rootBundle.loadString(ChapterLoader.assetPath),
      );
      final guidesRaw = await rootBundle.loadString(ContentPaths.guides);

      // Normal build: only approved, dated records get through.
      for (
        var week = AppConstants.minWeek;
        week <= AppConstants.maxWeek;
        week++
      ) {
        final chapter = ChapterLoader.forWeek(chapters, week);
        if (chapter != null) {
          expect(chapter.review(), Review.shown, reason: 'week $week');
          expect(chapter.isDraft, isFalse, reason: 'week $week');
        }
      }
      for (final c in chapters) {
        if (c.status != 'approved') {
          expect(ChapterLoader.isVisible(c), isFalse, reason: c.id);
        }
      }
      for (final guide in Guide.reviewAll(guidesRaw).values) {
        expect(guide.isDraft, isFalse, reason: guide.need.name);
      }

      // The same files in a review build: each draft shows, and only drafts
      // or approved records do, so the check above is not vacuous.
      final draftChapters = chapters.where((c) => c.isDraft).toList();
      for (final c in draftChapters) {
        expect(c.review(drafts: true), Review.draft, reason: c.id);
        expect(c.review(drafts: false), Review.hidden, reason: c.id);
      }
      for (final guide in Guide.reviewAll(guidesRaw, drafts: true).values) {
        if (guide.isDraft) {
          expect(
            Guide.reviewAll(guidesRaw, drafts: false)[guide.need],
            isNull,
            reason: guide.need.name,
          );
        }
      }
    },
  );

  test('with the review flag off, no draft or held Today line, week card '
      'or urgent list shows', () async {
    ContentGate.debugDrafts = false;
    ContentLoader.clearCache();
    final held = await ContentLoader.loadHeld();
    expect(held.records, isNotEmpty);

    // Today: only approved, unheld lines are loaded at all.
    final lines = await ContentLoader.load(ContentPaths.todayLines);
    expect(lines, isNotEmpty);
    for (final r in lines) {
      expect(r.isDraft, isFalse, reason: r.id);
      expect(r.isHeld, isFalse, reason: r.id);
      expect(ContentGate.canDisplay(r), isTrue, reason: r.id);
    }

    // Week cards (the plain week page and the chapter page both use findFor).
    final cards = await ContentLoader.loadWeekCards();
    final heldWeeks = cards.where((c) => c.isHeld).map((c) => c.week).toSet();
    expect(heldWeeks, containsAll(<int>[8, 9, 35]));
    for (
      var week = AppConstants.minWeek;
      week <= AppConstants.maxWeek;
      week++
    ) {
      for (final mode in ['everyday', 'halloween']) {
        final card = WeekCard.findFor(cards: cards, week: week, mode: mode);
        if (card == null) continue;
        expect(card.isDraft, isFalse, reason: 'week $week $mode');
        expect(card.isHeld, isFalse, reason: 'week $week $mode');
      }
    }
    // Not vacuous: a review build does show the held weeks, as drafts.
    for (final week in heldWeeks) {
      final card = WeekCard.findFor(
        cards: cards,
        week: week,
        mode: 'halloween',
        drafts: true,
      );
      expect(card?.isDraft, isTrue, reason: 'week $week');
    }

    // Urgent list: shown only when approved.
    final urgentRaw = await rootBundle.loadString(UrgentLoader.path);
    final urgent = UrgentSigns.review(urgentRaw, drafts: false);
    if (urgent != null) expect(urgent.isDraft, isFalse);
  });
}
