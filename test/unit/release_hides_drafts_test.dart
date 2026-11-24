import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_paths.dart';
import 'package:little_bumpy/core/constants/app_constants.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/guide.dart';

/// Whatever a review build shows as a draft, a normal build hides: checked
/// against the shipped chapters and guides, not fixtures.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => ContentGate.debugDrafts = null);

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
}
