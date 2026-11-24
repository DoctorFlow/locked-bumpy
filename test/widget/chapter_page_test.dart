import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/chapter_loader.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chapter_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final kites = chapterRecord();
  final lanterns = chapterRecord(
    id: 'chapter_20',
    from: 20,
    to: 23,
    title: 'Lantern night',
    accent: '#F2A65A',
    illustration: 'chapter-lanterns',
    status: 'draft',
    approvedBy: '',
    approvedDate: '',
    suggested: '',
  );

  tearDown(() {
    ChapterLoader.debugUse(null);
    ChapterLoader.debugReviewBuild = null;
  });

  /// Current week is 16, inside the kites chapter (16 to 19).
  Future<AppState> openThisWeek(
    WidgetTester t, {
    bool halloween = false,
    bool review = false,
  }) async {
    ChapterLoader.debugUse(ChapterLoader.parse(chapterJson([kites, lanterns])));
    ChapterLoader.debugReviewBuild = review;
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-11',
      'is_halloween': halloween,
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 24));
    if (state.isHalloween != halloween) await state.toggleMode();
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('This Week'));
    await t.pumpAndSettle();
    return state;
  }

  testWidgets('a chapter page reads in the storybook order', (t) async {
    await openThisWeek(t);
    final order = [
      'Paper kites',
      'Weeks 16 to 19',
      'I folded a tiny paper kite today.',
      'One thing to know',
      'Source: Test Kite Club',
      'Week 16',
      'One thing to get ready',
      'Something to look forward to',
    ];
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Draft'), findsNothing);
    final positions = <double>[];
    for (final text in order) {
      final inPage = find.descendant(
        of: find.byType(PageView),
        matching: find.text(text),
      );
      positions.add(t.getTopLeft(inPage.first).dy);
    }
    for (var i = 1; i < positions.length; i++) {
      expect(positions[i], greaterThan(positions[i - 1]), reason: order[i]);
    }
    expect(find.text('One thing to get ready'), findsOneWidget);
    expect(find.text('My question for the visit'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('one tap adds the question to the visit list', (t) async {
    final state = await openThisWeek(t);
    const question = 'Which ribbon colour is the brightest?';
    final add = find.text('Add to my visit list');
    await t.ensureVisible(add);
    await t.pumpAndSettle();
    await t.tap(add);
    await t.pumpAndSettle();
    expect(state.hasVisitQuestion(question), isTrue);
    expect(find.text('On your visit list'), findsOneWidget);
    expect(find.text('Add to my visit list'), findsNothing);
    expect(find.text('Write my own question'), findsOneWidget);
  });

  testWidgets('the curious question opens the guides', (t) async {
    final state = await openThisWeek(t);
    final link = find.text('How long can a kite string be?');
    await t.ensureVisible(link);
    await t.pumpAndSettle();
    await t.tap(link);
    await t.pumpAndSettle();
    expect(state.currentTab, 2);
  });

  testWidgets('a week without a chapter keeps the card and invitation', (
    t,
  ) async {
    await openThisWeek(t);
    await t.tap(find.byIcon(Icons.arrow_back_ios_new));
    await t.pumpAndSettle();
    expect(find.text('Week 15'), findsOneWidget);
    expect(find.text('My question for the visit'), findsOneWidget);
    expect(find.text('Paper kites'), findsNothing);
  });

  testWidgets('a draft chapter is hidden outside a review build', (t) async {
    await openThisWeek(t);
    await t.tap(find.text('Choose week'));
    await t.pumpAndSettle();
    await t.tap(find.text('21'));
    await t.pumpAndSettle();
    expect(find.text('Lantern night'), findsNothing);
    expect(find.text('Week 21'), findsOneWidget);
  });

  testWidgets('a review build shows the draft with its tag and colour', (
    t,
  ) async {
    await openThisWeek(t, review: true);
    Color band(String title) => t
        .widget<ColoredBox>(
          find
              .ancestor(of: find.text(title), matching: find.byType(ColoredBox))
              .first,
        )
        .color;
    final kitesColour = band('Paper kites');
    await t.tap(find.text('Choose week'));
    await t.pumpAndSettle();
    await t.tap(find.text('21'));
    await t.pumpAndSettle();
    expect(find.text('Lantern night'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Add to my visit list'), findsNothing);
    expect(band('Lantern night'), isNot(kitesColour));
    expect(band('Lantern night'), const Color(0xFFF2A65A));
  });

  for (final halloween in [false, true]) {
    testWidgets(
      'fits 320 px at 200 percent text (${halloween ? 'Halloween' : 'Everyday'})',
      (t) async {
        t.view.physicalSize = const Size(320, 640);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await openThisWeek(t, halloween: halloween);
        expect(find.text('Paper kites'), findsOneWidget);
        for (final text in [
          'One thing to get ready',
          'Add to my visit list',
          'How long can a kite string be?',
        ]) {
          await t.ensureVisible(find.text(text));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), isNull);
        final button = find.ancestor(
          of: find.text('Add to my visit list'),
          matching: find.byType(FilledButton),
        );
        expect(t.getSize(button).height, greaterThanOrEqualTo(48));
      },
    );
  }

  testWidgets('chapter headings are announced as headings', (t) async {
    final handle = t.ensureSemantics();
    await openThisWeek(t);
    for (final heading in [
      'Paper kites',
      'One thing to know',
      'One thing to get ready',
      'Something to look forward to',
    ]) {
      await t.ensureVisible(find.text(heading));
      await t.pumpAndSettle();
      expect(
        t.getSemantics(find.text(heading)),
        matchesSemantics(label: heading, isHeader: true),
      );
    }
    handle.dispose();
  });
}
