import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/presentation/widgets/need_word.dart';
import 'package:little_bumpy/content/content_loader.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => ContentLoader.load('assets/content/today_lines.json'));

  testWidgets('six costumes can be tried on without changing the day', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    var day = DateTime(2026, 11, 23, 23, 58);
    final state = await AppState.load(now: () => day);
    await state.toggleCheckIn('iron');
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    final trigger = find.byTooltip('Costume closet');
    expect(trigger, findsOneWidget);
    await tester.tap(trigger);
    await tester.pumpAndSettle();
    for (final need in MaternalNeed.values) {
      final card = find.byKey(ValueKey('closet-${need.name}'));
      expect(
        find.descendant(of: card, matching: find.text(needWord(need))),
        findsOneWidget,
      );
    }
    final witch = find.byKey(const ValueKey('closet-vitamin'));
    await tester.ensureVisible(witch);
    await tester.tap(witch);
    await tester.pumpAndSettle();
    expect(state.costumeOverride, isNull);
    final wear = find.text('Wear Witch');
    await tester.ensureVisible(wear);
    await tester.tap(wear);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(
        ValueKey(
          MaternalNeed.vitamin.assetPath(AppPalette.halloween, happy: true),
        ),
      ),
      findsOneWidget,
    );
    expect(state.todayNeed, MaternalNeed.iron);
    expect(state.completedCheckIns, {'iron'});
    expect(find.text('Iron · today’s need'), findsOneWidget);
    // The need stays named under any costume (Today's pairing tag).
    expect(find.text('Today · Iron'), findsOneWidget);
    expect(find.text('Dressed as a witch for fun'), findsOneWidget);
    expect(find.text('Iron in. Thank you!'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to Everyday'));
    await tester.pumpAndSettle();
    expect(trigger, findsNothing);
    expect(
      find.byKey(const ValueKey('assets/images/everyday-happy.png')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Switch to Halloween'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('assets/images/body-witch-happy.png')),
      findsOneWidget,
    );
    day = DateTime(2026, 11, 24);
    await tester.pump(const Duration(minutes: 2));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('assets/images/body-zombie.png')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('last costume is reachable at 200% text on a narrow phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
    final state = await AppState.load(now: () => DateTime(2026, 11, 23));
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    // At 320 px the room shows the icon-only wardrobe button.
    await tester.tap(find.byTooltip('Wardrobe'));
    await tester.pumpAndSettle();
    final witch = find.byKey(const ValueKey('closet-vitamin'));
    await tester.ensureVisible(witch);
    await tester.pumpAndSettle();
    await tester.tap(witch);
    await tester.pumpAndSettle();
    expect(state.costumeOverride, isNull);
    final wear = find.text('Wear Witch');
    await tester.ensureVisible(wear);
    await tester.tap(wear);
    await tester.pumpAndSettle();
    expect(state.costumeOverride, MaternalNeed.vitamin);
    expect(find.byType(BottomSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'the closet dismisses on Pause and can be cancelled without selecting',
    (tester) async {
      SharedPreferences.setMockInitialValues({'due_date_iso': '2027-05-10'});
      final state = await AppState.load();
      await tester.pumpWidget(LittleBumpyApp(state: state));
      await tester.pumpAndSettle();
      final trigger = find.byTooltip('Costume closet');
      expect(trigger, findsOneWidget);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      final witch = find.byKey(const ValueKey('closet-vitamin'));
      await tester.ensureVisible(witch);
      await tester.tap(witch);
      await tester.pumpAndSettle();
      expect(find.text('Wear Witch'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(state.costumeOverride, isNull);
      await tester.tap(trigger);
      await tester.pumpAndSettle();
      await state.togglePause();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(trigger, findsNothing);
      expect(find.text('Everything is paused.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final text in [1.0, 2.0]) {
    testWidgets('at 320 px the title keeps one line below a 12 px gap, and '
        'every need sits under its icon (text x$text)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = text;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      SharedPreferences.setMockInitialValues({
        'due_date_iso': '2027-05-10',
        'is_halloween': true,
      });
      final state = await AppState.load(now: () => DateTime(2026, 11, 23));
      await tester.pumpWidget(LittleBumpyApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Wardrobe'));
      await tester.pumpAndSettle();
      final title = find.byKey(const ValueKey('closet-title'));
      final sheet = find.byType(BottomSheet);
      expect(
        tester.getTopLeft(title).dy - tester.getTopLeft(sheet).dy,
        greaterThanOrEqualTo(12),
      );
      if (text == 1.0) {
        // Shrunk to fit one line, never wrapped.
        expect(
          find.ancestor(of: title, matching: find.byType(FittedBox)),
          findsOneWidget,
        );
        expect(tester.widget<Text>(title).maxLines, 1);
        final box = tester.getRect(
          find.ancestor(of: title, matching: find.byType(FittedBox)),
        );
        expect(box.height, lessThan(32));
        // The second row peeks above the footer (at least 24 px of it).
        final mummy = tester.getTopLeft(
          find.byKey(const ValueKey('closet-water')),
        );
        final footer = tester.getTopLeft(
          find.text('Wear it for this visit. Today’s check-in stays the same.'),
        );
        expect(footer.dy - mummy.dy, greaterThanOrEqualTo(24));
      } else {
        // Enlarged text is never scaled away: it wraps at full size.
        expect(
          find.ancestor(of: title, matching: find.byType(FittedBox)),
          findsNothing,
        );
      }
      for (final need in MaternalNeed.values) {
        final icon = find.byKey(ValueKey('closet-need-icon-${need.name}'));
        final word = find.descendant(
          of: find.byKey(ValueKey('closet-${need.name}')),
          matching: find.text(needWord(need)),
        );
        await tester.ensureVisible(word);
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(word).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(icon).dy),
          reason: need.name,
        );
        expect(
          (tester.getCenter(icon).dx - tester.getCenter(word).dx).abs(),
          lessThan(1),
          reason: need.name,
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
