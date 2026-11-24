import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/core/theme/paper.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:little_bumpy/presentation/screens/visit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Polish lane D, from design critique 4: the "Show at my visit" page puts
// each question on its own paper slip with a full-width Copy button, and the
// first-run date step marks the chosen way with an outline, not a fill.

final _today = DateTime(2026, 11, 23);

const _own = 'Can my partner come in with me for the scan?';
const _picked = 'Could we check my iron?';

Future<void> _phone(WidgetTester t, Size size, {double text = 1}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.reset);
  if (text != 1) {
    t.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }
}

Future<AppState> _state({required bool halloween, String? due}) async {
  SharedPreferences.setMockInitialValues({
    'due_date_iso': ?due,
    'is_halloween': halloween,
  });
  return AppState.load(now: () => _today);
}

double _ratio(Color x, Color y) {
  final a = x.computeLuminance();
  final b = y.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

Border _border(WidgetTester t, int i) {
  final c = t.widget<Container>(find.byKey(ValueKey('way-choice-$i')));
  return (c.decoration! as BoxDecoration).border! as Border;
}

void main() {
  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    final palette = halloween ? AppPalette.halloween : AppPalette.everyday;

    Future<void> showView(WidgetTester t) async {
      final state = await _state(halloween: halloween, due: '2027-05-10');
      await state.addVisitQuestion(_picked, need: MaternalNeed.iron);
      await state.addVisitQuestion(_own);
      await state.saveVisitTopics({MaternalNeed.rest});
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(palette),
          home: VisitScreen(state: state),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('show view: each question on its own raised paper slip, in '
        'the large type ($look)', (t) async {
      await _phone(t, const Size(375, 812));
      await showView(t);
      for (final q in [_own, _picked]) {
        final card = find.byKey(ValueKey('visit-show-card-$q'));
        expect(card, findsOneWidget, reason: q);
        expect(t.widget<PaperCard>(card).raised, isTrue, reason: q);
        final text = find.descendant(of: card, matching: find.text(q));
        expect(text, findsOneWidget, reason: q);
        expect(t.widget<Text>(text).style!.fontSize, 24, reason: q);
      }
      final a = t.getRect(find.byKey(const ValueKey('visit-show-card-$_own')));
      final b = t.getRect(
        find.byKey(const ValueKey('visit-show-card-$_picked')),
      );
      expect(a.overlaps(b), isFalse);
      expect(a.width, b.width);
      await t.pumpWidget(const SizedBox());
    });

    for (final size in [const Size(375, 812), const Size(320, 568)]) {
      for (final text in [1.0, 2.0]) {
        testWidgets('show view: Copy my list is full width and 48 tall, no '
            'overflow at ${size.width.toInt()} px, ${(text * 100).toInt()} '
            'percent text ($look)', (t) async {
          await _phone(t, size, text: text);
          await showView(t);
          expect(t.takeException(), isNull);
          final copy = find.byKey(const ValueKey('visit-copy'));
          await t.ensureVisible(copy);
          await t.pumpAndSettle();
          final r = t.getRect(copy);
          // The page's side margins are 24 each.
          expect(r.width, closeTo(size.width - 2 * AppSpace.xl, 0.5));
          expect(r.height, greaterThanOrEqualTo(AppSpace.target));
          final card = t.getRect(
            find.byKey(const ValueKey('visit-show-card-$_own')),
          );
          expect(card.width, closeTo(r.width, 0.5));
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        });
      }
    }

    Future<void> dateStep(WidgetTester t, Size size, double text) async {
      await _phone(t, size, text: text);
      final state = await _state(halloween: halloween);
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(palette),
          home: FirstRunScreen(state: state),
        ),
      );
      await t.pumpAndSettle();
      final start = find.text('Start');
      await t.ensureVisible(start);
      await t.pumpAndSettle();
      await t.tap(start);
      await t.pumpAndSettle();
    }

    testWidgets('date step: the chosen way is an outline with a tick, not a '
        'filled block, and is heard as selected ($look)', (t) async {
      final handle = t.ensureSemantics();
      await dateStep(t, const Size(375, 812), 1);
      final chosen = t.widget<Container>(
        find.byKey(const ValueKey('way-choice-0')),
      );
      expect((chosen.decoration! as BoxDecoration).color, isNull);
      expect(_border(t, 0).top.width, 2);
      expect(_border(t, 0).top.color, isNot(Colors.transparent));
      // The outline stands out from the night sky by at least 3:1.
      expect(
        _ratio(_border(t, 0).top.color, palette.skyTop),
        greaterThanOrEqualTo(3),
      );
      // The tick is there, so the choice never rests on colour alone.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('way-choice-0')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(_border(t, 1).top.color, Colors.transparent);
      // No way is painted as a filled accent block.
      for (final i in [0, 1, 2]) {
        final c = t.widget<Container>(find.byKey(ValueKey('way-choice-$i')));
        expect((c.decoration! as BoxDecoration).color, isNot(palette.accent));
        expect(
          t.getSize(find.byKey(ValueKey('way-choice-$i'))).height,
          greaterThanOrEqualTo(48),
        );
      }
      // Screen readers hear which way is chosen.
      expect(
        t
            .getSemantics(find.bySemanticsLabel('I know my due date'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      // Choosing another way moves the outline and the selected state.
      await t.tap(find.text('I know how many weeks'));
      await t.pumpAndSettle();
      expect(_border(t, 1).top.color, isNot(Colors.transparent));
      expect(_border(t, 0).top.color, Colors.transparent);
      expect(
        t
            .getSemantics(find.bySemanticsLabel('I know how many weeks'))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('date step: no overflow at 320 px and 200 percent text '
        '($look)', (t) async {
      await dateStep(t, const Size(320, 568), 2);
      expect(t.takeException(), isNull);
      for (final i in [0, 1, 2]) {
        final r = t.getRect(find.byKey(ValueKey('way-choice-$i')));
        expect(r.right, lessThanOrEqualTo(320));
        expect(r.left, greaterThanOrEqualTo(0));
      }
    });
  }
}
