import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/services/prefs_service.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/guide_fixture.dart';

/// Passes reads to the mock store and refuses every visit-list write.
class RefusingPrefs implements SharedPreferences {
  RefusingPrefs(this.disk);
  final SharedPreferences disk;

  @override
  bool containsKey(String key) => disk.containsKey(key);
  @override
  Set<String> getKeys() => disk.getKeys();
  @override
  String? getString(String key) => disk.getString(key);
  @override
  bool? getBool(String key) => disk.getBool(key);
  @override
  List<String>? getStringList(String key) => disk.getStringList(key);
  @override
  Future<void> reload() => disk.reload();
  @override
  Future<bool> setStringList(String key, List<String> value) async =>
      key == 'visit_topics' ? false : disk.setStringList(key, value);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Guide fixtureGuide({bool draft = false}) => Guide.reviewAll(
  jsonEncode([paperBoatGuide(status: draft ? 'draft' : 'approved')]),
  drafts: draft,
)[MaternalNeed.iron]!;

const cardTitles = [
  'Iron',
  'Good to know',
  'If it is hard',
  'Ask your doctor or midwife',
  'When to call',
];

void main() {
  tearDown(() => ContentLoader.debugSetGuides(null));

  Future<AppState> boot({bool halloween = false}) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-10',
      'is_halloween': halloween,
    });
    return AppState.load(now: () => DateTime(2026, 11, 23)); // IRON day
  }

  Future<void> pumpPage(
    WidgetTester t,
    AppState state,
    Guide? guide, {
    AppPalette palette = AppPalette.everyday,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(palette),
        home: GuideScreen(state: state, need: MaternalNeed.iron, guide: guide),
      ),
    );
    await t.pumpAndSettle();
  }

  for (final halloween in [false, true]) {
    testWidgets('Guides tab opens five cards in order, then sources '
        '(${halloween ? 'Halloween' : 'Everyday'})', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(440, 5000);
      addTearDown(t.view.reset);
      ContentLoader.debugSetGuides({MaternalNeed.iron: fixtureGuide()});
      final state = await boot(halloween: halloween);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.text('Guides'));
      await t.pumpAndSettle();
      expect(find.text('Care guides'), findsOneWidget);
      final ironCard = find.byKey(const PageStorageKey(MaternalNeed.iron));
      expect(
        find.bySemanticsLabel(RegExp('Open the Iron guide')),
        findsOneWidget,
      );
      await t.tap(find.descendant(of: ironCard, matching: find.text('Iron')));
      await t.pumpAndSettle();

      expect(find.text('Iron guide'), findsOneWidget);
      final tops = [
        for (final title in cardTitles) t.getTopLeft(find.text(title).last).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(
        find.text('A crisp fold keeps the paper boat steady on a pond.'),
        findsOneWidget,
      );
      expect(find.text('Fold a boat from old paper'), findsOneWidget);
      expect(find.text('Pond Club: Folding a paper boat'), findsOneWidget);
      expect(find.text('Last checked 24 November 2026'), findsOneWidget);
      expect(
        t.getTopLeft(find.text('Pond Club: Folding a paper boat')).dy,
        greaterThan(tops.last),
      );
      expect(find.byType(DraftTag), findsNothing);
      if (halloween) expect(find.text('VAMPIRE'), findsWidgets);
      expect(t.takeException(), isNull);

      // Pause closes the guide with everything else.
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Pause').hitTestable());
      await t.pumpAndSettle();
      expect(find.text('Iron guide'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'a guide question goes on the visit list in one tap and off again',
    (t) async {
      final state = await boot();
      final guide = fixtureGuide();
      await pumpPage(t, state, guide);
      final q = guide.questions.first;
      final add = find.descendant(
        of: find.byKey(const ValueKey('guide-question-0')),
        matching: find.text('Add to visit list'),
      );
      await t.scrollUntilVisible(add, 200);
      await t.pumpAndSettle();
      expect(
        t
            .getSize(
              find.ancestor(of: add, matching: find.byType(OutlinedButton)),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await t.tap(add);
      await t.pumpAndSettle();
      expect(state.hasVisitQuestion(q), isTrue);
      expect(find.text('On your visit list'), findsOneWidget);
      final saved = (await AppState.load()).visitQuestions;
      expect(saved.single.text, q);
      expect(saved.single.need, MaternalNeed.iron);

      await t.tap(find.text('Remove'));
      await t.pumpAndSettle();
      expect(state.hasVisitQuestion(q), isFalse);
      expect(find.text('On your visit list'), findsNothing);
      expect((await AppState.load()).visitQuestions, isEmpty);
    },
  );

  testWidgets('a failed save shows a calm message and keeps the button', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final disk = await SharedPreferences.getInstance();
    final state = AppState.withPrefs(
      PrefsService.wrap(RefusingPrefs(disk)),
      now: () => DateTime(2026, 11, 23),
    );
    await pumpPage(t, state, fixtureGuide());
    final add = find.descendant(
      of: find.byKey(const ValueKey('guide-question-0')),
      matching: find.text('Add to visit list'),
    );
    await t.scrollUntilVisible(add, 200);
    await t.pumpAndSettle();
    await t.tap(add);
    await t.pumpAndSettle();
    expect(find.text('That did not save. Please try again.'), findsOneWidget);
    expect(state.visitQuestions, isEmpty);
    expect(find.text('Add to visit list'), findsNWidgets(3));
  });

  testWidgets('a review-build draft marks every card with a Draft tag', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(440, 5000);
    addTearDown(t.view.reset);
    final state = await boot();
    final draft = fixtureGuide(draft: true);
    expect(draft.isDraft, isTrue);
    await pumpPage(t, state, draft);
    // Five cards plus the line under the sources.
    expect(find.byType(DraftTag), findsNWidgets(6));
    expect(find.bySemanticsLabel('Draft, not reviewed'), findsNWidgets(6));

    ContentLoader.debugSetGuides({MaternalNeed.iron: draft});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
    expect(find.byType(DraftTag), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
    testWidgets('guide page fits 320 px at 200% text '
        '(${palette.isHalloween ? 'Halloween' : 'Everyday'})', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 640);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final state = await boot();
      await pumpPage(t, state, fixtureGuide(), palette: palette);
      final list = find.byType(Scrollable).first;
      final call = find.textContaining('Call your doctor or midwife today if');
      for (final target in [
        find.text('Good to know'),
        find.byKey(const ValueKey('guide-question-2')),
        call,
        find.text('Last checked 24 November 2026'),
      ]) {
        await t.scrollUntilVisible(target, 300, scrollable: list);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        // Reading text is at least 16 px, in the look's own ink.
        final text = t.widget(target);
        if (text is Text) {
          expect(text.style!.fontSize, greaterThanOrEqualTo(16));
        }
        if (target == call) {
          expect((text as Text).style!.color, palette.ink);
        }
      }
    });
  }

  testWidgets('a hidden guide still offers the topic for the visit list', (
    t,
  ) async {
    final state = await boot();
    ContentLoader.debugSetGuides(const {});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
    expect(find.text('Care topics'), findsOneWidget);
    final card = find.byKey(const PageStorageKey(MaternalNeed.iron));
    await t.tap(find.descendant(of: card, matching: find.text('Iron')));
    await t.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('Add to my visit list')),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());

    await pumpPage(t, state, null);
    expect(find.textContaining('still being checked'), findsOneWidget);
    expect(find.text('Add to my visit list'), findsOneWidget);
  });

  testWidgets('GuideScreen.open pushes the page for that need', (t) async {
    final state = await boot();
    ContentLoader.debugSetGuides({MaternalNeed.iron: fixtureGuide()});
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(AppPalette.everyday),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                GuideScreen.open(context, state, MaternalNeed.iron),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('Iron guide'), findsOneWidget);
    expect(
      find.text('Paper boats sail best when every fold is crisp.'),
      findsOneWidget,
    );
  });

  testWidgets('the review banner says draft text is marked', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(AppPalette.halloween),
        builder: (context, child) => ReviewBanner(child: child),
        home: const Scaffold(body: Text('app')),
      ),
    );
    expect(find.text('Review build: draft text is marked'), findsOneWidget);
    expect(find.text('app'), findsOneWidget);
  });
}
