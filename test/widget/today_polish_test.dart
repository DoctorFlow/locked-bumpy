import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/core/theme/paper.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/content_record.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:little_bumpy/presentation/widgets/draft_tag.dart';
import 'package:little_bumpy/presentation/widgets/nursery_scene.dart';
import 'package:little_bumpy/presentation/screens/today_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Design critique 3, lane A: the polish fixes on Today.

Future<AppState> start({
  bool halloween = false,
  Map<String, Object> extra = const {},
}) async {
  SharedPreferences.setMockInitialValues({
    'due_date_iso': '2027-05-10',
    'is_halloween': halloween,
    ...extra,
  });
  // 23 Nov 2026 is day 0 of the rotation: iron.
  return AppState.load(now: () => DateTime(2026, 11, 23));
}

Widget wrap(AppState state, {bool reduceMotion = false}) => MaterialApp(
  theme: ThemeData(
    extensions: [
      state.isHalloween ? AppPalette.halloween : AppPalette.everyday,
    ],
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: Scaffold(body: TodayScreen(state: state)),
);

Future<void> phone(WidgetTester t, double width, double height) async {
  t.view.devicePixelRatio = 2;
  t.view.physicalSize = Size(width * 2, height * 2);
  addTearDown(t.view.reset);
}

void main() {
  for (final width in [320.0, 375.0]) {
    testWidgets('"Get ready for week N" is full width at $width px', (t) async {
      await phone(t, width, 800);
      final state = await start();
      await t.pumpWidget(wrap(state));
      await t.pumpAndSettle();
      final link = find.byKey(const ValueKey('today-week-link'));
      expect(link, findsOneWidget);
      // The page margin is 16 on each side.
      expect(t.getSize(link).width, closeTo(width - 32, 0.5));
      expect(t.getSize(link).height, greaterThanOrEqualTo(48));
      expect(find.text('Today’s check-ins'), findsOneWidget);
      expect(find.text("Today's check-ins"), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  }

  double hopNow(WidgetTester t) =>
      t.widget<BumpyAvatar>(find.byType(BumpyAvatar)).hopAnimation!.value;

  Future<void> tick(WidgetTester t, String label) async {
    final f = find.text(label);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
  }

  group('all three ticked', () {
    tearDown(() => ContentGate.debugDrafts = null);

    testWidgets('the third tick makes Bumpy hop once', (t) async {
      final state = await start();
      await t.pumpWidget(wrap(state));
      await t.pumpAndSettle();
      await tick(t, 'Iron · today’s need');
      await t.pumpAndSettle();
      await tick(t, 'Water');
      await t.pumpAndSettle();
      expect(hopNow(t), 0);
      // The vitamin is not today's need, so only the all-done hop can move
      // Bumpy now.
      await tick(t, 'Prenatal vitamin');
      await t.pump();
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(hopNow(t), lessThan(-4));
      await t.pumpAndSettle();
      expect(hopNow(t), 0);
      expect(find.byKey(const ValueKey('today-check-ins-saved')), findsOne);
      // A rebuild does not hop again.
      state.setTab(0);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(hopNow(t), 0);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a day opened already finished does not hop', (t) async {
      final state = await start(
        extra: {
          'daily_needs_v2': ['2026-11-23', 'iron', 'water', 'vitamin'],
        },
      );
      expect(state.allChecked, isTrue);
      await t.pumpWidget(wrap(state));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(hopNow(t), 0);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('with motion off nothing hops and the moment still reads', (
      t,
    ) async {
      ContentGate.debugDrafts = true;
      final state = await start(halloween: true);
      await t.pumpWidget(wrap(state, reduceMotion: true));
      await t.pumpAndSettle();
      for (final label in ['Iron · today’s need', 'Water', 'Prenatal vitamin']) {
        await tick(t, label);
        await t.pump();
        await t.pump(const Duration(milliseconds: 100));
        expect(hopNow(t), 0);
        await t.pumpAndSettle();
      }
      expect(find.text('Today’s check-ins are saved'), findsOne);
      expect(find.byKey(const ValueKey('today-check-ins-thanks')), findsOne);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('the saved card: three ticked discs, a thank-you, no counts', (
      t,
    ) async {
      ContentGate.debugDrafts = true;
      await phone(t, 320, 568);
      final state = await start(
        extra: {
          'daily_needs_v2': ['2026-11-23', 'iron', 'water', 'vitamin'],
        },
      );
      await t.pumpWidget(wrap(state));
      await t.pumpAndSettle();
      final card = find.byKey(const ValueKey('today-check-ins-saved'));
      for (final need in ['iron', 'water', 'vitamin']) {
        final disc = find.byKey(ValueKey('saved-disc-$need'));
        expect(disc, findsOne);
        expect(t.getSize(disc), const Size(48, 48));
        expect(
          find.descendant(of: disc, matching: find.byIcon(Icons.check)),
          findsOne,
        );
      }
      // The discs sit centred in the card.
      final left = t.getRect(find.byKey(const ValueKey('saved-disc-iron')));
      final right = t.getRect(find.byKey(const ValueKey('saved-disc-vitamin')));
      final box = t.getRect(card);
      expect(
        (left.left - box.left) - (box.right - right.right),
        closeTo(0, 1),
      );
      final thanks = find.byKey(const ValueKey('today-check-ins-thanks'));
      expect(t.widget<Text>(thanks).data, 'Thank you! That made me smile.');
      expect(find.descendant(of: card, matching: find.byType(DraftTag)), findsOne);
      // Nothing on the card counts, scores or compares.
      final words = t
          .widgetList<Text>(find.descendant(of: card, matching: find.byType(Text)))
          .map((w) => w.data ?? '')
          .join(' ');
      expect(words, isNot(matches(RegExp(r'\d'))));
      expect(
        words.toLowerCase(),
        isNot(matches(RegExp(r'streak|score|in a row|of 3|all three'))),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a release build hides the draft thank-you', (t) async {
      ContentGate.debugDrafts = false;
      final state = await start(
        extra: {
          'daily_needs_v2': ['2026-11-23', 'iron', 'water', 'vitamin'],
        },
      );
      await t.pumpWidget(wrap(state));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('today-check-ins-thanks')), findsNothing);
      expect(find.byKey(const ValueKey('saved-disc-iron')), findsOne);
      await t.pumpWidget(const SizedBox());
    });
  });

  for (final width in [320.0, 375.0]) {
    testWidgets('the Wardrobe chip is a paper tag 12 in from the corner at '
        '$width px', (t) async {
      await phone(t, width, 800);
      final state = await start(halloween: true);
      await t.pumpWidget(wrap(state));
      await t.pumpAndSettle();
      final palette = AppPalette.halloween;
      final tag = find.byKey(const ValueKey('wardrobe-tag'));
      expect(tag, findsOne);
      final room = t.getTopLeft(find.byType(NurseryScene));
      expect(t.getTopLeft(tag) - room, const Offset(12, 12));
      final shadow = t.widget<DecoratedBox>(tag).decoration as BoxDecoration;
      expect(shadow.boxShadow, isNotEmpty);
      final ButtonStyle? style = width < 340
          ? t.widget<IconButton>(find.byKey(const ValueKey('wardrobe-compact'))).style
          : t
                .widget<ButtonStyleButton>(
                  find.descendant(
                    of: tag,
                    matching: find.byWidgetPredicate(
                      (w) => w is ButtonStyleButton,
                    ),
                  ),
                )
                .style;
      expect(style!.backgroundColor!.resolve({}), palette.paperRaised);
      expect(style.side!.resolve({})!.color, palette.edge);
      await t.pumpWidget(const SizedBox());
    });
  }

  group('For your visit', () {
    Future<void> open(WidgetTester t, List<String> topics) async {
      await phone(t, 375, 1400);
      final state = await start(extra: {'visit_topics': topics});
      await t.pumpWidget(wrap(state));
      await t.pumpAndSettle();
    }

    testWidgets('the question is a quoted raised piece, not a second heading', (
      t,
    ) async {
      await open(t, ['question:Can I travel?']);
      final piece = find.byKey(const ValueKey('visit-card-question-piece'));
      expect(piece, findsOne);
      expect(t.widget<PaperCard>(piece).raised, isTrue);
      final text = t.widget<Text>(
        find.byKey(const ValueKey('visit-card-question')),
      );
      expect(text.data, '“Can I travel?”');
      expect(text.style!.fontSize, 18);
      expect(text.style!.fontWeight, isNot(FontWeight.w700));
      // 8 between the card title and the piece.
      final title = t.getRect(find.text('For your visit'));
      expect(t.getRect(piece).top - title.bottom, closeTo(8, 0.5));
      await t.pumpWidget(const SizedBox());
    });

    testWidgets('a saved topic alone is not put in quotes', (t) async {
      await open(t, ['iron']);
      expect(
        t.widget<Text>(find.byKey(const ValueKey('visit-card-question'))).data,
        'Iron',
      );
      await t.pumpWidget(const SizedBox());
    });
  });
}
