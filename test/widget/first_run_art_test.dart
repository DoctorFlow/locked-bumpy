import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('the first visit shows Bumpy and a real preview of each look', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.load(now: () => DateTime(2026, 11, 23));
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    Finder asset(String path) => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == 'assets/images/$path.png',
    );
    expect(asset('body-vampire-happy'), findsOneWidget);
    await tester.ensureVisible(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose due date'));
    await tester.tap(find.text('Choose due date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    Future<void> next() async {
      final button = find.widgetWithText(ElevatedButton, 'Next');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await next();
    await next();
    expect(asset('everyday'), findsOneWidget);
    expect(asset('body-vampire'), findsOneWidget);
    expect(find.text('Halloween'), findsOneWidget);
    await tester.tap(find.text('Everyday'));
    await tester.pumpAndSettle();
    await next();
    // The Everyday look shows the six needs by icon, colour and word.
    for (final need in ['iron', 'brain', 'bones', 'water', 'rest', 'vitamin']) {
      expect(asset('need-$need'), findsOneWidget);
    }
    final start = find.text('Enter the nursery');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(state.isHalloween, isFalse);
    expect(
      find.byKey(const ValueKey('assets/images/everyday.png')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
