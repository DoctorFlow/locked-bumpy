import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:little_bumpy/presentation/screens/today_screen.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/guide_fixture.dart';

// Made-up paper-boat guides stand in for real ones: no health text here.
const _question = 'Could you show me the first fold again?';

void useGuides(List<Map<String, dynamic>> rows, {bool drafts = false}) =>
    ContentLoader.debugSetGuides(
      Guide.reviewAll(jsonEncode(rows), drafts: drafts),
    );

Future<AppState> start(DateTime day, {bool halloween = false}) async {
  SharedPreferences.setMockInitialValues({
    'due_date_iso': '2027-05-10',
    'is_halloween': halloween,
  });
  return AppState.load(now: () => day);
}

Widget wrap(AppState state) => MaterialApp(
  theme: ThemeData(
    extensions: [
      state.isHalloween ? AppPalette.halloween : AppPalette.everyday,
    ],
  ),
  home: Scaffold(body: TodayScreen(state: state)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => ContentLoader.debugSetGuides(null));

  Future<void> tapOn(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f.hitTestable());
    await t.pumpAndSettle();
  }

  testWidgets('today shows one fact with its source, adds the first question '
      'and opens the guide', (t) async {
    useGuides([paperBoatGuide()]);
    // 23 Nov 2026 is day 0 of the rotation: iron, first fact.
    final state = await start(DateTime(2026, 11, 23));
    await t.pumpWidget(wrap(state));
    await t.pumpAndSettle();

    final fact = find.byKey(const ValueKey('today-fact'));
    expect(fact, findsOneWidget);
    expect(
      find.descendant(
        of: fact,
        matching: find.text(
          'A crisp fold keeps the paper boat steady on a pond.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: fact, matching: find.text('Source: Pond Club')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: fact, matching: find.byType(DraftTag)),
      findsNothing,
    );
    // One visit entry: with a fact, the topic control leaves the visit card.
    expect(find.byKey(const ValueKey('visit-topic-today')), findsNothing);

    // Reading order: Bumpy's pairing, the fact, then the visit card. (This
    // 800 px view puts the check-ins in a column of their own; the upright
    // order is checked in phone_accessibility_test.)
    final pairing = find.byKey(const ValueKey('need-pairing'));
    final visit = find.byKey(const ValueKey('visit-empty'));
    expect(t.getTopLeft(pairing).dy, lessThan(t.getTopLeft(fact).dy));
    expect(t.getTopLeft(fact).dy, lessThan(t.getTopLeft(visit).dy));

    await tapOn(t, find.byKey(const ValueKey('fact-add-question')));
    expect(state.hasVisitQuestion(_question), isTrue);
    expect(state.visitQuestions.single.text, _question);
    expect(state.visitQuestions.single.origin, VisitOrigin.today);
    expect(find.text('On your visit list'), findsOneWidget);
    expect(find.byKey(const ValueKey('fact-add-question')), findsNothing);
    expect(state.completedCheckIns, isEmpty);
    // The visit card now holds the question in words.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('visit-card')),
        matching: find.text(_question),
      ),
      findsOneWidget,
    );

    await tapOn(t, find.byKey(const ValueKey('fact-open-guide')));
    expect(find.byType(GuideScreen), findsOneWidget);
  });

  testWidgets('the fact moves on once per full turn of the six needs', (
    t,
  ) async {
    useGuides([paperBoatGuide()]);
    // Day 6 is iron again: the second fact.
    final state = await start(DateTime(2026, 11, 29));
    await t.pumpWidget(wrap(state));
    await t.pumpAndSettle();
    expect(
      find.text('Thick paper holds its shape longer than thin paper.'),
      findsOneWidget,
    );
  });

  testWidgets('a draft guide carries the Draft tag on its fact', (t) async {
    useGuides([paperBoatGuide(status: 'draft')], drafts: true);
    final state = await start(DateTime(2026, 11, 23));
    await t.pumpWidget(wrap(state));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('today-fact')),
        matching: find.byType(DraftTag),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no guide for today: no fact, and the visit card keeps the '
      'one-tap topic', (t) async {
    // A guide for another need does not show on an iron day.
    useGuides([paperBoatGuide(need: 'WATER')]);
    final state = await start(DateTime(2026, 11, 23));
    await t.pumpWidget(wrap(state));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-fact')), findsNothing);
    final topic = find.byKey(const ValueKey('visit-topic-today'));
    expect(topic, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('visit-empty')),
        matching: topic,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the costume and its need are one readable pairing', (t) async {
    useGuides(const []);
    final halloween = await start(DateTime(2026, 11, 23), halloween: true);
    await t.pumpWidget(wrap(halloween));
    await t.pumpAndSettle();
    final title = t.widget<Text>(find.text('Vampire night · Iron'));
    expect(title.style!.fontSize, greaterThanOrEqualTo(18));

    final everyday = await start(DateTime(2026, 11, 23));
    await t.pumpWidget(wrap(everyday));
    await t.pumpAndSettle();
    expect(find.text('Today · Iron'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('need-pairing')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );
  });

  for (final halloween in [false, true]) {
    testWidgets('320 px and 200 percent text fit Today with a fact '
        '(${halloween ? 'Halloween' : 'Everyday'})', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 568);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      useGuides([paperBoatGuide()]);
      final state = await start(DateTime(2026, 11, 23), halloween: halloween);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      for (final key in ['fact-add-question', 'fact-open-guide']) {
        final button = find.byKey(ValueKey(key));
        await t.ensureVisible(button);
        await t.pumpAndSettle();
        expect(t.getSize(button).height, greaterThanOrEqualTo(48));
      }
      final disclaimer = find.text(TodayScreen.disclaimer);
      await t.ensureVisible(disclaimer);
      await t.pumpAndSettle();
      expect(disclaimer.hitTestable(), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
