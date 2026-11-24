import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chapter_fixtures.dart';

/// The chapter page opens as the parent's own: their name for the baby,
/// their place in the chapter's weeks, what they already put on the list.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ChapterLoader.debugUse(null);
    ContentGate.debugDrafts = null;
  });

  /// Current week is 16 (due 2027-05-11, today 2026-11-24), in the kites
  /// chapter (16 to 19).
  Future<AppState> open(
    WidgetTester t, {
    String nickname = '',
    List<String> visit = const [],
    Size? size,
    double textScale = 1,
    bool halloween = false,
  }) async {
    if (size != null) {
      t.view.physicalSize = size * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
    }
    if (textScale != 1) {
      t.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    }
    ChapterLoader.debugUse(ChapterLoader.parse(chapterJson([chapterRecord()])));
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-11',
      'is_halloween': halloween,
      'baby_nickname': nickname,
      'visit_topics': visit,
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    await t.pumpAndSettle();
    return state;
  }

  group('opens as theirs', () {
    testWidgets('the nickname signs Bumpy\'s line', (t) async {
      await open(t, nickname: 'Peanut');
      expect(find.byKey(const ValueKey('chapter-bumpy-name')), findsOneWidget);
      expect(find.text('Peanut'), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('^Peanut says')), findsOneWidget);
      expect(find.text('I folded a tiny paper kite today.'), findsOneWidget);
    });

    testWidgets('no nickname: the line reads exactly as before', (t) async {
      await open(t);
      expect(find.byKey(const ValueKey('chapter-bumpy-name')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Bumpy says')), findsOneWidget);
    });

    testWidgets('the week strip marks the parent\'s own week, no count', (
      t,
    ) async {
      await open(t);
      for (final w in [17, 18, 19]) {
        expect(find.byKey(ValueKey('chapter-strip-$w')), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('chapter-strip-mine-16')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Your week now: week 16'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('browsing another week keeps the pin on the parent\'s week', (
      t,
    ) async {
      await open(t);
      final next = find.byIcon(Icons.arrow_forward_ios);
      await t.ensureVisible(next);
      await t.pumpAndSettle();
      await t.tap(next);
      await t.pumpAndSettle();
      expect(find.text('Week 17'), findsOneWidget);
      expect(find.byKey(const ValueKey('chapter-strip-mine-16')), findsWidgets);
    });
  });

  group('on your list', () {
    const suggested = 'Which ribbon colour is the brightest?';
    String q2(String text, String origin, {int? week, String? day}) =>
        'q2:${jsonEncode({'t': text, 'o': origin, 'w': ?week, 'd': ?day})}';

    testWidgets('the saved chapter question shows back, not offered again', (
      t,
    ) async {
      await open(
        t,
        visit: [q2(suggested, 'week', week: 16, day: '2026-11-20')],
      );
      final piece = find.byKey(const ValueKey('chapter-on-list'));
      await t.ensureVisible(piece);
      await t.pumpAndSettle();
      expect(find.text('On your list:'), findsOneWidget);
      expect(find.text('“$suggested”'), findsOneWidget);
      expect(find.text('Add to my visit list'), findsNothing);
      expect(find.text('Write my own question'), findsOneWidget);
    });

    testWidgets('own words typed during these weeks show back', (t) async {
      // Due 2027-05-11: 2026-11-24 is in week 16, 2026-10-01 in week 8.
      await open(
        t,
        visit: [
          q2('Can my partner come in with me?', 'own', day: '2026-11-24'),
          q2('An old question from before', 'own', day: '2026-10-01'),
        ],
      );
      final piece = find.byKey(const ValueKey('chapter-on-list'));
      await t.ensureVisible(piece);
      await t.pumpAndSettle();
      expect(find.text('“Can my partner come in with me?”'), findsOneWidget);
      expect(find.textContaining('An old question'), findsNothing);
      expect(find.text('Add to my visit list'), findsNothing);
    });

    testWidgets('nothing from this chapter: the question is offered', (
      t,
    ) async {
      await open(t, visit: [q2('From another chapter', 'week', week: 9)]);
      expect(find.byKey(const ValueKey('chapter-on-list')), findsNothing);
      expect(find.text('Add to my visit list'), findsOneWidget);
    });
  });
}
