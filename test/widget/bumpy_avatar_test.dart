import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/core/theme/palette.dart';
import 'package:little_bumpy/domain/models/need.dart';
import 'package:little_bumpy/presentation/widgets/bumpy_avatar.dart';
import 'package:little_bumpy/presentation/widgets/nursery_scene.dart';

void main() {
  testWidgets(
    'all six needs use bundled, complete Bumpy pictures in both looks',
    (tester) async {
      for (final palette in [AppPalette.everyday, AppPalette.halloween]) {
        for (final need in MaternalNeed.values) {
          for (final happy in [false, true]) {
            await tester.pumpWidget(
              MaterialApp(
                home: Center(
                  child: BumpyAvatar(
                    need: need,
                    palette: palette,
                    happy: happy,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final stem = palette.isHalloween
                ? 'body-${need.costume.toLowerCase()}'
                : 'everyday';
            final path = 'assets/images/$stem${happy ? '-happy' : ''}.png';
            expect(find.image(AssetImage(path)), findsOneWidget);
            expect(
              tester.getSize(find.byType(BumpyAvatar)),
              const Size.square(190),
            );
            expect((await rootBundle.load(path)).lengthInBytes, greaterThan(0));
            expect(
              find.descendant(
                of: find.byType(BumpyAvatar),
                matching: find.byType(Text),
              ),
              findsNothing,
            );
            expect(
              find.bySemanticsLabel(RegExp('Bumpy in a ')),
              findsOneWidget,
            );
          }
        }
      }
    },
  );

  testWidgets('both nursery backdrops load at their full export size', (
    tester,
  ) async {
    for (final (palette, path, size) in [
      (
        AppPalette.halloween,
        'assets/images/nursery-halloween.webp',
        (1190, 1190),
      ),
      (AppPalette.everyday, 'assets/images/nursery-everyday.webp', (941, 1672)),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: NurseryScene(
            palette: palette,
            avatar: BumpyAvatar(
              need: MaternalNeed.iron,
              palette: palette,
              happy: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.image(AssetImage(path)), findsOneWidget);
      final decoded = await tester.runAsync(() async {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          Uint8List.sublistView(data),
        );
        final image = (await codec.getNextFrame()).image;
        final result = (image.width, image.height);
        image.dispose();
        codec.dispose();
        return result;
      });
      expect(decoded, size, reason: path);
    }
  });

  testWidgets('the hop lands on whole device pixels', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: BumpyAvatar(
            need: MaternalNeed.water,
            palette: AppPalette.halloween,
            happy: false,
            hopAnimation: AlwaysStoppedAnimation(-18.3),
          ),
        ),
      ),
    );
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(BumpyAvatar),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.transform.getTranslation().y * 3, closeTo(-55, 1e-9));
  });

  testWidgets('reduced motion swaps immediately and ignores the hop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: BumpyAvatar(
            need: MaternalNeed.water,
            palette: AppPalette.halloween,
            happy: true,
            hopAnimation: AlwaysStoppedAnimation(-18),
          ),
        ),
      ),
    );
    final root = find.byType(BumpyAvatar);
    final switcher = tester.widget<AnimatedSwitcher>(
      find.descendant(of: root, matching: find.byType(AnimatedSwitcher)),
    );
    expect(switcher.duration, Duration.zero);
    expect(
      find.descendant(of: root, matching: find.byType(Transform)),
      findsNothing,
    );
  });
}
