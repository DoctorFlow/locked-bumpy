import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chapter_fixtures.dart';
import '../support/guide_fixture.dart';

// "When curious": a chapter's question opens its guide at the fact that
// answers it, marked and announced. From the Guides list the guide opens at
// its top, unmarked. A missing or unknown pointer falls back to the top.

const _lastFact = 'Folded boats work in puddles as well as ponds.';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la >= lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
}

Guide _restGuide() => Guide.reviewAll(
  jsonEncode([paperBoatGuide(need: 'REST')]),
)[MaternalNeed.rest]!;

Map<String, dynamic> _chapter({String? answer}) {
  final record = chapterRecord();
  if (answer != null) {
    (record['curious'] as Map<String, dynamic>)['answer_fact'] = answer;
  }
  return record;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ChapterLoader.debugUse(null);
    ContentGate.debugDrafts = null;
    ContentLoader.debugSetGuides(null);
  });

  /// Records what the app asks screen readers to announce.
  List<String> listenForAnnouncements(WidgetTester t) {
    final heard = <String>[];
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (message) async {
        final map = message as Map<dynamic, dynamic>;
        if (map['type'] == 'announce') {
          heard.add(
            (map['data'] as Map<dynamic, dynamic>)['message'] as String,
          );
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(
            SystemChannels.accessibility,
            null,
          ),
    );
    return heard;
  }

  void phone(WidgetTester t, {double width = 375, double height = 812}) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(width, height);
    addTearDown(t.view.reset);
  }

  /// This Week at week 16 (the kites chapter, curious need REST), then the
  /// curious question tapped.
  Future<void> followCuriousQuestion(
    WidgetTester t, {
    String? answer,
    bool halloween = false,
  }) async {
    ContentLoader.debugSetGuides({MaternalNeed.rest: _restGuide()});
    ChapterLoader.debugUse(
      ChapterLoader.parse(chapterJson([_chapter(answer: answer)])),
    );
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-11',
      'is_halloween': halloween,
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    if (state.isHalloween != halloween) await state.toggleMode();
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    await t.pumpAndSettle();
    final link = find.text('How long can a kite string be?');
    await t.ensureVisible(link);
    await t.pumpAndSettle();
    await t.tap(link);
    await t.pumpAndSettle();
    expect(find.byType(GuideScreen), findsOneWidget);
  }

  double guideOffset(WidgetTester t) => t
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(GuideScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position
      .pixels;

  void expectOnScreen(WidgetTester t, Finder f, double height) {
    final rect = t.getRect(f);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(height));
  }

  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    testWidgets('from a chapter the guide opens on the answering fact, '
        'marked and announced ($look)', (t) async {
      phone(t);
      final heard = listenForAnnouncements(t);
      await followCuriousQuestion(t, answer: 'boat-f5', halloween: halloween);
      final mark = find.byKey(const ValueKey('guide-answer-boat-f5'));
      expect(mark, findsOneWidget);
      expect(find.byType(AnswerMark), findsOneWidget);
      expect(
        find.descendant(of: mark, matching: find.text(_lastFact)),
        findsOneWidget,
      );
      // Scrolled down to it, and it sits fully on screen.
      expect(guideOffset(t), greaterThan(0));
      expectOnScreen(t, find.text(_lastFact), 812);
      // Screen readers hear the answering fact first.
      expect(heard, isNotEmpty);
      expect(heard.first, _lastFact);
    });
  }

  testWidgets('from the Guides list the guide opens at its top, unmarked', (
    t,
  ) async {
    phone(t);
    final heard = listenForAnnouncements(t);
    ContentLoader.debugSetGuides({MaternalNeed.rest: _restGuide()});
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-11'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
    final context = t.element(find.byType(Scaffold).first);
    GuideScreen.open(context, state, MaternalNeed.rest);
    await t.pumpAndSettle();
    expect(find.byType(GuideScreen), findsOneWidget);
    expect(find.byType(AnswerMark), findsNothing);
    expect(guideOffset(t), 0);
    expect(heard, isEmpty);
  });

  testWidgets('a chapter without a pointer opens the guide at its top', (
    t,
  ) async {
    phone(t);
    await followCuriousQuestion(t);
    expect(find.byType(AnswerMark), findsNothing);
    expect(guideOffset(t), 0);
    expect(t.takeException(), isNull);
  });

  testWidgets('an unknown pointer falls back to the top without error', (
    t,
  ) async {
    phone(t);
    await followCuriousQuestion(t, answer: 'boat-f99');
    expect(find.byType(AnswerMark), findsNothing);
    expect(guideOffset(t), 0);
    expect(t.takeException(), isNull);
  });

  Future<AppState> bootState() async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-11'});
    return AppState.load(now: () => DateTime(2026, 11, 24));
  }

  Widget page(AppState state, String? answer) => MaterialApp(
    theme: buildTheme(AppPalette.everyday),
    home: GuideScreen(
      state: state,
      need: MaternalNeed.rest,
      guide: _restGuide(),
      answerFact: answer,
    ),
  );

  testWidgets('with reduced motion the guide jumps to the answer', (t) async {
    phone(t);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final state = await bootState();
    await t.pumpWidget(page(state, 'boat-f5'));
    // One frame after the first: already there, nothing left to animate.
    await t.pump();
    final jumped = guideOffset(t);
    expect(jumped, greaterThan(0));
    await t.pumpAndSettle();
    expect(guideOffset(t), jumped);
  });

  testWidgets('with motion on the guide glides to the answer', (t) async {
    phone(t);
    final state = await bootState();
    await t.pumpWidget(page(state, 'boat-f5'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final midway = guideOffset(t);
    await t.pumpAndSettle();
    expect(guideOffset(t), greaterThan(midway));
  });

  testWidgets('the marked fact holds at 320 px and 200 percent text', (
    t,
  ) async {
    phone(t, width: 320, height: 568);
    final state = await bootState();
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: page(state, 'boat-f5'),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.byType(AnswerMark), findsOneWidget);
    expectOnScreen(t, find.textContaining('Folded boats'), 568);
  });

  for (final p in [AppPalette.everyday, AppPalette.halloween]) {
    final look = p.isHalloween ? 'Halloween' : 'Everyday';
    test('the mark passes contrast ($look)', () {
      final tint = AnswerMark.tint(p);
      // Text on the tint: the fact in ink, its source in inkSoft.
      expect(_contrast(p.ink, tint), greaterThanOrEqualTo(4.5));
      expect(_contrast(p.inkSoft, tint), greaterThanOrEqualTo(4.5));
      // The side rule is a visible marker against paper and against the tint.
      expect(_contrast(p.accent, p.paper), greaterThanOrEqualTo(3));
      expect(_contrast(p.accent, tint), greaterThanOrEqualTo(3));
    });
  }

  testWidgets('This Week: the last link ends clear of the week bar', (t) async {
    phone(t);
    ContentLoader.debugSetGuides({MaternalNeed.rest: _restGuide()});
    ChapterLoader.debugUse(ChapterLoader.parse(chapterJson([_chapter()])));
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-11'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    await t.pumpAndSettle();
    final bar = find.byKey(const ValueKey('week-strip-fixed'));
    expect(bar, findsOneWidget);
    // Scroll the page to its very end.
    final scroll = t.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const PageStorageKey('chapter-week-16')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await t.pumpAndSettle();
    final last = find.byKey(const ValueKey('chapter-urgent-link-16'));
    expect(t.getRect(last).bottom, lessThanOrEqualTo(t.getRect(bar).top - 48));
  });
}
