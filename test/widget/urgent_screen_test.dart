import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/content/urgent_loader.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/domain/models/urgent_signs.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:little_bumpy/presentation/screens/urgent_screen.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/guide_fixture.dart';
import '../support/urgent_fixture.dart';

Guide guideWith({String? callToday}) => Guide.reviewAll(
  jsonEncode([
    {...paperBoatGuide(), 'call_today': ?callToday},
  ]),
  drafts: false,
)[MaternalNeed.iron]!;

UrgentSigns urgentList({bool draft = false}) => UrgentSigns.review(
  jsonEncode(paperBoatUrgent(status: draft ? 'draft' : 'approved')),
  drafts: draft,
)!;

const ownSigns =
    'Call your doctor or midwife today if the paper turns to mush, '
    'even if you are not sure.';
const closing = 'Your doctor or midwife decides what is right for you.';
const signTexts = [
  'The sail has a hole in it',
  'The hull is soaked through',
  'A duck is sitting on the deck',
];

void main() {
  tearDown(() {
    ContentLoader.debugSetGuides(null);
    UrgentLoader.debugReset();
  });

  Future<AppState> boot({bool halloween = false}) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-10',
      'is_halloween': halloween,
    });
    return AppState.load(now: () => DateTime(2026, 11, 23));
  }

  Future<void> pumpGuide(
    WidgetTester t,
    AppState state,
    Guide guide,
    UrgentSigns? urgent, {
    AppPalette palette = AppPalette.everyday,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(palette),
        home: GuideScreen(
          state: state,
          need: MaternalNeed.iron,
          guide: guide,
          urgent: urgent,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Finder inCard5(Finder f) => find.descendant(
    of: find.byKey(const ValueKey('guide-card-call')),
    matching: f,
  );

  void tallView(WidgetTester t) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(440, 5000);
    addTearDown(t.view.reset);
  }

  double top(WidgetTester t, Finder f) => t.getTopLeft(f).dy;

  testWidgets('card 5, approved list: own signs, the full list, closing', (
    t,
  ) async {
    tallView(t);
    final state = await boot();
    await pumpGuide(t, state, guideWith(), urgentList());
    final order = [
      inCard5(find.text(ownSigns)),
      inCard5(find.text('Pull the boat out of the pond')),
      inCard5(
        find.text('Rain or shine, lift it out, if you see any of these:'),
      ),
      for (final s in signTexts) inCard5(find.text(s)),
      inCard5(
        find.text('Fetch a dry towel. If none is near, ask the pond keeper.'),
      ),
      inCard5(find.text(closing)),
    ];
    for (final f in order) {
      expect(f, findsOneWidget);
    }
    final tops = [for (final f in order) top(t, f)];
    expect(tops, orderedEquals([...tops]..sort()));
    // Every sign is its own line, and nothing is folded away.
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.text(UrgentSigns.fallback), findsNothing);
    expect(find.byType(DraftTag), findsNothing);
    // Not in Bumpy's voice: no "Bumpy says" inside card 5.
    expect(inCard5(find.textContaining('Bumpy')), findsNothing);
  });

  testWidgets('card 5, draft list in review: shown with a Draft tag', (
    t,
  ) async {
    tallView(t);
    final state = await boot();
    await pumpGuide(t, state, guideWith(), urgentList(draft: true));
    for (final s in signTexts) {
      expect(inCard5(find.text(s)), findsOneWidget);
    }
    expect(inCard5(find.byType(DraftTag)), findsOneWidget);
    expect(find.byType(DraftTag), findsOneWidget);
  });

  testWidgets('card 5, hidden list: the fixed fallback, never empty', (
    t,
  ) async {
    tallView(t);
    final state = await boot();
    await pumpGuide(t, state, guideWith(), null);
    expect(
      UrgentSigns.fallback,
      'If you are worried about yourself or your baby, call your doctor or '
      'midwife now. In an emergency, call emergency services.',
    );
    expect(inCard5(find.text(UrgentSigns.fallback)), findsOneWidget);
    expect(inCard5(find.text(ownSigns)), findsOneWidget);
    expect(inCard5(find.text(closing)), findsOneWidget);
    expect(
      top(t, inCard5(find.text(UrgentSigns.fallback))),
      lessThan(top(t, inCard5(find.text(closing)))),
    );
    expect(find.text('Pull the boat out of the pond'), findsNothing);
  });

  testWidgets('a guide with empty call_today: list, then closing', (t) async {
    tallView(t);
    final state = await boot();
    for (final urgent in [urgentList(), null]) {
      await pumpGuide(t, state, guideWith(callToday: ''), urgent);
      expect(find.textContaining('today if'), findsNothing);
      final first = urgent == null
          ? find.text(UrgentSigns.fallback)
          : find.text('Pull the boat out of the pond');
      expect(inCard5(first), findsOneWidget);
      expect(top(t, first), lessThan(top(t, find.text(closing))));
    }
  });

  testWidgets('GuideScreen.open passes the loaded list to card 5', (t) async {
    tallView(t);
    final state = await boot();
    ContentLoader.debugSetGuides({MaternalNeed.iron: guideWith()});
    UrgentLoader.debugSet(urgentList());
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
    expect(inCard5(find.text(signTexts.last)), findsOneWidget);
  });

  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    testWidgets('Guides tab: the last row opens the list as a page ($look)', (
      t,
    ) async {
      tallView(t);
      ContentLoader.debugSetGuides({MaternalNeed.iron: guideWith()});
      UrgentLoader.debugSet(urgentList());
      final state = await boot(halloween: halloween);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.text('Guides'));
      await t.pumpAndSettle();
      final row = find.byKey(const ValueKey('urgent-row'));
      expect(row, findsOneWidget);
      expect(
        find.bySemanticsLabel('When to get help right away'),
        findsOneWidget,
      );
      // Near the top: above every need card (Amendment 3).
      for (final need in MaternalNeed.values) {
        expect(top(t, row), lessThan(top(t, find.byKey(PageStorageKey(need)))));
      }
      expect(t.getSize(row).height, greaterThanOrEqualTo(48));
      await t.tap(row);
      await t.pumpAndSettle();
      expect(find.byType(UrgentScreen), findsOneWidget);
      expect(find.text('When to get help right away'), findsWidgets);
      for (final s in signTexts) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text('Pond Club: Boat rescue card'), findsOneWidget);
      expect(find.text('Last checked 24 November 2026'), findsOneWidget);
      expect(find.byType(DraftTag), findsNothing);
      // Back to the tab, then Pause closes everything.
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(find.byType(UrgentScreen), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('the Guides row shows without scrolling on a 375 x 812 phone', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(375, 812);
    addTearDown(t.view.reset);
    final state = await boot();
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
    final row = find.byKey(const ValueKey('urgent-row'));
    expect(row.hitTestable(), findsOneWidget);
    expect(t.getBottomLeft(row).dy, lessThan(812 - 80));
    await t.pumpWidget(const SizedBox());
  });

  group('grouped list (Amendment 3)', () {
    final grouped = {
      ...paperBoatUrgent(),
      'groups': [
        {
          'title': 'Sail trouble',
          'signs': ['The sail has a hole in it'],
        },
        {
          'title': 'Hull trouble',
          'signs': [
            'The hull is soaked through',
            'A duck is sitting on the deck',
          ],
        },
      ],
      'footer': 'Not sure about the boat? Ask the pond keeper anyway.',
    };
    UrgentSigns groupedList() =>
        UrgentSigns.review(jsonEncode(grouped), drafts: false)!;

    for (final onPage in [true, false]) {
      testWidgets('group titles, their signs, the action, then the footer '
          '(${onPage ? 'page' : 'card 5'})', (t) async {
        tallView(t);
        final state = await boot();
        final list = groupedList();
        if (onPage) {
          await t.pumpWidget(
            MaterialApp(
              theme: buildTheme(AppPalette.everyday),
              home: UrgentScreen(state: state, urgent: list),
            ),
          );
          await t.pumpAndSettle();
        } else {
          await pumpGuide(t, state, guideWith(), list);
        }
        Finder f(String s) => onPage ? find.text(s) : inCard5(find.text(s));
        final order = [
          f('Sail trouble'),
          f('The sail has a hole in it'),
          f('Hull trouble'),
          f('The hull is soaked through'),
          f('A duck is sitting on the deck'),
          f(list.action),
          f(list.footer!),
        ];
        for (final x in order) {
          expect(x, findsOneWidget);
        }
        final tops = [for (final x in order) top(t, x)];
        expect(tops, orderedEquals([...tops]..sort()));
        // The action is the strongest line: larger than every sign.
        final action = t.widget<Text>(order[5]).style!;
        final sign = t.widget<Text>(order[1]).style!;
        expect(action.fontSize, greaterThan(sign.fontSize!));
        expect(action.fontWeight, FontWeight.w700);
        expect(find.byType(ExpansionTile), findsNothing);
      });
    }
  });

  testWidgets('the page shows the fallback when the list is hidden', (t) async {
    tallView(t);
    UrgentLoader.debugSet(null);
    final state = await boot();
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('urgent-row')));
    await t.pumpAndSettle();
    expect(find.text(UrgentSigns.fallback), findsOneWidget);
    expect(find.text('Sources'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the page marks a review-build draft list', (t) async {
    final state = await boot();
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(AppPalette.everyday),
        home: UrgentScreen(state: state, urgent: urgentList(draft: true)),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(DraftTag), findsOneWidget);
  });

  testWidgets('the shipped file (empty draft list) shows the fallback', (
    t,
  ) async {
    UrgentLoader.debugReset();
    final state = await boot();
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(AppPalette.everyday),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => UrgentScreen.open(context, state),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    // The real asset read is real I/O: let it finish, then rebuild.
    final shipped = await t.runAsync(UrgentLoader.load);
    await t.pumpAndSettle();
    expect(find.byType(UrgentScreen), findsOneWidget);
    if (shipped == null) {
      expect(find.text(UrgentSigns.fallback), findsOneWidget);
    } else {
      expect(find.text(shipped.signs.first), findsOneWidget);
    }
  });

  for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
    final look = palette.isHalloween ? 'Halloween' : 'Everyday';
    for (final urgent in [urgentList(), null]) {
      final which = urgent == null ? 'fallback' : 'list';
      testWidgets('320 px at 200% text, card 5 and page ($look, $which)', (
        t,
      ) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(320, 640);
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final state = await boot();

        final targets = urgent == null
            ? [find.text(UrgentSigns.fallback)]
            : [
                find.text('Pull the boat out of the pond'),
                for (final s in signTexts) find.text(s),
                find.text(urgent.action),
              ];

        Future<void> check() async {
          final list = find.byType(Scrollable).first;
          for (final target in targets) {
            await t.scrollUntilVisible(target, 300, scrollable: list);
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            final text = t.widget<Text>(target);
            expect(text.style!.fontSize, greaterThanOrEqualTo(16));
            expect(text.style!.color, palette.ink);
          }
        }

        await pumpGuide(t, state, guideWith(), urgent, palette: palette);
        await check();
        await t.scrollUntilVisible(
          find.text(closing),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(t.takeException(), isNull);

        await t.pumpWidget(
          MaterialApp(
            theme: buildTheme(palette),
            home: UrgentScreen(state: state, urgent: urgent),
          ),
        );
        await t.pumpAndSettle();
        await check();
      });
    }

    testWidgets('the bundled list, as a review build shows it, fits 320 px '
        'at 200% text ($look)', (t) async {
      final json = File('assets/content/urgent_signs.json').readAsStringSync();
      final bundled = UrgentSigns.review(json, drafts: true);
      if (bundled == null) return; // nothing to lay out yet
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 640);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final state = await boot();
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(palette),
          home: UrgentScreen(state: state, urgent: bundled),
        ),
      );
      await t.pumpAndSettle();
      final list = find.byType(Scrollable).first;
      for (final target in [
        for (final s in bundled.signs) find.text(s),
        find.text(bundled.action),
      ]) {
        await t.scrollUntilVisible(target, 300, scrollable: list);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
    });

    testWidgets('Guides tab row fits 320 px at 200% text ($look)', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 640);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final state = await boot(halloween: palette.isHalloween);
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.text('Guides'));
      await t.pumpAndSettle();
      final row = find.byKey(const ValueKey('urgent-row'));
      await t.scrollUntilVisible(
        row,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final label = find.descendant(
        of: row,
        matching: find.text('When to get help right away'),
      );
      expect(t.widget<Text>(label).style!.color, palette.ink);
      await t.pumpWidget(const SizedBox());
    });
  }
}
