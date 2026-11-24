import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/presentation/widgets/need_word.dart';
import 'package:little_bumpy/core/services/prefs_service.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/visit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../unit/privacy_persistence_test.dart' show FlakyPrefs;

DateTime _now() => DateTime(2026, 11, 23);

const _own = 'Is it safe to keep cycling to work?';
const _second = 'Can my partner come to the scan?';
const _guide = 'Could we check my iron?';
const _week = 'When will I feel movement?';

void main() {
  Future<AppState> start(Map<String, Object> extra) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-10',
      ...extra,
    });
    return AppState.load(now: _now);
  }

  Future<void> tapOn(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f.hitTestable());
    await t.pumpAndSettle();
  }

  Future<void> addTyped(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const ValueKey('visit-question-field')), text);
    await tapOn(t, find.text('Add question'));
  }

  testWidgets('a question typed on Today is there after a cold restart, '
      'with no check-ins done', (t) async {
    final state = await start({});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('visit-card')), findsNothing);
    await tapOn(t, find.byKey(const ValueKey('visit-invite')));
    await addTyped(t, '  $_own  ');
    await tapOn(t, find.byTooltip('Close visit list'));
    expect(state.completedCheckIns, isEmpty);
    await t.pumpWidget(const SizedBox());

    final cold = await AppState.load(now: _now);
    expect(cold.visitQuestions.single.text, _own);
    await t.pumpWidget(LittleBumpyApp(state: cold));
    await t.pumpAndSettle();
    final card = find.byKey(const ValueKey('visit-card'));
    await t.ensureVisible(card);
    expect(
      find.descendant(of: card, matching: find.text('“$_own”')),
      findsOneWidget,
    );
    expect(find.text('Show at my visit'), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-invite')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Today shows the newest own words and the show page puts '
      'own words first, each picked one with its origin line', (t) async {
    final handle = t.ensureSemantics();
    final state = await start({});
    await state.addVisitQuestion(_guide, need: MaternalNeed.iron);
    await state.addVisitQuestion(_own);
    await state.addVisitQuestion(_week, origin: VisitOrigin.week);
    await state.addVisitQuestion(_second);
    await state.saveVisitTopics({MaternalNeed.water, MaternalNeed.rest});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();

    final card = find.byKey(const ValueKey('visit-card'));
    await t.ensureVisible(card);
    // The newest of the parent's own questions, with no count of the rest.
    expect(
      find.descendant(of: card, matching: find.text('“$_second”')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('More on your list')),
      findsOneWidget,
    );
    expect(find.textContaining(RegExp(r'\d+ more')), findsNothing);
    await tapOn(t, find.text('Show at my visit'));

    expect(find.byType(VisitScreen), findsOneWidget);
    expect(find.text('My questions'), findsOneWidget);
    expect(find.byType(BottomNavigationBar).hitTestable(), findsNothing);
    final order = [
      find.text('My questions'),
      find.text(VisitScreen.ownWordsHeading),
      find.text(_own),
      find.text(_second),
      find.text(VisitScreen.pickedHeading),
      find.text(_guide),
      find.text('From the iron guide · 23 Nov'),
      find.text(_week),
      find.text('From week 16 · 23 Nov'),
      find.text('Topics'),
      find.text(MaternalNeed.water.label),
      find.text(MaternalNeed.rest.label),
      find.text('Copy my list'),
    ];
    for (var i = 0; i < order.length; i++) {
      expect(order[i], findsOneWidget, reason: '$i');
    }
    for (var i = 1; i < order.length; i++) {
      expect(
        t.getTopLeft(order[i]).dy,
        greaterThan(t.getTopLeft(order[i - 1]).dy),
        reason: '$i',
      );
    }
    // Own words carry no label; a picked one reads with its origin.
    expect(find.bySemanticsLabel(_own), findsOneWidget);
    expect(
      find.bySemanticsLabel('$_guide\nFrom the iron guide · 23 Nov'),
      findsOneWidget,
    );
    // Nothing numbers or ticks the questions.
    expect(find.text('1.'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    // Edit opens the list over the page; a removal shows at once.
    await tapOn(t, find.text('Edit'));
    await tapOn(
      t,
      find.descendant(
        of: find.byKey(const ValueKey('visit-question-$_second')),
        matching: find.byTooltip(RegExp('^Remove from visit list: ')),
      ),
    );
    await tapOn(t, find.byTooltip('Close visit list'));
    expect(find.text(_second), findsNothing);
    await tapOn(t, find.byTooltip('Close'));
    expect(find.byType(VisitScreen), findsNothing);
    expect(
      find.descendant(of: card, matching: find.text('“$_own”')),
      findsOneWidget,
    );
    handle.dispose();
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('the editor lists own words first and changing a picked '
      'question moves it to the parent’s own words', (t) async {
    final state = await start({});
    await state.addVisitQuestion(_guide, need: MaternalNeed.iron);
    await state.addVisitQuestion(_own);
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await tapOn(t, find.text('Show at my visit'));
    await tapOn(t, find.text('Edit'));

    final ownRow = find.byKey(const ValueKey('visit-question-$_own'));
    final guideRow = find.byKey(const ValueKey('visit-question-$_guide'));
    expect(t.getTopLeft(ownRow).dy, lessThan(t.getTopLeft(guideRow).dy));
    expect(find.byKey(const ValueKey('visit-origin-$_own')), findsNothing);
    expect(
      find.descendant(
        of: guideRow,
        matching: find.text('From the iron guide · 23 Nov'),
      ),
      findsOneWidget,
    );

    // Change the words of the picked question.
    await tapOn(
      t,
      find.descendant(
        of: guideRow,
        matching: find.byTooltip(RegExp('^Change the words: ')),
      ),
    );
    expect(find.text('Change the words'), findsOneWidget);
    expect(
      find.text('Once you change it, it sits with your own words.'),
      findsOneWidget,
    );
    const mine = 'Could we check my iron at this visit?';
    await t.enterText(find.byKey(const ValueKey('visit-edit-field')), mine);
    await tapOn(t, find.byKey(const ValueKey('visit-edit-save')));

    expect(state.hasVisitQuestion(_guide), isFalse);
    expect(state.visitQuestionsOwnFirst.map((q) => q.text), [_own, mine]);
    expect(state.visitQuestions.every((q) => q.isOwnWords), isTrue);
    expect(find.byKey(const ValueKey('visit-origin-$mine')), findsNothing);

    // Cancel leaves the words as they were.
    await tapOn(
      t,
      find.descendant(
        of: find.byKey(const ValueKey('visit-question-$mine')),
        matching: find.byTooltip(RegExp('^Change the words: ')),
      ),
    );
    expect(
      find.text('Once you change it, it sits with your own words.'),
      findsNothing,
    );
    await t.enterText(find.byKey(const ValueKey('visit-edit-field')), 'x');
    await tapOn(t, find.text('Cancel'));
    expect(state.hasVisitQuestion(mine), isTrue);

    // It stays in the parent's own words after a cold restart.
    final cold = await AppState.load(now: _now);
    final changed = cold.visitQuestions.singleWhere((q) => q.text == mine);
    expect(changed.origin, VisitOrigin.own);
    expect(changed.added, DateTime(2026, 11, 23));
    await tapOn(t, find.byTooltip('Close visit list'));
    expect(find.text(VisitScreen.pickedHeading), findsNothing);
    expect(find.text(mine), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Copy my list puts the whole list on the clipboard as plain '
      'text, own words first, and says so', (t) async {
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final state = await start({});
    await state.addVisitQuestion(_guide, need: MaternalNeed.iron);
    await state.addVisitQuestion(_own);
    await state.saveVisitTopics({MaternalNeed.water});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await tapOn(t, find.text('Show at my visit'));
    expect(
      find.ancestor(
        of: find.text('Copy my list'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton),
      ),
      findsOneWidget,
    );
    await tapOn(t, find.text('Copy my list'));
    expect(
      copied,
      'My questions\n'
      'Week 16\n'
      '\n'
      'In my own words\n'
      '- $_own\n'
      '\n'
      'Picked from Bumpy’s suggestions\n'
      '- $_guide\n'
      '\n'
      'Topics\n'
      '- Water\n',
    );
    expect(copied, VisitScreen.plainText(state));
    expect(find.text('Your list is copied.'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('an empty show page offers no copy', (t) async {
    final state = await start({});
    await t.pumpWidget(MaterialApp(home: VisitScreen(state: state)));
    await t.pumpAndSettle();
    expect(find.text('Copy my list'), findsNothing);
    expect(
      find.text('Nothing here yet. Tap Edit to add a question.'),
      findsOneWidget,
    );
  });

  testWidgets('the list adds several questions, trims, keeps one of each '
      'and removes', (t) async {
    final state = await start({});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await tapOn(t, find.byKey(const ValueKey('visit-invite')));
    await addTyped(t, '   ');
    expect(state.visitQuestions, isEmpty);
    await addTyped(t, _own);
    await addTyped(t, '  $_second ');
    await addTyped(t, _own);
    expect(find.text('That question is already on your list.'), findsOneWidget);
    expect(state.visitQuestions.map((q) => q.text), [_own, _second]);
    expect(find.byKey(const ValueKey('visit-question-$_own')), findsOneWidget);
    await tapOn(
      t,
      find.descendant(
        of: find.byKey(const ValueKey('visit-question-$_own')),
        matching: find.byTooltip(RegExp('^Remove from visit list: ')),
      ),
    );
    expect(find.byKey(const ValueKey('visit-question-$_own')), findsNothing);
    expect(
      (await AppState.load(now: _now)).visitQuestions.single.text,
      _second,
    );
    // Typed words left in the box are kept by "Save visit list" too.
    await t.enterText(find.byKey(const ValueKey('visit-question-field')), _own);
    await tapOn(t, find.byKey(const ValueKey('visit-topic-water')));
    await tapOn(t, find.text('Save visit list'));
    // The sheet closes and says, calmly, that the list landed.
    expect(find.text('Save visit list'), findsNothing);
    expect(find.text('Your visit list is saved.'), findsOneWidget);
    final cold = await AppState.load(now: _now);
    expect(cold.visitQuestions.map((q) => q.text), [_second, _own]);
    expect(cold.visitTopics, {MaternalNeed.water});
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('a save that does not land keeps the words and says so calmly', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final disk = await SharedPreferences.getInstance();
    final flaky = FlakyPrefs(disk)..failVisit = true;
    final state = AppState.withPrefs(PrefsService.wrap(flaky), now: _now);
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await tapOn(t, find.byKey(const ValueKey('visit-invite')));
    await addTyped(t, _own);
    expect(
      find.textContaining('couldn’t be saved on this device'),
      findsOneWidget,
    );
    expect(
      t
          .widget<TextFormField>(
            find.byKey(const ValueKey('visit-question-field')),
          )
          .controller!
          .text,
      _own,
    );
    expect(state.visitQuestions, isEmpty);
    flaky.failVisit = false;
    await tapOn(t, find.text('Add question'));
    expect(find.textContaining('couldn’t be saved'), findsNothing);
    expect(state.visitQuestions.single.text, _own);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Pause hides the whole visit list at once and Erase removes it', (
    t,
  ) async {
    final state = await start({});
    await state.addVisitQuestion(_own);
    await state.saveVisitTopics({MaternalNeed.iron});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await tapOn(t, find.text('Show at my visit'));
    await tapOn(t, find.text('Edit'));
    await tapOn(t, find.byTooltip('Pause').hitTestable());
    expect(find.text('Everything is paused.'), findsOneWidget);
    expect(find.text(_own), findsNothing);
    expect(find.text('My questions'), findsNothing);
    expect(find.text('For your visit'), findsNothing);
    expect(find.byType(VisitScreen), findsNothing);

    await tapOn(t, find.widgetWithText(TextButton, 'Erase all data'));
    await tapOn(t, find.text('Yes, erase'));
    expect(state.isFirstRun, isTrue);
    expect(find.text(_own), findsNothing);
    final cold = await AppState.load(now: _now);
    expect(cold.visitQuestions, isEmpty);
    expect(cold.visitTopics, isEmpty);
    await t.pumpWidget(const SizedBox());
  });

  for (final halloween in [false, true]) {
    testWidgets('320 px and 200 percent text fit Today, the show page and '
        'the editor (${halloween ? 'Halloween' : 'Everyday'})', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(320, 568);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final state = await start({'is_halloween': halloween});
      await state.addVisitQuestion(
        'Is it all right to keep cycling to work every morning until the '
        'third trimester, or would walking be gentler?',
      );
      await state.addVisitQuestion(_second);
      await state.saveVisitTopics({MaternalNeed.vitamin});
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await tapOn(t, find.text('Show at my visit'));
      expect(t.takeException(), isNull);
      final palette = halloween ? AppPalette.halloween : AppPalette.everyday;
      final title = t.widget<Text>(find.text('My questions'));
      expect(title.style!.color, palette.ink);
      expect(t.getSize(find.byTooltip('Close')).shortestSide, 48);
      await t.dragUntilVisible(
        find.text(needWord(MaternalNeed.vitamin)),
        find.descendant(
          of: find.byType(VisitScreen),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -200),
      );
      await tapOn(t, find.text('Edit'));
      expect(t.takeException(), isNull);
      await tapOn(t, find.byTooltip('Close visit list'));
      await tapOn(t, find.byTooltip('Close'));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
