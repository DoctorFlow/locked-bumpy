import 'package:flutter/material.dart';

/// A heading that wraps only between words. When the longest word, at the
/// reader's text size, is wider than the space it has (320 px at 200 percent
/// text), the heading steps down in size until that word fits, so it never
/// breaks inside a word ("Everythin / g"). At normal sizes it is plain [Text].
class WholeWordText extends StatelessWidget {
  const WholeWordText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  /// The font size at which every word of [text] fits in [maxWidth].
  static double fittingSize(
    String text,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
    double maxWidth,
  ) {
    var size = style.fontSize ?? 14;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    for (var tries = 0; tries < 12; tries++) {
      var widest = 0.0;
      for (final word in words) {
        final painter = TextPainter(
          text: TextSpan(
            text: word,
            style: style.copyWith(fontSize: size),
          ),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        if (painter.width > widest) widest = painter.width;
        painter.dispose();
      }
      if (widest <= maxWidth || size <= 13) break;
      size = (size * maxWidth / widest * 0.98).clamp(13, size - 0.5);
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, bounds) {
        final base = style.fontSize ?? 14;
        final size = bounds.maxWidth.isFinite
            ? fittingSize(
                text,
                style,
                MediaQuery.textScalerOf(context),
                Directionality.of(context),
                bounds.maxWidth,
              )
            : base;
        return Text(
          text,
          textAlign: textAlign,
          style: size == base ? style : style.copyWith(fontSize: size),
        );
      },
    );
  }
}
