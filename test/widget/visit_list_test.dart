import 'package:flutter/material.dart';
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
      find.descendant(of: card, matching: find.text(_own)),
      findsOneWidget,
    );
    expect(find.text('Show at my visit'), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-invite')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('Today puts the parent’s own words first and the show page '
      'lists everything in order', (t) async {
    final handle = t.ensureSemantics();
    final state = await start({});
    await state.addVisitQuestion(_guide, need: MaternalNeed.iron);
    await state.addVisitQuestion(_own);
    await state.addVisitQuestion(_second);
    await state.saveVisitTopics({MaternalNeed.water, MaternalNeed.rest});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();

    final card = find.byKey(const ValueKey('visit-card'));
    await t.ensureVisible(card);
    expect(
      find.descendant(of: card, matching: find.text(_own)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('And 4 more on your list')),
      findsOneWidget,
    );
    await tapOn(t, find.text('Show at my visit'));

    expect(find.byType(VisitScreen), findsOneWidget);
    expect(find.text('My questions'), findsOneWidget);
    expect(find.byType(BottomNavigationBar).hitTestable(), findsNothing);
    final order = [
      find.text('My questions'),
      find.text(_guide),
      find.text(_own),
      find.text(_second),
      find.text('Topics'),
      find.text(MaternalNeed.water.label),
      find.text(MaternalNeed.rest.label),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(
        t.getTopLeft(order[i]).dy,
        greaterThan(t.getTopLeft(order[i - 1]).dy),
        reason: '$i',
      );
    }
    expect(find.bySemanticsLabel('1.\n$_guide'), findsOneWidget);
    expect(find.bySemanticsLabel('2.\n$_own'), findsOneWidget);
    expect(find.bySemanticsLabel('3.\n$_second'), findsOneWidget);

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
    expect(find.bySemanticsLabel('2.\n$_own'), findsOneWidget);
    await tapOn(t, find.byTooltip('Close'));
    expect(find.byType(VisitScreen), findsNothing);
    expect(find.text('And 3 more on your list'), findsOneWidget);
    handle.dispose();
    await t.pumpWidget(const SizedBox());
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
