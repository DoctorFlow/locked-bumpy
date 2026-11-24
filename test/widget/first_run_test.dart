import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _freshState() async {
  SharedPreferences.setMockInitialValues({'is_halloween': true});
  return AppState.load();
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

void main() {
  group('FirstRunScreen', () {
    testWidgets('step 1 renders hello message and date picker', (tester) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pump();

      expect(find.text('Hello, Little Bumpy.'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
      expect(find.text('Last Period'), findsOneWidget);
      expect(find.text('Choose due date'), findsOneWidget);
      expect(find.text('Enter the nursery'), findsNothing);
    });

    testWidgets('shows gestational week preview after a date is chosen', (
      tester,
    ) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pump();

      // No preview chip before a date is picked.
      expect(find.textContaining('You are at week'), findsNothing);

      await tester.tap(find.text('Last Period'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose period start date'));
      await tester.tap(find.text('Choose period start date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('You are at week 20 right now.'), findsOneWidget);
    });

    testWidgets('medical disclaimer present on step 1', (tester) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pump();

      expect(
        find.text(
          'This app is not medical advice. '
          'If you are worried about anything, call your doctor.',
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
        await tester.tap(find.text('Try daylight'));
        await tester.pumpAndSettle();
        expect(find.text('Try moonlight'), findsOneWidget);
        expect(state.isFirstRun, isTrue);
      },
    );

    testWidgets('step 3 shows both look cards', (tester) async {
      final state = await _freshState();
      await tester.pumpWidget(_wrap(state));
      await tester.pump();

      tester.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(2);
      await tester.pumpAndSettle();
      expect(find.text('Halloween'), findsOneWidget);
      expect(find.text('Everyday'), findsOneWidget);
      await tester.tap(find.text('Everyday'));
      await tester.pumpAndSettle();
      // Looking at a choice is reversible until the final confirmation.
      expect(state.isHalloween, isTrue);
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
