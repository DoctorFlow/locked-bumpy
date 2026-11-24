import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_line.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/paused_screen.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lab round 3, problem 3: Paused had a bright Resume, a faceless disc and
/// no kind word. Now: Bumpy asleep, a calm outlined Resume, quieter links,
/// and one kind line that is draft content behind the review gate.
void main() {
  const support =
      'If today is heavy, your doctor or midwife is there for you too.';

  setUp(() {
    ContentLoader.debugSetAppLines(null);
    rootBundle.clear();
  });
  tearDown(() => ContentLoader.debugSetAppLines(null));

  void useLines({required bool drafts}) => ContentLoader.debugSetAppLines(
    AppLines.review(
      File('assets/content/app_lines.json').readAsStringSync(),
      drafts: drafts,
    ),
  );

  Future<void> pumpPaused(WidgetTester t, AppPalette palette) async {
    SharedPreferences.setMockInitialValues({
      'is_paused': true,
      'is_halloween': palette.isHalloween,
      'due_date_iso': '2027-05-10',
    });
    final state = await AppState.load(now: () => DateTime(2026, 11, 23));
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(palette),
        home: Scaffold(body: PausedScreen(state: state)),
      ),
    );
    await t.pumpAndSettle();
  }

  for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
    final look = palette.isHalloween ? 'Halloween' : 'Everyday';

    testWidgets('$look: Bumpy asleep in place of the disc, still and silent', (
      t,
    ) async {
      useLines(drafts: false);
      await pumpPaused(t, palette);
      final picture = find.byKey(const ValueKey('paused-bumpy'));
      expect(picture, findsOneWidget);
      expect(find.byKey(const ValueKey('paused-moon')), findsNothing);
      // A still picture: not the hopping avatar, no costume.
      expect(find.byType(BumpyAvatar), findsNothing);
      expect(
        find.ancestor(of: picture, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });

    testWidgets('$look: Resume is calm and outlined; reset and erase are '
        'quieter links', (t) async {
      useLines(drafts: false);
      await pumpPaused(t, palette);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      final resume = find.byKey(const ValueKey('paused-resume'));
      expect(t.widget(resume), isA<OutlinedButton>());
      expect(
        t.widget(find.byKey(const ValueKey('paused-reset'))),
        isA<TextButton>(),
      );
      expect(
        t.widget(find.byKey(const ValueKey('paused-erase'))),
        isA<TextButton>(),
      );
      Color labelColour(String text) =>
          DefaultTextStyle.of(t.element(find.text(text))).style.color!;
      // Resume reads in ink, never the accent; the links in the softer ink.
      expect(labelColour('Resume'), palette.ink);
      expect(labelColour('Resume'), isNot(palette.accent));
      expect(labelColour('Erase all data'), palette.inkSoft);
      expect(labelColour('Erase all data'), isNot(palette.danger));
      for (final key in ['paused-resume', 'paused-reset', 'paused-erase']) {
        expect(
          t.getSize(find.byKey(ValueKey(key))).height,
          greaterThanOrEqualTo(48),
          reason: key,
        );
      }
      // The approved words are unchanged.
      expect(find.text('Everything is paused.'), findsOneWidget);
      expect(
        find.text(
          'Take all the time you need. '
          'We are right here whenever you are ready.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('$look: review build shows the kind line with a Draft tag', (
      t,
    ) async {
      useLines(drafts: true);
      await pumpPaused(t, palette);
      expect(find.text(support), findsOneWidget);
      expect(find.byType(DraftTag), findsOneWidget);
    });

    testWidgets('$look: a normal build hides the draft kind line', (t) async {
      useLines(drafts: false);
      await pumpPaused(t, palette);
      expect(find.text(support), findsNothing);
      expect(find.byType(DraftTag), findsNothing);
    });
  }

  test('the kind line is content, a draft with empty approval fields', () {
    final lines = AppLines.review(
      File('assets/content/app_lines.json').readAsStringSync(),
      drafts: true,
    );
    expect(lines[AppLines.pausedSupport]!.text, support);
    expect(lines[AppLines.pausedSupport]!.isDraft, isTrue);
    expect(
      File(
        'lib/presentation/screens/paused_screen.dart',
      ).readAsStringSync().contains('is there for you'),
      isFalse,
      reason: 'the line lives in app_lines.json, not in Dart',
    );
  });
}
