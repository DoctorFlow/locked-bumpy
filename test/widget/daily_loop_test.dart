import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/main.dart';
import 'package:little_bumpy/presentation/screens/today_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('an open Today tab resets to the next need at midnight', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 26, 23, 59, 58);
    SharedPreferences.setMockInitialValues({'due_date_iso': '2027-04-10'});
    final state = await AppState.load(now: () => now);
    await state.toggleCheckIn('water');
    await tester.pumpWidget(LittleBumpyApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('WATER · Need of the Day'), findsOneWidget);
    now = DateTime(2026, 11, 27);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('REST · Need of the Day'), findsOneWidget);
    expect(state.completedCheckIns, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  for (final day in List.generate(6, (i) => DateTime(2026, 11, 23 + i))) {
    testWidgets('three distinct check-ins and one goodbye on ${day.day} Nov', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final state = await AppState.load(now: () => day);
      final today = state.todayNeed;
      final expected = {
        MaternalNeed.water,
        MaternalNeed.vitamin,
        if (today == MaternalNeed.water || today == MaternalNeed.vitamin)
          MaternalNeed.rest
        else
          today,
      };
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppPalette.everyday]),
          home: Scaffold(body: TodayScreen(state: state)),
        ),
      );
      await tester.pumpAndSettle();
      for (final need in expected) {
        final label = need == today
            ? '${need.needName} · Need of the Day'
            : need == MaternalNeed.vitamin
            ? 'Prenatal Vitamin'
            : need == MaternalNeed.water
            ? 'Water'
            : 'Rest';
        final tile = find.text(label);
        expect(
          tile,
          findsOneWidget,
          reason: 'Expected $label on ${today.name} day',
        );
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }
      expect(state.allChecked, isTrue);
      expect(find.text("That's us for today."), findsOneWidget);
    });
  }
}
