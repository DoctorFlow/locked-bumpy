import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/guide.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/guide_screen.dart';
import 'package:little_bumpy/presentation/screens/guides_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/guide_fixture.dart';

/// Design critique 3, lane C: the Guides cards, the guide page and the
/// one form of "Add to my visit list".
void main() {
  tearDown(() => ContentLoader.debugSetGuides(null));

  Future<AppState> boot() async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    return AppState.load(now: () => DateTime(2026, 11, 23)); // IRON day
  }

  Guide draftGuide() => Guide.reviewAll(
    jsonEncode([paperBoatGuide(status: 'draft')]),
    drafts: true,
  )[MaternalNeed.iron]!;

  Future<void> openGuides(WidgetTester t, {Size size = const Size(375, 812)}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    ContentLoader.debugSetGuides({MaternalNeed.iron: draftGuide()});
    final state = await boot();
    await t.pumpWidget(LittleBumpyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('Guides'));
    await t.pumpAndSettle();
  }

  for (final size in [const Size(320, 568), const Size(375, 812)]) {
    testWidgets('a Guides card runs its point the full width under the '
        'portrait (${size.width.toInt()} px)', (t) async {
      await openGuides(t, size: size);
      final card = find.byKey(const PageStorageKey(MaternalNeed.iron));
      final summary = find.byKey(const ValueKey('guide-summary-iron'));
      await t.scrollUntilVisible(
        summary,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await t.pumpAndSettle();
      final portrait = find.descendant(
        of: card,
        matching: find.byType(NeedPortrait),
      );
      expect(t.getSize(portrait), const Size(72, 72));
      final word = find.descendant(of: card, matching: find.text('Iron'));
      // Starts at the card's own padding, left of the need word, and
      // below the picture: a paragraph, not a narrow column.
      expect(
        t.getTopLeft(summary).dx,
        lessThan(t.getTopLeft(word).dx - 48),
      );
      expect(
        t.getTopLeft(summary).dy,
        greaterThanOrEqualTo(t.getBottomLeft(portrait).dy),
      );
      expect(
        t.getSize(summary).width,
        greaterThan(t.getSize(card).width - 2 * 16 - 1),
      );
      // The chevron sits level with the need word, not halfway down.
      final chevron = find.descendant(
        of: card,
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(
        (t.getCenter(chevron).dy - t.getCenter(word).dy).abs(),
        lessThan(12),
      );
      expect(t.takeException(), isNull);
    });
  }

  /// The visit-list control is the one outlined, full-width form.
  void expectOneForm(WidgetTester t, Finder label, {required Finder within}) {
    final button = find.ancestor(of: label, matching: find.byType(OutlinedButton));
    expect(button, findsOneWidget);
    expect(
      find.descendant(
        of: button,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              (w.icon == Icons.playlist_add ||
                  w.icon == Icons.playlist_add_check),
        ),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.bookmark_outline), findsNothing);
    expect(find.byIcon(Icons.bookmark_add_outlined), findsNothing);
    expect(t.getSize(button).height, greaterThanOrEqualTo(48));
    expect(t.getSize(button).width, t.getSize(within).width - 2 * 16);
  }

  testWidgets('a Guides card offers the visit list as the full-width '
      'outlined button', (t) async {
    await openGuides(t);
    final card = find.byKey(const PageStorageKey(MaternalNeed.iron));
    final add = find.descendant(
      of: card,
      matching: find.text('Add to my visit list'),
    );
    await t.scrollUntilVisible(
      add,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.pumpAndSettle();
    expectOneForm(t, add, within: card);
  });

  testWidgets('guide page: each question and the not-ready page use the '
      'same button', (t) async {
    final state = await boot();
    await t.pumpWidget(
      MaterialApp(
        home: GuideScreen(
          state: state,
          need: MaternalNeed.iron,
          guide: draftGuide(),
        ),
      ),
    );
    await t.pumpAndSettle();
    final row = find.byKey(const ValueKey('guide-question-0'));
    final add = find.descendant(
      of: row,
      matching: find.text('Add to visit list'),
    );
    await t.scrollUntilVisible(add, 200);
    await t.pumpAndSettle();
    final button = find.ancestor(of: add, matching: find.byType(OutlinedButton));
    expect(t.getSize(button).width, t.getSize(row).width - 2 * 12);
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.playlist_add)),
      findsOneWidget,
    );

    await t.pumpWidget(
      MaterialApp(
        home: GuideScreen(state: state, need: MaternalNeed.iron, guide: null),
      ),
    );
    await t.pumpAndSettle();
    final notReady = find.text('Add to my visit list');
    final card = find.ancestor(of: notReady, matching: find.byType(GuideCard));
    expectOneForm(t, notReady, within: card);
  });
}
