import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_bumpy/domain/models/skin_tone.dart';
import 'package:little_bumpy/presentation/widgets/paper_portrait.dart';

Future<Uint8List> pixels(ImageProvider<Object> provider) async {
  final stream = provider.resolve(ImageConfiguration.empty);
  final frame = Completer<ui.Image>();
  final listener = ImageStreamListener(
    (info, _) {
      frame.complete(info.image.clone());
      info.dispose();
    },
    onError: (Object error, StackTrace? trace) =>
        frame.completeError(error, trace),
  );
  stream.addListener(listener);
  try {
    final image = await frame.future;
    try {
      expect((image.width, image.height), (512, 512));
      return Uint8List.sublistView((await image.toByteData())!);
    } finally {
      image.dispose();
    }
  } finally {
    stream.removeListener(listener);
    await provider.evict();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'the engine decodes every tint mask and preserves each registered silhouette',
    () async {
      for (final name in [
        'everyday',
        'body-vampire',
        'body-mummy',
        'body-witch',
        'body-ghost',
        'body-skeleton',
        'body-zombie',
      ]) {
        for (final expression in [
          '',
          '-happy',
          if (name == 'everyday') '-sleepy',
        ]) {
          final path = 'assets/images/$name$expression.png';
          final base = await pixels(paperPortrait(path, SkinTone.peach));
          for (final tone in SkinTone.values.where(
            (tone) => tone != SkinTone.peach,
          )) {
            final tinted = await pixels(paperPortrait(path, tone));
            var differentSkinPixels = 0;
            var alphaChanges = 0;
            for (var i = 0; i < base.length; i += 4) {
              if (base[i + 3] != tinted[i + 3]) alphaChanges++;
              if (base[i + 3] > 200 &&
                  (base[i + 1] - tinted[i + 1]).abs() > 4) {
                differentSkinPixels++;
              }
            }
            expect(alphaChanges, 0, reason: '$path with ${tone.label}');
            expect(differentSkinPixels, greaterThan(1000));
          }
        }
      }
    },
  );
}
