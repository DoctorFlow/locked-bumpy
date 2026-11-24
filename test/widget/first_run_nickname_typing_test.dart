import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pick_date_helper.dart';

/// The first-run nickname field takes typing, whether it is reached by a
/// tap or by the accessibility tree's focus action, keeps it while the
/// parent goes on, and the name is the one the app then uses.

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<AppState> _toNickname(
  WidgetTester tester, {
  required bool halloween,
}) async {
  SharedPreferences.setMockInitialValues({'is_halloween': halloween});
  final state = await AppState.load(now: () => DateTime(2026, 11, 24));
  await tester.pumpWidget(LittleBumpyApp(state: state));
  await tester.pumpAndSettle();
  await _tap(tester, find.text('Start'));
  await _tap(tester, find.text('Choose due date'));
  await chooseDateInPicker(tester, dueIn140(state.today));
  await _tap(tester, find.text('Next'));
  expect(find.text('Give the baby a nickname?'), findsOneWidget);
  return state;
}

Future<void> _finish(WidgetTester tester) async {
  await _tap(tester, find.text('Next').hitTestable());
  await _tap(tester, find.text('Next').hitTestable());
  await _tap(tester, find.text('Meet Bumpy'));
}

void main() {
  for (final halloween in [true, false]) {
    final look = halloween ? 'Halloween' : 'Everyday';

    testWidgets('$look: a tap on the nickname field takes typing and the '
        'name is carried into the app', (tester) async {
      final state = await _toNickname(tester, halloween: halloween);
      final field = find.byType(EditableText);
      await _tap(tester, field);
      final node = tester.widget<EditableText>(field).focusNode;
      expect(node.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);

      tester.testTextInput.enterText('Peanut');
      await tester.pumpAndSettle();
      // Bumpy's name tag and the counter follow the typing.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('first-run-name-tag')),
          matching: find.text('Peanut'),
        ),
        findsOneWidget,
      );
      expect(find.text('6/24'), findsOneWidget);
      // Still focused a moment later: nothing takes the field away.
      await tester.pump(const Duration(milliseconds: 500));
      expect(node.hasFocus, isTrue);

      await _finish(tester);
      expect(state.isFirstRun, isFalse);
      expect(state.nickname, 'Peanut');
      expect(state.babyDisplayName, 'Peanut');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('$look: focus from the accessibility tree holds and takes '
        'typing', (tester) async {
      final handle = tester.ensureSemantics();
      final state = await _toNickname(tester, halloween: halloween);
      final field = find.byType(EditableText);
      tester.semantics.performAction(
        find.semantics.byPredicate(
          (n) => n.getSemanticsData().flagsCollection.isTextField,
        ),
        SemanticsAction.focus,
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester
              .getSemantics(field)
              .getSemanticsData()
              .flagsCollection
              .isFocused,
          Tristate.isTrue,
          reason: 'frame $i',
        );
      }
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.testTextInput.enterText('Sprout');
      await tester.pumpAndSettle();
      expect(find.text('6/24'), findsOneWidget);
      await _finish(tester);
      expect(state.nickname, 'Sprout');
      handle.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  }
}
