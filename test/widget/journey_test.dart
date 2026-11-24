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
import 'package:little_bumpy/presentation/screens/visit_screen.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chapter_fixtures.dart';
import '../support/guide_fixture.dart';

/// The three moments of the merged app, each walked as one flow with
/// made-up fixture content, in a review build (drafts shown and tagged).
DateTime _now() => DateTime(2026, 11, 24); // week 16 for this due date

const _question = 'Which ribbon colour is the brightest?';
const _curious = 'How long can a kite string be?';
const _guideQuestion = 'Could you show me the first fold again?';

/// A draft chapter for weeks 16 to 19 whose curious question is about Iron.
final _kites = chapterRecord(
  status: 'draft',
  approvedBy: '',
  approvedDate: '',
  need: 'IRON',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ContentGate.debugDrafts = true; // a review build
    ChapterLoader.debugUse(ChapterLoader.parse(chapterJson([_kites])));
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-11'});
  });

  tearDown(() {
    ContentGate.debugDrafts = null;
    ChapterLoader.debugUse(null);
    ContentLoader.debugSetGuides(null);
  });

  Future<void> tapOn(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f.hitTestable());
    await t.pumpAndSettle();
  }

  Finder inPage(Finder f) =>
      find.descendant(of: find.byType(PageView), matching: f);

  Future<AppState> openThisWeek(WidgetTester t) async {
    // Set inside the test body: a future made in setUp lives outside the
    // test's fake clock and would never complete during pumps.
    ContentLoader.debugSetGuides(
      Guide.reviewAll(jsonEncode([paperBoatGuide(status: 'draft')])),
    );
    final state = await AppState.load(now: _now);
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    await t.pumpAndSettle();
    return state;
  }

  testWidgets('(a) This Week in a chapter week: picture, one thing to know '
      'with its source, get ready, add the question, look forward', (t) async {
    final state = await openThisWeek(t);

    // Picture (or the fallback panel with Bumpy) under the title band.
    final picture = find.byKey(const ValueKey('chapter-picture'));
    expect(picture, findsOneWidget);
    final size = t.getSize(picture);
    expect(size.width / size.height, closeTo(4 / 3, .01));
    expect(
      find.descendant(
        of: picture,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/images/chapter-test-'
                      '${state.isHalloween ? 'halloween' : 'everyday'}.webp',
        ),
      ),
      findsOneWidget,
    );
    // The fixture has no art, so the fallback panel shows Bumpy instead.
    expect(
      find.descendant(of: picture, matching: find.byType(BumpyAvatar)),
      findsOneWidget,
    );
    expect(
      t.getTopLeft(find.text('Paper kites')).dy,
      greaterThan(t.getTopLeft(picture).dy),
    );
    expect(inPage(find.byType(DraftTag)), findsOneWidget);

    // One thing to know, with its source organisation and page title.
    final order = [
      'One thing to know',
      'Kites fly best on a breezy afternoon.',
      'Source: Test Kite Club, Kite basics',
      'One thing to get ready',
      'Find a ribbon you like for the kite tail.',
      '“$_question”',
      'Something to look forward to',
      'A picnic on the hill with a striped blanket.',
      _curious,
    ];
    double top(String text) => t.getTopLeft(inPage(find.text(text))).dy;
    for (var i = 1; i < order.length; i++) {
      expect(top(order[i]), greaterThan(top(order[i - 1])), reason: order[i]);
    }

    // Add the suggested question in one tap.
    await tapOn(t, find.text('Add to my visit list'));
    expect(state.hasVisitQuestion(_question), isTrue);
    expect(find.text('On your visit list'), findsOneWidget);

    await t.ensureVisible(
      find.text('A picnic on the hill with a striped blanket.'),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('(b) after a cold restart Today shows the question in words '
      'and one tap shows it at the visit', (t) async {
    await openThisWeek(t);
    await tapOn(t, find.text('Add to my visit list'));
    await t.pumpWidget(const SizedBox());

    final cold = await AppState.load(now: _now);
    expect(cold.visitQuestions.map((q) => q.text), [_question]);
    await t.pumpWidget(LittleBumpyApp(state: cold));
    await t.pumpAndSettle();
    expect(cold.currentTab, 0);
    final card = find.byKey(const ValueKey('visit-card'));
    await t.ensureVisible(card);
    await t.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('“$_question”')),
      findsOneWidget,
    );
    await tapOn(t, find.text('Show at my visit'));
    expect(find.byType(VisitScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(VisitScreen),
        matching: find.text(_question),
      ),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('(c) the curious question opens the guide with five cards, '
      'and a guide question goes on the visit list', (t) async {
    // Tall enough that the guide's list builds all five cards at once.
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(440, 3000);
    addTearDown(t.view.reset);
    final state = await openThisWeek(t);
    await tapOn(t, find.text(_curious));

    expect(find.byType(GuideScreen), findsOneWidget);
    expect(find.text('Iron guide'), findsOneWidget);
    const cards = [
      'guide-card-point',
      'guide-card-facts',
      'guide-card-hard',
      'guide-card-ask',
      'guide-card-call',
    ];
    final tops = [
      for (final key in cards) t.getTopLeft(find.byKey(ValueKey(key))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(tops.toSet(), hasLength(5));
    // Draft guide in a review build: every card carries the tag.
    expect(find.byType(DraftTag), findsWidgets);

    final row = find.byKey(const ValueKey('guide-question-0'));
    await tapOn(
      t,
      find.descendant(of: row, matching: find.text('Add to visit list')),
    );
    expect(state.hasVisitQuestion(_guideQuestion), isTrue);
    expect(
      state.visitQuestions.firstWhere((q) => q.text == _guideQuestion).need,
      MaternalNeed.iron,
    );
    expect(
      find.descendant(of: row, matching: find.text('On your visit list')),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  for (final halloween in [false, true]) {
    for (final width in [320.0, 375.0, 412.0, 440.0]) {
      testWidgets('the chapter picture keeps its whole 4:3 frame at $width px '
          '(${halloween ? 'Halloween' : 'Everyday'})', (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 812);
        addTearDown(t.view.reset);
        SharedPreferences.setMockInitialValues({
          'due_date_iso': '2027-05-11',
          'is_halloween': halloween,
        });
        final state = await openThisWeek(t);
        expect(state.isHalloween, halloween);
        final picture = find.byKey(const ValueKey('chapter-picture'));
        final size = t.getSize(picture);
        expect(size.width / size.height, closeTo(4 / 3, .01));
        // The fallback panel (fixture art is missing) fills the same box,
        // with Bumpy on it.
        expect(
          find.descendant(of: picture, matching: find.byType(BumpyAvatar)),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      });
    }
  }
}
