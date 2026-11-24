import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:little_bumpy/presentation/screens/guides_screen.dart';
import 'package:little_bumpy/core/theme/paper.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chapter_fixtures.dart';
import '../support/guide_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final kites = chapterRecord();
  final lanterns = chapterRecord(
    id: 'chapter_20',
    from: 20,
    to: 23,
    title: 'Lantern night',
    accent: '#F2A65A',
    illustration: 'chapter-lanterns',
    status: 'draft',
    approvedBy: '',
    approvedDate: '',
    suggested: '',
  );

  tearDown(() {
    ChapterLoader.debugUse(null);
    ContentGate.debugDrafts = null;
    ContentLoader.debugSetGuides(null);
  });

  /// Current week is 16, inside the kites chapter (16 to 19).
  Future<AppState> openThisWeek(
    WidgetTester t, {
    bool halloween = false,
    bool review = false,
    bool reduceMotion = false,
    bool settle = true,
  }) async {
    if (reduceMotion) {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    ChapterLoader.debugUse(ChapterLoader.parse(chapterJson([kites, lanterns])));
    ContentGate.debugDrafts = review;
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-11',
      'is_halloween': halloween,
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    if (state.isHalloween != halloween) await state.toggleMode();
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    if (settle) {
      await t.pumpAndSettle();
    } else {
      // The chapters load in a microtask; two frames build the page.
      await t.pump();
      await t.pump();
    }
    return state;
  }

  testWidgets('a chapter page reads in the storybook order', (t) async {
    await openThisWeek(t);
    final order = [
      'Paper kites',
      'Weeks 16 to 19',
      'Week 16',
      'I folded a tiny paper kite today.',
      'One thing to know',
      'Source: Test Kite Club, Kite basics',
      'One thing to get ready',
      'Something to look forward to',
    ];
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
    final positions = <double>[];
    for (final text in order) {
      final inPage = find.descendant(
        of: find.byType(PageView),
        matching: find.text(text),
      );
      positions.add(t.getTopLeft(inPage.first).dy);
    }
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThan(positions[i - 1]), reason: order[i]);
    }
    expect(find.text('One thing to get ready'), findsOneWidget);
    expect(find.text('My question for the visit'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('one tap adds the question to the visit list', (t) async {
    final state = await openThisWeek(t);
    const question = 'Which ribbon colour is the brightest?';
    final add = find.text('Add to my visit list');
    await t.ensureVisible(add);
    await t.pumpAndSettle();
    await t.tap(add);
    await t.pumpAndSettle();
    expect(state.hasVisitQuestion(question), isTrue);
    expect(state.visitQuestions.single.origin, VisitOrigin.week);
    expect(find.text('On your visit list'), findsOneWidget);
    expect(find.text('Add to my visit list'), findsNothing);
    expect(find.text('Write my own question'), findsOneWidget);
  });

  testWidgets('the curious question opens that need\'s guide page', (t) async {
    ContentLoader.debugSetGuides({
      MaternalNeed.rest: Guide.reviewAll(
        jsonEncode([paperBoatGuide(need: 'REST')]),
      )[MaternalNeed.rest]!,
    });
    final state = await openThisWeek(t);
    final link = find.text('How long can a kite string be?');
    await t.ensureVisible(link);
    await t.pumpAndSettle();
    await t.tap(link);
    await t.pumpAndSettle();
    expect(find.byType(GuideScreen), findsOneWidget);
    expect(find.text('Rest guide'), findsOneWidget);
    expect(state.currentTab, 1);
  });

  testWidgets('a hidden guide sends the curious question to the Guides tab', (
    t,
  ) async {
    ContentLoader.debugSetGuides(const {});
    final state = await openThisWeek(t);
    final link = find.text('How long can a kite string be?');
    await t.ensureVisible(link);
    await t.pumpAndSettle();
    await t.tap(link);
    await t.pumpAndSettle();
    expect(find.byType(GuideScreen), findsNothing);
    expect(state.currentTab, 2);
    // The Guides tab, where Rest still has its name and visit-list control.
    expect(find.byType(GuidesScreen), findsOneWidget);
    expect(find.text('Care topics'), findsOneWidget);
  });

  testWidgets('a week without a chapter keeps the card and invitation', (
    t,
  ) async {
    await openThisWeek(t);
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    await t.pumpAndSettle();
    expect(find.text('Week 15'), findsOneWidget);
    expect(find.text('My question for the visit'), findsOneWidget);
    expect(find.text('Paper kites'), findsNothing);
  });

  testWidgets('a draft chapter is hidden outside a review build', (t) async {
    await openThisWeek(t);
    await t.tap(find.text('Choose week'));
    await t.pumpAndSettle();
    await t.tap(find.text('21'));
    await t.pumpAndSettle();
    expect(find.text('Lantern night'), findsNothing);
    expect(find.text('Week 21'), findsOneWidget);
  });

  testWidgets('a review build shows the draft with its tag and colour', (
    t,
  ) async {
    await openThisWeek(t, review: true);
    Color band(String title) => t
        .widget<ColoredBox>(
          find
              .ancestor(of: find.text(title), matching: find.byType(ColoredBox))
              .first,
        )
        .color;
    final kitesColour = band('Paper kites');
    await t.tap(find.text('Choose week'));
    await t.pumpAndSettle();
    await t.tap(find.text('21'));
    await t.pumpAndSettle();
    expect(find.text('Lantern night'), findsOneWidget);
    expect(find.byType(DraftTag), findsOneWidget);
    expect(find.text('Add to my visit list'), findsNothing);
    expect(band('Lantern night'), isNot(kitesColour));
    expect(band('Lantern night'), const Color(0xFFF2A65A));
  });

  for (final halloween in [false, true]) {
    testWidgets(
      'fits 320 px at 200 percent text (${halloween ? 'Halloween' : 'Everyday'})',
      (t) async {
        t.view.physicalSize = const Size(320, 640);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await openThisWeek(t, halloween: halloween);
        expect(find.text('Paper kites'), findsOneWidget);
        for (final text in [
          'One thing to get ready',
          'Add to my visit list',
          'How long can a kite string be?',
        ]) {
          await t.ensureVisible(find.text(text));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), isNull);
        final button = find.ancestor(
          of: find.text('Add to my visit list'),
          matching: find.byType(FilledButton),
        );
        expect(t.getSize(button).height, greaterThanOrEqualTo(48));
      },
    );
  }

  testWidgets('chapter headings are announced as headings', (t) async {
    final handle = t.ensureSemantics();
    await openThisWeek(t);
    for (final heading in [
      'Paper kites',
      'One thing to know',
      'One thing to get ready',
      'Something to look forward to',
    ]) {
      await t.ensureVisible(find.text(heading));
      await t.pumpAndSettle();
      expect(
        t.getSemantics(find.text(heading)),
        matchesSemantics(label: heading, isHeader: true),
      );
    }
    handle.dispose();
  });

  Finder bandOf(String title) => find
      .ancestor(of: find.text(title), matching: find.byType(ColoredBox))
      .first;

  testWidgets('the week card sits right under the cover, 24 above Bumpy', (
    t,
  ) async {
    await openThisWeek(t);
    final week = find.ancestor(
      of: find.text('Week 16'),
      matching: find.byType(PaperCard),
    );
    expect(
      t.getTopLeft(week.first).dy - t.getBottomLeft(bandOf('Paper kites')).dy,
      AppSpace.xl,
    );
  });

  testWidgets('Bumpy hops once and the bubble fades in when the page opens', (
    t,
  ) async {
    await openThisWeek(t, settle: false);
    final hop = find.byKey(const ValueKey('chapter-bumpy-hop'));
    final fade = find.byKey(const ValueKey('chapter-bubble-fade'));
    expect(hop, findsOneWidget);
    await t.pump(const Duration(milliseconds: 120));
    final lifted = t.widget<Transform>(hop).transform.getTranslation().y;
    expect(lifted, lessThan(-8));
    expect(lifted, greaterThanOrEqualTo(-18));
    expect(t.widget<Opacity>(fade).opacity, inExclusiveRange(0, 1));
    await t.pump(const Duration(milliseconds: 140));
    expect(t.widget<Opacity>(fade).opacity, 1);
    await t.pumpAndSettle();
    expect(t.widget<Transform>(hop).transform.getTranslation().y, 0);
    // Once only: a rebuild of the same page (a new look) does not hop again.
    await t.tap(find.text('Switch look'));
    await t.pump(const Duration(milliseconds: 120));
    expect(t.widget<Transform>(hop).transform.getTranslation().y, 0);
    await t.pumpAndSettle();
  });

  testWidgets('with less motion Bumpy stays still and the bubble is there', (
    t,
  ) async {
    await openThisWeek(t, reduceMotion: true, settle: false);
    expect(find.text('I folded a tiny paper kite today.'), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-bumpy-hop')), findsNothing);
    expect(find.byKey(const ValueKey('chapter-bubble-fade')), findsNothing);
    await t.pumpAndSettle();
  });

  testWidgets('the cover band needs no Draft tag (release build)', (t) async {
    await openThisWeek(t);
    final band = bandOf('Paper kites');
    expect(find.byType(DraftTag), findsNothing);
    expect(find.byKey(const ValueKey('chapter-draft-sticker')), findsNothing);
    final weeks = find.byKey(const ValueKey('chapter-weeks-tag'));
    expect(find.descendant(of: band, matching: weeks), findsOneWidget);
    // The band ends one card padding below the weeks tag.
    expect(t.getBottomLeft(band).dy - t.getBottomLeft(weeks).dy, AppSpace.l);
  });

  testWidgets('in a review build the Draft tag is a sticker on the picture', (
    t,
  ) async {
    await openThisWeek(t, review: true);
    await t.tap(find.text('Choose week'));
    await t.pumpAndSettle();
    await t.tap(find.text('21'));
    await t.pumpAndSettle();
    final sticker = find.byKey(const ValueKey('chapter-draft-sticker'));
    expect(sticker, findsOneWidget);
    final picture = t.getRect(find.byKey(const ValueKey('chapter-picture')));
    final tag = t.getRect(
      find.descendant(of: sticker, matching: find.byType(DraftTag)),
    );
    expect(picture.contains(tag.topLeft), isTrue);
    expect(picture.contains(tag.bottomRight), isTrue);
    final weeks = find.byKey(const ValueKey('chapter-weeks-tag'));
    expect(
      t.getBottomLeft(bandOf('Lantern night')).dy - t.getBottomLeft(weeks).dy,
      AppSpace.l,
    );
  });

  testWidgets('every tappable thing on the chapter is at least 48 x 48', (
    t,
  ) async {
    await openThisWeek(t);
    final page = find.byType(PageView);
    for (final type in [FilledButton, OutlinedButton, TextButton, IconButton]) {
      final found = find.descendant(of: page, matching: find.byType(type));
      for (final e in found.evaluate()) {
        final size = (e.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(48), reason: '$type');
        expect(size.width, greaterThanOrEqualTo(48), reason: '$type');
      }
    }
    final row = find.ancestor(
      of: find.text('How long can a kite string be?'),
      matching: find.byType(InkWell),
    );
    expect(t.getSize(row.first).height, greaterThanOrEqualTo(48));
  });

  for (final halloween in [false, true]) {
    testWidgets(
      'at 320 x 568 and 200 percent the chapter keeps 60 percent of the '
      'height (${halloween ? 'Halloween' : 'Everyday'})',
      (t) async {
        t.view.physicalSize = const Size(320, 568);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await openThisWeek(t, halloween: halloween);
        expect(find.byKey(const ValueKey('week-strip-fixed')), findsNothing);
        expect(
          t.getSize(find.byType(PageView)).height,
          greaterThanOrEqualTo(568 * .6),
        );
        for (final text in [
          'Week 16',
          'I folded a tiny paper kite today.',
          'Something to look forward to',
          'Write my own question',
        ]) {
          await t.ensureVisible(
            find.descendant(
              of: find.byType(PageView),
              matching: find.text(text),
            ),
          );
          await t.pumpAndSettle();
        }
        // The strip still works: it scrolls with the page, at its top.
        final next = find.byIcon(Icons.arrow_forward_ios);
        await t.scrollUntilVisible(
          next,
          -200,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await t.pumpAndSettle();
        await t.tap(next);
        await t.pumpAndSettle();
        expect(find.text('Week 17'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('at normal text on a tall phone the week strip stays fixed', (
    t,
  ) async {
    t.view.physicalSize = const Size(375, 812);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await openThisWeek(t);
    expect(find.byKey(const ValueKey('week-strip-fixed')), findsOneWidget);
    expect(find.byKey(const ValueKey('week-strip-in-page')), findsNothing);
  });
}
