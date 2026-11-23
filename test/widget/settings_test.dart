import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/constants/app_constants.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AppState> open(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'due_date_iso': '2027-05-10',
      'baby_nickname': 'Cub',
    });
    final state = await AppState.load();
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Settings'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('Settings has both looks, privacy, version and back to Guides', (
    tester,
  ) async {
    final state = await open(tester);
    expect(find.text('Little Bumpy'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(
      find.text(
        'No data ever leaves your phone. No accounts. No tracking. No ads.',
      ),
      findsOneWidget,
    );
    expect(find.text(AppConstants.disclaimer), findsOneWidget);
    await tester.tap(find.text('Everyday'));
    await tester.pumpAndSettle();
    expect(state.isHalloween, isFalse);
    expect((await AppState.load()).isHalloween, isFalse);
    expect(find.text(AppConstants.disclaimer), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(state.currentTab, 2);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Pause inside Settings quiets the app immediately', (
    tester,
  ) async {
    final state = await open(tester);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Everything is paused.'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(state.currentTab, 2);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Settings and Pause use the same reversible erase confirmation', (
    tester,
  ) async {
    final state = await open(tester);
    final erase = find.text('Erase all data');
    await tester.ensureVisible(erase);
    await tester.tap(erase);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Never mind'));
    await tester.pumpAndSettle();
    expect(state.nickname, 'Cub');
    await tester.tap(erase);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, erase'));
    await tester.pumpAndSettle();
    expect(state.isFirstRun, isTrue);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
