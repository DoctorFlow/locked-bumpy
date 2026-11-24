import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/visit_screen.dart';
import 'package:little_bumpy/presentation/widgets/app_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Lab round 3, problem 5: on reopening, the parent's own question was the
// last card on Today. Now it sits in a slim strip right under Bumpy.

DateTime _now() => DateTime(2026, 11, 23);

const _own = 'Can my partner come in with me for the scan?';
const _older = 'Is it all right to keep cycling to work?';
const _picked = 'Could we check my iron?';

const _strip = ValueKey('own-words-strip');

Future<AppState> _start({bool halloween = false}) async {
  SharedPreferences.setMockInitialValues({
    'due_date_iso': '2027-05-10',
    'is_halloween': halloween,
  });
  return AppState.load(now: _now);
}

Future<void> _phone(WidgetTester t, Size size, {double text = 1}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetPhysicalSize);
  if (text != 1) {
    t.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }
}

/// Reopens the app: a cold load of what was saved, then the app.
Future<AppState> _reopen(WidgetTester t) async {
  final state = await AppState.load(now: _now);
  await t.pumpWidget(LittleBumpyApp(state: state));
  await t.pumpAndSettle();
  return state;
}

void main() {
  setUpAll(() async {
    // The real faces, so line breaks and heights match a phone (the test
    // font draws every letter as a 1 em square).
    Future<void> face(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }

    await face('Fraunces', ['Fraunces.ttf']);
    await face('Atkinson Hyperlegible', [
      'AtkinsonHyperlegible-Regular.ttf',
      'AtkinsonHyperlegible-Bold.ttf',
    ]);
  });

  testWidgets('with no own-words question the strip is absent', (t) async {
    await _phone(t, const Size(375, 812));
    final state = await _start();
    await state.addVisitQuestion(_picked, need: MaternalNeed.iron);
    await state.saveVisitTopics({MaternalNeed.rest});
    await _reopen(t);
    expect(find.byKey(_strip), findsNothing);
    expect(
      find.textContaining('My question', findRichText: true),
      findsNothing,
    );
    // The visit card still shows the picked question as before.
    final card = find.byKey(const ValueKey('visit-card'));
    await t.ensureVisible(card);
    expect(
      find.descendant(of: card, matching: find.text('“$_picked”')),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('with an empty list the strip is absent', (t) async {
    await _phone(t, const Size(375, 812));
    await _start();
    await _reopen(t);
    expect(find.byKey(_strip), findsNothing);
    expect(find.byKey(const ValueKey('visit-empty')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('on reopening, the newest own words sit under Bumpy, above the '
      'check-ins, and the card below does not repeat them', (t) async {
    await _phone(t, const Size(375, 812));
    final state = await _start();
    await state.addVisitQuestion(_older);
    await state.addVisitQuestion(_picked, need: MaternalNeed.iron);
    await state.addVisitQuestion(_own);
    await _reopen(t);

    final strip = find.byKey(_strip);
    expect(strip, findsOneWidget);
    // One line: the quiet label, then the words in quotes.
    final quote = t.widget<Text>(
      find.byKey(const ValueKey('own-words-strip-question')),
    );
    expect(quote.textSpan!.toPlainText(), 'My question  “$_own”');
    final checkIns = find.byKey(const ValueKey('today-check-ins'));
    expect(t.getRect(strip).bottom, lessThan(t.getRect(checkIns).top));
    expect(quote.maxLines, 1);
    expect(quote.overflow, TextOverflow.ellipsis);

    final card = find.byKey(const ValueKey('visit-card'));
    await t.ensureVisible(card);
    expect(
      find.descendant(of: card, matching: find.textContaining(_own)),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.text('“$_older”')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('More on your list')),
      findsOneWidget,
    );
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('with that one question only, the card offers to add another', (
    t,
  ) async {
    await _phone(t, const Size(375, 812));
    final state = await _start();
    await state.addVisitQuestion(_own);
    await _reopen(t);
    expect(find.byKey(_strip), findsOneWidget);
    final card = find.byKey(const ValueKey('visit-card'));
    await t.ensureVisible(card);
    expect(
      find.descendant(of: card, matching: find.textContaining(_own)),
      findsNothing,
    );
    expect(find.text('Another question? Add it here.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('visit-add-another')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('visit-question-field')), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the strip is one button with a spoken label and opens the '
      'show view', (t) async {
    final handle = t.ensureSemantics();
    await _phone(t, const Size(375, 812));
    final state = await _start();
    await state.addVisitQuestion(_own);
    await _reopen(t);
    final node = find.bySemanticsLabel('My question: $_own. Show at my visit');
    expect(node, findsOneWidget);
    expect(t.getSemantics(node).flagsCollection.isButton, isTrue);
    expect(t.getSize(find.byKey(_strip)).height, greaterThanOrEqualTo(48));
    await t.tap(find.byKey(_strip));
    await t.pumpAndSettle();
    expect(find.byType(VisitScreen), findsOneWidget);
    expect(find.text(_own), findsOneWidget);
    handle.dispose();
    await t.pumpWidget(const SizedBox());
  });

  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    testWidgets('at 375 x 812 Bumpy, the strip and two check-in rows share '
        'the first screen ($look)', (t) async {
      await _phone(t, const Size(375, 812));
      final state = await _start(halloween: halloween);
      await state.addVisitQuestion(
        'Is it normal to feel this tired in the afternoons, even after a '
        'full night of sleep?',
      );
      await _reopen(t);
      final tabTop = t.getRect(find.byType(AppNavBar)).top;
      final strip = t.getRect(find.byKey(_strip));
      expect(strip.height, lessThanOrEqualTo(56));
      expect(strip.bottom, lessThan(tabTop));
      final rows = state.dailyCheckIns;
      for (final need in rows.take(2)) {
        final row = t.getRect(find.byKey(ValueKey(need)));
        expect(row.top, greaterThan(strip.bottom), reason: need.name);
        expect(row.bottom, lessThanOrEqualTo(tabTop), reason: need.name);
      }
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('at 320 x 568 and 200 percent text nothing overlaps ($look)', (
      t,
    ) async {
      await _phone(t, const Size(320, 568), text: 2);
      final state = await _start(halloween: halloween);
      await state.addVisitQuestion(_own);
      await _reopen(t);
      expect(t.takeException(), isNull);
      final strip = find.byKey(_strip);
      await t.ensureVisible(strip);
      await t.pumpAndSettle();
      final box = t.getRect(strip);
      final checkIns = t.getRect(find.byKey(const ValueKey('today-check-ins')));
      expect(box.bottom, lessThanOrEqualTo(checkIns.top));
      // The label and the quote stay inside the strip.
      final r = t.getRect(
        find.byKey(const ValueKey('own-words-strip-question')),
      );
      expect(r.left, greaterThanOrEqualTo(box.left));
      expect(r.right, lessThanOrEqualTo(box.right));
      expect(r.top, greaterThanOrEqualTo(box.top));
      expect(r.bottom, lessThanOrEqualTo(box.bottom));
      await t.pumpWidget(const SizedBox());
    });
  }

  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    testWidgets('the show view has room under Copy my list at 320 px and 200 '
        'percent text ($look)', (t) async {
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _phone(t, const Size(320, 568), text: 2);
      final state = await _start(halloween: halloween);
      await state.addVisitQuestion(_picked, need: MaternalNeed.iron);
      await state.addVisitQuestion(_older);
      await state.addVisitQuestion(_own);
      await state.saveVisitTopics({MaternalNeed.rest, MaternalNeed.water});
      await _reopen(t);
      final navTop = t.getRect(find.byType(AppNavBar)).top;
      final navHeight = 568 - navTop;
      await t.ensureVisible(find.byKey(_strip));
      await t.pumpAndSettle();
      await t.tap(find.byKey(_strip));
      await t.pumpAndSettle();
      expect(find.byType(VisitScreen), findsOneWidget);
      final scroller = find.descendant(
        of: find.byType(VisitScreen),
        matching: find.byType(Scrollable),
      );
      // Scroll to the very end.
      await t.fling(scroller, const Offset(0, -3000), 3000);
      await t.pumpAndSettle();
      final copy = find.byKey(const ValueKey('visit-copy'));
      final button = t.getRect(copy);
      // The whole button sits clear of where the tab bar is, and clear of
      // a floating note, with room to spare.
      expect(button.bottom, lessThanOrEqualTo(navTop - 8));
      expect(568 - button.bottom, greaterThanOrEqualTo(navHeight));
      expect(t.getSize(copy).height, greaterThanOrEqualTo(48));
      expect(find.text('Edit').hitTestable(), findsOneWidget);
      await t.tap(copy);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      final note = t.getRect(
        find
            .descendant(
              of: find.byKey(const ValueKey('visit-copied')),
              matching: find.byType(Material),
            )
            .first,
      );
      // The note does not sit on the button it answers.
      expect(note.top, greaterThanOrEqualTo(t.getRect(copy).bottom));
      expect(t.takeException(), isNull);
      await t.pumpAndSettle(const Duration(seconds: 3));
      await t.pumpWidget(const SizedBox());
    });

  }
}
