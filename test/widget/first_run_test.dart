import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pick_date_helper.dart';

const _welcome = 'Hello, I’m your Little Bumpy.';
const _whatItIs =
    'I dress up as six everyday needs, share a chapter each week, '
    'and keep your questions for your doctor or midwife.';
const _private = 'Private: everything stays on this device.';

Future<AppState> _freshState({bool halloween = true}) async {
  SharedPreferences.setMockInitialValues({'is_halloween': halloween});
  return AppState.load(now: () => DateTime(2026, 11, 23));
}

Widget _wrap(AppState state) {
  final palette = state.isHalloween
      ? AppPalette.halloween
      : AppPalette.everyday;
  return MaterialApp(
    theme: ThemeData(extensions: [palette]),
    home: FirstRunScreen(state: state),
  );
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _pickDueDate(WidgetTester tester) async {
  await _tap(tester, find.text('Choose due date'));
  await chooseDateInPicker(tester, dueIn140(DateTime(2026, 11, 23)));
}

Finder _asset(String path) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is AssetImage &&
      (w.image as AssetImage).assetName == 'assets/images/$path.png',
);

void main() {
  group('FirstRunScreen', () {
    testWidgets('Pause before choosing a date survives relaunch', (
      tester,
    ) async {
      final state = await _freshState();
      await tester.pumpWidget(LittleBumpyApp(state: state));
      await tester.pumpAndSettle();

      final pause = find.byTooltip('Pause');
      expect(tester.getSize(pause).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(pause);
      await tester.pumpAndSettle();
      expect(find.text('Everything is paused.'), findsOneWidget);
      expect(find.text('Start Fresh'), findsNothing);
      expect(find.text(_welcome), findsNothing);

      await tester.pumpWidget(const SizedBox());
      final restored = await AppState.load();
      expect(restored.dueDate, isNull);
      await tester.pumpWidget(LittleBumpyApp(state: restored));
      await tester.pumpAndSettle();
      expect(find.text('Everything is paused.'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.text(_welcome), findsOneWidget);
      expect((await AppState.load()).isPaused, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'the welcome says what the app is, privately, with one button',
      (tester) async {
        final state = await _freshState();
        await tester.pumpWidget(_wrap(state));
        await tester.pumpAndSettle();

        expect(find.text(_welcome), findsOneWidget);
        expect(find.text(_whatItIs), findsOneWidget);
        expect(find.text(_private), findsOneWidget);
        expect(find.text('1 of 5'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Back'), findsNothing);
        expect(
          find.bySemanticsLabel('Bumpy in a vampire costume, smiling'),
          findsOneWidget,
        );
        expect(
          tester
              .getSemantics(find.text(_welcome))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        expect(find.text('Choose due date'), findsNothing);
      },
    );

    testWidgets('step 2 asks for the date and holds Next until one is chosen', (
      tester,
    ) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));

      expect(find.text('2 of 5'), findsOneWidget);
      expect(find.text('When am I due?'), findsOneWidget);
      expect(find.text('Due date'), findsOneWidget);
      expect(find.text('Last period'), findsOneWidget);
      expect(find.text('Choose due date'), findsOneWidget);
      final next = find.widgetWithText(ElevatedButton, 'Next');
      expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
      await _pickDueDate(tester);
      expect(tester.widget<ElevatedButton>(next).onPressed, isNotNull);
    });

    testWidgets('the date picker opens with no day chosen, and OK alone '
        'saves nothing and says why', (tester) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));
      await _tap(tester, find.text('Choose due date'));

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(dialog.initialDate, isNull);
      // OK with no day stays open and says why, next to the buttons.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text('Pick a day first'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.text('Choose due date'), findsOneWidget);
      expect(find.textContaining('You are at week'), findsNothing);
      final next = find.widgetWithText(ElevatedButton, 'Next');
      expect(tester.widget<ElevatedButton>(next).onPressed, isNull);

      // A chosen day opens selected the next time.
      await _tap(tester, find.text('Choose due date'));
      await chooseDateInPicker(tester, dueIn140(DateTime(2026, 11, 23)));
      expect(tester.widget<ElevatedButton>(next).onPressed, isNotNull);
      await _tap(tester, find.text('Apr 12, 2027'));
      expect(
        tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .initialDate,
        DateTime(2027, 4, 12),
      );
    });

    testWidgets('OK in the date picker stays dimmed until a day is tapped', (
      tester,
    ) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));
      await _tap(tester, find.text('Choose due date'));

      Color okColor() => DefaultTextStyle.of(
        tester.element(find.text('OK')),
      ).style.color!;
      final cancelColor = DefaultTextStyle.of(
        tester.element(find.text('Cancel')),
      ).style.color!;
      // Dimmed while empty: not the same as Cancel's full colour.
      expect(okColor(), isNot(cancelColor));
      expect(okColor().a, lessThan(1));
      expect(find.text('Pick a day first'), findsNothing);

      // A day tapped in the calendar lights OK, and OK saves it.
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').hitTestable().first);
      await tester.pumpAndSettle();
      expect(okColor(), cancelColor);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.text('Dec 15, 2026'), findsOneWidget);
      final next = find.widgetWithText(ElevatedButton, 'Next');
      expect(tester.widget<ElevatedButton>(next).onPressed, isNotNull);
    });

    for (final halloween in [false, true]) {
      testWidgets('the waiting "Next" is readable in '
          '${halloween ? 'Halloween' : 'Everyday'}', (tester) async {
        final state = await _freshState(halloween: halloween);
        await tester.pumpWidget(_wrap(state));
        await tester.pumpAndSettle();
        await _tap(tester, find.text('Start'));
        final next = find.widgetWithText(ElevatedButton, 'Next');
        final button = tester.widget<ElevatedButton>(next);
        expect(button.onPressed, isNull);
        const disabled = {WidgetState.disabled};
        final fg = button.style!.foregroundColor!.resolve(disabled)!;
        final bg = button.style!.backgroundColor!.resolve(disabled)!;
        double lum(Color c) => c.computeLuminance();
        final hi = lum(Color.alphaBlend(fg, bg)) > lum(bg)
            ? lum(Color.alphaBlend(fg, bg))
            : lum(bg);
        final lo = lum(Color.alphaBlend(fg, bg)) > lum(bg)
            ? lum(bg)
            : lum(Color.alphaBlend(fg, bg));
        expect((hi + .05) / (lo + .05), greaterThanOrEqualTo(3));
        // It says why it waits.
        final data = tester.getSemantics(next).getSemanticsData();
        expect(data.label, 'Next');
        expect(data.hint, 'Choose a date first');
      });
    }

    testWidgets('shows gestational week preview after a date is chosen', (
      tester,
    ) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));

      // No preview chip before a date is picked.
      expect(find.textContaining('You are at week'), findsNothing);

      await tester.tap(find.text('Last period'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose period start date'));
      await tester.tap(find.text('Choose period start date'));
      await tester.pumpAndSettle();
      await chooseDateInPicker(tester, periodBack140(DateTime(2026, 11, 23)));
      expect(find.text('You are at week 20 right now.'), findsOneWidget);
      await tester.tap(find.text('Due date'));
      await tester.pumpAndSettle();
      expect(find.text('Choose due date'), findsOneWidget);
      await tester.tap(find.text('Last period'));
      await tester.pumpAndSettle();
      expect(find.text('You are at week 20 right now.'), findsOneWidget);
    });

    testWidgets('medical disclaimer present on the date step', (tester) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));

      expect(
        find.text(
          'This app is not medical advice. '
          'If you are worried about anything, call your doctor or midwife.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'the welcome screen lets a parent try the nursery lamp before sharing a date',
      (tester) async {
        final state = await _freshState();
        await tester.pumpWidget(_wrap(state));
        await tester.pumpAndSettle();
        final lamp = find.text('Try daylight');
        expect(
          tester
              .getSize(
                find.ancestor(of: lamp, matching: find.byType(FilledButton)),
              )
              .shortestSide,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(lamp);
        await tester.pumpAndSettle();
        expect(find.text('Try moonlight'), findsOneWidget);
        expect(state.isFirstRun, isTrue);
      },
    );

    testWidgets('step 4 shows both look cards', (tester) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pump();

      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(3);
      await tester.pumpAndSettle();
      expect(find.text('4 of 5'), findsOneWidget);
      expect(find.text('Halloween'), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);
      await tester.tap(find.text('Everyday'));
      await tester.pumpAndSettle();
      // Looking at a choice is reversible until the final confirmation.
      expect(state.isHalloween, isTrue);
    });

    for (final halloween in [true, false]) {
      final look = halloween ? 'Halloween' : 'Everyday';
      testWidgets('step 5 shows the six needs in the $look look', (
        tester,
      ) async {
        final state = await _freshState(halloween: halloween);
        await tester.pumpWidget(_wrap(state));
        await tester.pump();
        tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .jumpToPage(4);
        await tester.pumpAndSettle();

        expect(find.text('5 of 5'), findsOneWidget);
        expect(
          find.text(
            halloween
                ? 'Six costumes, six everyday needs'
                : 'Six everyday needs',
          ),
          findsOneWidget,
        );
        for (final need in MaternalNeed.values) {
          final tile = find.byKey(ValueKey('first-run-need-${need.name}'));
          expect(tile, findsOneWidget);
          expect(
            find.descendant(of: tile, matching: find.text(need.label)),
            findsOneWidget,
          );
          final picture = halloween
              ? 'body-${need.costume.toLowerCase()}'
              : 'need-${need.name}';
          expect(
            find.descendant(of: tile, matching: _asset(picture)),
            findsOneWidget,
            reason: '${need.name} picture in $look',
          );
        }
        // Six needs only: no amounts, foods or explanations on this step.
        for (final need in MaternalNeed.values) {
          expect(find.textContaining(need.foodHint), findsNothing);
        }
        expect(find.text('Meet Bumpy'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
      });
    }

    testWidgets('tapping straight through finishes and saves the choices', (
      tester,
    ) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));
      await _pickDueDate(tester);
      await _tap(tester, find.text('Next'));
      expect(find.text('3 of 5'), findsOneWidget);
      await _tap(tester, find.text('Next'));
      expect(find.text('4 of 5'), findsOneWidget);
      await _tap(tester, find.text('Next'));
      expect(find.text('5 of 5'), findsOneWidget);
      expect(state.isFirstRun, isTrue);
      final enter = find.text('Meet Bumpy');
      await tester.ensureVisible(enter);
      await tester.pumpAndSettle();
      await tester.tap(enter);
      // Outside the app shell the screen keeps its saving spinner turning.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(state.isFirstRun, isFalse);
      expect(state.isHalloween, isTrue);
      expect(state.nickname, '');
    });

    testWidgets('Back and the system back both work on every step', (
      tester,
    ) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Start'));
      await _pickDueDate(tester);
      await _tap(tester, find.text('Next'));
      await _tap(tester, find.text('Next'));
      await _tap(tester, find.text('Next'));
      expect(find.text('5 of 5'), findsOneWidget);
      for (final expected in ['4 of 5', '3 of 5', '2 of 5', '1 of 5']) {
        await _tap(tester, find.text('Back'));
        expect(find.text(expected), findsOneWidget);
      }
      // The picked date survives going back and forward.
      await _tap(tester, find.text('Start'));
      expect(find.text('Choose due date'), findsNothing);
      await _tap(tester, find.text('Next'));
      await _tap(tester, find.text('Next'));
      expect(find.text('4 of 5'), findsOneWidget);
      for (final expected in ['3 of 5', '2 of 5', '1 of 5']) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
      }
      expect(state.isFirstRun, isTrue);
    });

    testWidgets(
      'parity: FirstRunScreen renders same step-1 structure in both modes',
      (tester) async {
        // Halloween
        SharedPreferences.setMockInitialValues({'is_halloween': true});
        final halloween = await AppState.load();
        await tester.pumpWidget(_wrap(halloween));
        await tester.pump();
        final hwInkWells = tester
            .widgetList(find.byType(GestureDetector))
            .length;

        // Everyday
        SharedPreferences.setMockInitialValues({'is_halloween': false});
        final everyday = await AppState.load();
        await tester.pumpWidget(_wrap(everyday));
        await tester.pump();
        final ewInkWells = tester
            .widgetList(find.byType(GestureDetector))
            .length;

        expect(hwInkWells, equals(ewInkWells));
      },
    );

    testWidgets('new first-run words keep the voice rules', (tester) async {
      const banned = [
        'should',
        'must',
        'need to',
        'have to',
        'missed',
        'forgot',
        'failed',
        'weight',
        'diet',
        'lesson',
        'learn',
        'teach',
      ];
      for (final halloween in [true, false]) {
        final state = await _freshState(halloween: halloween);
        await tester.pumpWidget(_wrap(state));
        await tester.pumpAndSettle();
        for (var page = 0; page < 5; page++) {
          tester
              .widget<PageView>(find.byType(PageView))
              .controller!
              .jumpToPage(page);
          await tester.pumpAndSettle();
          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            final words = (text.data ?? '').toLowerCase();
            for (final word in banned) {
              expect(
                RegExp('\\b$word\\b').hasMatch(words),
                isFalse,
                reason: '"$word" in "${text.data}"',
              );
            }
            // "doctor" never stands alone in the new lines.
            if (words.contains('doctor') && !words.contains('not medical')) {
              expect(words, contains('doctor or midwife'));
            }
          }
        }
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('AppState nickname', () {
    test('defaults to empty string', () async {
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load();
      expect(state.nickname, equals(''));
      expect(state.babyDisplayName, equals('Little Bumpy'));
    });

    test('saveNickname persists and updates babyDisplayName', () async {
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load();
      await state.saveNickname('Peanut');
      expect(state.nickname, equals('Peanut'));
      expect(state.babyDisplayName, equals('Peanut'));
    });

    test('saveNickname trims whitespace', () async {
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load();
      await state.saveNickname('  Sprout  ');
      expect(state.nickname, equals('Sprout'));
    });

    test('empty nickname keeps default display name', () async {
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load();
      await state.saveNickname('   ');
      expect(state.babyDisplayName, equals('Little Bumpy'));
    });
  });
}
