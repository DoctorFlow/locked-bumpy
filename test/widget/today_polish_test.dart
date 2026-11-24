import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
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
}
