import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/app_theme.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/app_state.dart';
import 'package:little_bumpy/presentation/screens/first_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Design critique 3, lane B: the Welcome step.

Future<AppState> _fresh({required bool halloween}) async {
  SharedPreferences.setMockInitialValues({'is_halloween': halloween});
  return AppState.load(now: () => DateTime(2026, 11, 23));
}

Future<void> _pump(WidgetTester tester, AppState state, Size size) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final palette = state.isHalloween
      ? AppPalette.halloween
      : AppPalette.everyday;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(palette),
      home: FirstRunScreen(state: state),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // The real faces, so line breaks match a phone (the test font draws
    // every letter as a 1 em square).
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

  for (final halloween in [false, true]) {
    final look = halloween ? 'Halloween' : 'Everyday';
    testWidgets('$look: Start is wholly on the first screen at 320x568', (
      tester,
    ) async {
      await _pump(
        tester,
        await _fresh(halloween: halloween),
        const Size(320, 568),
      );
      final start = tester.getRect(
        find.widgetWithText(ElevatedButton, 'Start'),
      );
      expect(start.bottom, lessThanOrEqualTo(568));
      expect(start.height, greaterThanOrEqualTo(48));
      expect(find.text('Start').hitTestable(), findsOneWidget);
    });
  }

  testWidgets('Welcome on a tall phone: Start sits at the bottom and the '
      'story is centred in the space above, no empty bottom third', (
    tester,
  ) async {
    await _pump(tester, await _fresh(halloween: true), const Size(375, 812));
    final start = tester.getRect(find.text('Start'));
    expect(start.bottom, greaterThan(812 * 0.85));
    final title = tester.getRect(find.text('Hello, I’m your Little Bumpy.'));
    final private = tester.getRect(
      find.text('Private: everything stays on this device.'),
    );
    // The group of room, title, story and privacy line is centred: the gap
    // under the privacy line is not much larger than the gap above the room.
    final scroll = tester.getRect(find.byType(SingleChildScrollView).first);
    final room = tester.getRect(find.byType(ClipRRect).first);
    final above = room.top - scroll.top;
    final below = scroll.bottom - private.bottom;
    expect((above - below).abs(), lessThan(48));
    expect(title.top, greaterThan(room.bottom));
  });

  // 539 = 568 less the review build's banner.
  for (final height in [568.0, 539.0]) {
    testWidgets('at 320x${height.toInt()} the privacy line is whole above '
        'Start, not cut by the scroll', (tester) async {
      await _pump(tester, await _fresh(halloween: false), Size(320, height));
      final private = tester.getRect(
        find.text('Private: everything stays on this device.'),
      );
      final scroll = tester.getRect(
        find.byKey(const ValueKey('welcome-story')),
      );
      expect(private.bottom, lessThanOrEqualTo(scroll.bottom));
      final start = tester.getRect(
        find.widgetWithText(ElevatedButton, 'Start'),
      );
      expect(start.bottom, lessThanOrEqualTo(height));
    });
  }
}
