import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/core/theme/paper.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/visit_screen.dart';
import 'package:little_bumpy/presentation/sheets/closet_sheet.dart';
import 'package:little_bumpy/presentation/widgets/app_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The wardrobe grid, the Guides list, the Paused page, the show-at-visit
/// page, Settings and the visit-list save note, at the sizes where they
/// used to break (design critique 2, a11y audit 2, lab round 2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await ContentLoader.load('assets/content/today_lines.json');
    // The real faces, so word widths and line breaks match a phone (the
    // test font draws every letter as a 1 em square).
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
  tearDown(() => ContentLoader.debugSetGuides(null));

  void phone(WidgetTester t, Size size, {double text = 1}) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    t.platformDispatcher.textScaleFactorTestValue = text;
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<AppState> boot(Map<String, Object> extra) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-10',
      ...extra,
    });
    return AppState.load(now: () => DateTime(2026, 11, 23)); // IRON day
  }

  /// Fails when any word of [text] is drawn across two lines.
  void expectWholeWords(WidgetTester t, String text) {
    final paragraph = t.renderObject<RenderParagraph>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    );
    for (final m in RegExp(r'\S+').allMatches(text)) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: m.start, extentOffset: m.end),
      );
      final tops = boxes.map((b) => b.top.round()).toSet();
      expect(tops.length, 1, reason: '"${m.group(0)}" breaks inside a word');
    }
  }

  for (final width in [320.0, 375.0]) {
    testWidgets('wardrobe rows are even and the ring fits its tile at '
        '$width px', (t) async {
      phone(t, Size(width, width == 320 ? 568 : 812));
      final state = await boot({'is_halloween': true});
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      // A room under 340 px shows the compact corner button (fix-today).
      await t.tap(
        find.byTooltip(width == 320 ? 'Wardrobe' : 'Costume closet'),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      Finder card(MaternalNeed need) => find
          .ancestor(
            of: find.byKey(ValueKey('closet-${need.name}')),
            matching: find.byType(PaperCard),
          )
          .first;
      // Three a row: each row is one height, Witch's included.
      for (final row in [
        MaternalNeed.values.sublist(0, 3),
        MaternalNeed.values.sublist(3),
      ]) {
        final heights = {for (final n in row) t.getSize(card(n)).height};
        expect(heights.length, 1, reason: '$row');
        final tops = {for (final n in row) t.getTopLeft(card(n)).dy};
        expect(tops.length, 1, reason: '$row');
      }
      // Selected: the ring's stack is exactly the card, not wider.
      final selected = MaternalNeed.iron;
      final stack = find
          .ancestor(of: card(selected), matching: find.byType(Stack))
          .first;
      expect(t.getSize(stack), t.getSize(card(selected)));
      // Witch says the need in sentence case; no extra tick before a name.
      // (Today's check-in row under the sheet says it too since fix-today.)
      expect(
        find.descendant(
          of: find.byType(ClosetSheet),
          matching: find.text('Prenatal vitamin'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card(selected), matching: find.byIcon(Icons.check)),
        findsNothing,
      );
      // The title keeps clear of the preview card (8 between at least).
      final title = t.getRect(find.text('Tonight’s wardrobe'));
      final preview = t.getRect(
        find
            .descendant(
              of: find.byType(ClosetSheet),
              matching: find.byType(PaperCard),
            )
            .first,
      );
      expect(preview.top - title.bottom, greaterThanOrEqualTo(8));
      for (final need in MaternalNeed.values) {
        final tile = t.getSize(find.byKey(ValueKey('closet-${need.name}')));
        expect(tile.shortestSide, greaterThanOrEqualTo(48));
      }
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('every Guides summary shows in full at 320 px and 200% text', (
    t,
  ) async {
    phone(t, const Size(320, 568), text: 2);
    final semantics = t.ensureSemantics();
    final raw = File('assets/content/guides.json').readAsStringSync();
    final guides = Guide.reviewAll(raw, drafts: true);
    expect(guides, isNotEmpty);
    ContentLoader.debugSetGuides(guides);
    final state = await boot({});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
    for (final entry in guides.entries) {
      final summary = find.byKey(ValueKey('guide-summary-${entry.key.name}'));
      await t.scrollUntilVisible(
        summary,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final text = t.widget<Text>(summary);
      expect(text.data, entry.value.point);
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      final paragraph = t.renderObject<RenderParagraph>(
        find.descendant(of: summary, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      // Each of the six visit buttons names its need aloud.
      final need = entry.key;
      final word = need == MaternalNeed.vitamin
          ? 'Prenatal vitamin'
          : need.label;
      expect(
        find.bySemanticsLabel(
          RegExp('^(Add $word to my visit list|On my visit list: $word)\$'),
        ),
        findsOneWidget,
      );
    }
    expect(t.takeException(), isNull);
    // The six visit buttons each name their need aloud.
    semantics.dispose();
    await t.pumpWidget(const SizedBox());
  });

  for (final halloween in [false, true]) {
    testWidgets('Paused fits 320 px at 200% with whole words '
        '(${halloween ? 'Halloween' : 'Everyday'})', (t) async {
      phone(t, const Size(320, 568), text: 2);
      final state = await boot({'is_paused': true, 'is_halloween': halloween});
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expectWholeWords(t, 'Everything is paused.');
      // A paper moon, never Bumpy.
      expect(t.getSize(find.byKey(const ValueKey('paused-moon'))).width, 72);
      expect(find.bySemanticsLabel(RegExp('^Bumpy')), findsNothing);
      final reset = find.text('Reset today’s check-ins and resume');
      await t.ensureVisible(reset);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(
        t
            .getSize(
              find.ancestor(of: reset, matching: find.byType(OutlinedButton)),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('the show page title keeps whole words at 320 px and 200% '
        '(${halloween ? 'Halloween' : 'Everyday'})', (t) async {
      phone(t, const Size(320, 568), text: 2);
      final state = await boot({'is_halloween': halloween});
      await state.addVisitQuestion('Can I travel?');
      final palette = halloween ? AppPalette.halloween : AppPalette.everyday;
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(palette),
          home: VisitScreen(state: state),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expectWholeWords(t, 'My questions');
      await t.pumpWidget(const SizedBox());
    });
  }

  for (final scale in [1.2, 1.3, 1.4]) {
    testWidgets('Settings header fits 320 px at ${scale}x text', (t) async {
      phone(t, const Size(320, 568), text: scale);
      final state = await boot({});
      await t.pumpWidget(LittleBumpyApp(state: state));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expectWholeWords(t, 'Settings');
      final pause = find.ancestor(
        of: find.textContaining('Pause'),
        matching: find.byType(OutlinedButton),
      );
      expect(pause, findsOneWidget);
      expect(t.getSize(pause).height, greaterThanOrEqualTo(48));
      await t.pumpWidget(const SizedBox());
    });
  }

  testWidgets('the saved note floats above the tabs and goes in 2 seconds', (
    t,
  ) async {
    phone(t, const Size(375, 812));
    final state = await boot({});
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('visit-topics-row')));
    await t.pumpAndSettle();
    expect(find.byTooltip('Close visit list'), findsOneWidget);
    // "Add question" is a real button now, at least 48 tall.
    final add = find.ancestor(
      of: find.text('Add question'),
      matching: find.byType(OutlinedButton),
    );
    expect(t.getSize(add).height, greaterThanOrEqualTo(48));
    final save = find.text('Save visit list');
    await t.ensureVisible(save);
    await t.pumpAndSettle();
    await t.tap(save);
    await t.pumpAndSettle();
    final bar = t.widget<SnackBar>(find.byKey(const ValueKey('visit-saved')));
    expect(bar.behavior, SnackBarBehavior.floating);
    expect(bar.duration, const Duration(seconds: 2));
    final note = t.getRect(
      find
          .descendant(
            of: find.byKey(const ValueKey('visit-saved')),
            matching: find.byType(Material),
          )
          .first,
    );
    final tabs = t.getRect(find.byType(AppNavBar));
    expect(note.bottom, lessThanOrEqualTo(tabs.top));
    // The tabs take a tap while the note is up.
    await t.tap(find.text('Today'));
    await t.pump();
    expect(state.currentTab, 0);
    await t.pumpAndSettle(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('visit-saved')), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
