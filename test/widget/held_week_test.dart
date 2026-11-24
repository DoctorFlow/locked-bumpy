import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/held_list.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A week whose stamped card is on `held.json`, seen on This Week.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const week9 = 'Week nine. I am no longer an embryo — officially a baby!';
  const week35 =
      'Thirty-five weeks. All the big things are done. Just growing now.';

  setUp(() {
    // No chapter pages, so each week shows its own weekly card.
    ChapterLoader.debugUse(const []);
    ContentLoader.clearCache();
    // The bundle keeps each read as a Future from the test that made it;
    // awaited from a later test's fake clock it would never finish.
    rootBundle.clear();
  });

  tearDown(() {
    ContentGate.debugDrafts = null;
    ChapterLoader.debugUse(null);
    ContentLoader.debugSetHeld(null);
  });

  /// Opens This Week for a parent whose current week is 9 or 35.
  Future<void> openWeek(WidgetTester t, int week) async {
    // 2027-05-11 is week 16 on 2026-11-24.
    final due = DateTime(2027, 5, 11 + 7 * (16 - week));
    SharedPreferences.setMockInitialValues({
      'due_date_iso': due.toIso8601String().substring(0, 10),
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    await t.pumpAndSettle();
    expect(find.text('Week $week'), findsWidgets);
    expect(find.text('You are here'), findsOneWidget);
  }

  for (final (week, line) in [(9, week9), (35, week35)]) {
    testWidgets('normal build: week $week falls back like a week with no '
        'card', (t) async {
      ContentGate.debugDrafts = false;
      await openWeek(t, week);
      expect(find.text(line), findsNothing);
      expect(find.byType(DraftTag), findsNothing);
      expect(find.text('Held'), findsNothing);
      // The rest of the page is still there: the week's own invitation.
      expect(
        find.textContaining(
          week <= 13
              ? 'Save your care team'
              : 'Think through getting to your next visit',
        ),
        findsOneWidget,
      );
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('review build: the held card shows with a Held tag', (t) async {
    ContentGate.debugDrafts = true;
    await openWeek(t, 9);
    expect(find.text(week9), findsOneWidget);
    expect(find.text('Held'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
    expect(find.bySemanticsLabel('Held for a re-check'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('taking week 9 off the list restores it untagged', (t) async {
    ContentGate.debugDrafts = false;
    ContentLoader.debugSetHeld(HeldList.empty);
    await openWeek(t, 9);
    expect(find.text(week9), findsOneWidget);
    expect(find.byType(DraftTag), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
