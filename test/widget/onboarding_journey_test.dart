import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('onboarding comes to rest immediately with reduced motion', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load();
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    for (final dot in tester.widgetList<AnimatedContainer>(
      find.byType(AnimatedContainer),
    )) {
      expect(dot.duration, Duration.zero);
    }
    await tester.tap(find.text('Tap to pick a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next').first);
    await tester.pump();
    expect(
      tester.widget<PageView>(find.byType(PageView)).controller!.page,
      1.0,
    );
    await tester.pumpWidget(const SizedBox());
  });
  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('complete first run and Pause at 200% text on $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load(now: () => DateTime(2026, 11, 23));
      await tester.pumpWidget(LittleBumpyApp(state: state));
      await tester.pumpAndSettle();
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tap(find.text('Tap to pick a date'));
      await tap(find.text('OK'));
      await tap(find.text('Next').first);
      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Clover');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tap(find.text('Next').hitTestable());
      await tap(find.textContaining('Everyday').first);
      await tap(find.text("Let's go"));
      expect(state.nickname, 'Clover');
      expect(state.isHalloween, isFalse);
      expect(state.isFirstRun, isFalse);
      await tap(find.byTooltip('Pause'));
      final erase = find.text('Erase all data');
      await tap(erase);
      await tap(find.text('Never mind'));
      expect(state.isPaused, isTrue);
      await tap(find.text('Resume'));
      expect(find.text('Today'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
