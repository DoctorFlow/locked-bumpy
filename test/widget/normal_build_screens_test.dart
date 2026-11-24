import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_line.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/urgent_signs.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/urgent_screen.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A normal build (review flag off) with the shipped content files: nothing
/// draft or held reaches the screen, and each screen still reads as whole
/// without it (no empty card, no heading with nothing under it).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const laterTitle = 'Later in pregnancy or after birth';
  const week20 = 'Thank you for everything.';

  setUp(() {
    ContentGate.debugDrafts = false;
    ContentLoader.clearCache();
    rootBundle.clear();
  });

  tearDown(() {
    ContentGate.debugDrafts = null;
    ContentLoader.clearCache();
  });

  test('app_lines.json: no draft line gets through a normal build', () {
    final raw = File(AppLines.assetPath).readAsStringSync();
    final review = AppLines.review(raw, drafts: true);
    // Not vacuous: the review build has both draft lines.
    expect(
      review.keys,
      containsAll(<String>[AppLines.pausedSupport, AppLines.urgentLaterTitle]),
    );
    for (final line in AppLines.review(raw, drafts: false).values) {
      expect(line.isDraft, isFalse, reason: line.id);
    }
    expect(AppLines.review(raw, drafts: false), isEmpty);
  });

  /// The app for a parent at [week] on 24 Nov 2026.
  Future<AppState> open(WidgetTester t, int week) async {
    // 2027-05-11 is week 16 on 2026-11-24.
    final due = DateTime(2027, 5, 11 + 7 * (16 - week));
    SharedPreferences.setMockInitialValues({
      'due_date_iso': due.toIso8601String().substring(0, 10),
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    return state;
  }

  void noDraft(WidgetTester t, String where) {
    expect(find.byType(DraftTag), findsNothing, reason: where);
    expect(find.text('Draft'), findsNothing, reason: where);
    expect(find.text('Held'), findsNothing, reason: where);
    expect(t.takeException(), isNull, reason: where);
  }

  for (final week in [9, 20, 35]) {
    testWidgets('week $week: Today, This Week, Guides and the urgent page '
        'show nothing draft or held and read as whole', (t) async {
      await open(t, week);
      noDraft(t, 'Today');
      expect(find.text('Little Bumpy'), findsWidgets);

      await t.tap(find.text('This Week'));
      await t.pumpAndSettle();
      noDraft(t, 'This Week');
      expect(find.text('You are here'), findsOneWidget);
      expect(find.textContaining(week20), findsNothing);
      // No draft chapter: the shipped chapters are all drafts.
      for (final c in ChapterLoader.parse(
        File(ChapterLoader.assetPath).readAsStringSync(),
      )) {
        if (c.isDraft) expect(find.text(c.title), findsNothing, reason: c.id);
      }

      await t.tap(find.text('Guides'));
      await t.pumpAndSettle();
      noDraft(t, 'Guides');
      // With every guide a draft, the page names its cards plainly.
      expect(find.text('Care topics'), findsOneWidget);
      expect(find.text(UrgentScreen.rowLabel), findsWidgets);

      await t.tap(find.text(UrgentScreen.rowLabel).first);
      await t.pumpAndSettle();
      noDraft(t, 'urgent');
      expect(find.byKey(const ValueKey('urgent-fallback')), findsOneWidget);
      expect(find.text(UrgentSigns.fallback), findsOneWidget);
      expect(find.text(laterTitle), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('urgent list approved but its last group title still a draft: '
      'no stray heading, every sign shown once', (t) async {
    // The list as a review build reads it, with the title as a normal build
    // reads it (hidden), so the order falls back to Amendment 4.
    final list =
        UrgentSigns.review(
          File('assets/content/urgent_signs.json').readAsStringSync(),
          drafts: true,
        )!.withLaterTitle(
          AppLines.review(
            File(AppLines.assetPath).readAsStringSync(),
            drafts: false,
          )[AppLines.urgentLaterTitle],
        );
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-06-26'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    expect(state.currentWeek, 9);
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(AppPalette.halloween),
        home: UrgentScreen(state: state, urgent: list),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('urgent-later-group')), findsNothing);
    expect(find.text(laterTitle), findsNothing);
    for (final s in list.signs) {
      expect(find.text(s), findsOneWidget);
    }
  });
}
