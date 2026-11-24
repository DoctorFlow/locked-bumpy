import 'package:flutter/material.dart';

/// Little Bumpy's type scale: ten named styles, two voices.
///
/// Fraunces (soft, variable) is Bumpy's voice and the story headings.
/// Atkinson Hyperlegible is everything the app says. Atkinson ships Regular
/// (400) and Bold (700) only, so a `w600` on top of these styles renders Bold.
///
/// The styles carry no colour. Add the palette colour where you use them:
///
///     Text(line, style: AppText.bumpy.copyWith(color: palette.ink))
///
/// Sizes are logical pixels and grow with the system text size. Nothing is
/// smaller than 13, and every sentence a parent reads is 16 or larger.
abstract final class AppText {
  static const String sans = 'Atkinson Hyperlegible';
  static const String serif = 'Fraunces';

  // Fraunces axes are always set by hand: the file's own defaults are a 900
  // weight and the smallest optical size.
  static const FontVariation _soft = FontVariation('SOFT', 100);
  static const FontVariation _plain = FontVariation('WONK', 0);
  static const FontVariation _wonky = FontVariation('WONK', 1);

  /// 34 / 38. "Week 24" on the week card. At most one per screen.
  static const TextStyle display = TextStyle(
    fontFamily: serif,
    fontSize: 34,
    height: 38 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    leadingDistribution: TextLeadingDistribution.even,
    fontVariations: [
      FontVariation('opsz', 34),
      FontVariation('wght', 700),
      _soft,
      _plain,
    ],
  );

  /// 24 / 30. Screen, sheet and dialog titles; onboarding headings.
  static const TextStyle title = TextStyle(
    fontFamily: serif,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    leadingDistribution: TextLeadingDistribution.even,
    fontVariations: [
      FontVariation('opsz', 24),
      FontVariation('wght', 700),
      _soft,
      _plain,
    ],
  );

  /// 22 / 28. Bumpy's first-person line on Today and the welcome sample.
  static const TextStyle bumpy = TextStyle(
    fontFamily: serif,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
    fontVariations: [
      FontVariation('opsz', 22),
      FontVariation('wght', 600),
      _soft,
      _wonky,
    ],
  );

  /// 18 / 26. Bumpy's words on the week card.
  static const TextStyle bumpyStory = TextStyle(
    fontFamily: serif,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
    fontVariations: [
      FontVariation('opsz', 18),
      FontVariation('wght', 500),
      _soft,
      _wonky,
    ],
  );

  /// 18 / 24 Bold. Section headings and card titles.
  static const TextStyle heading = TextStyle(
    fontFamily: sans,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 16 / 22 Bold. Row titles, the baby's name, emphasis inside body text.
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 16 / 24. Every sentence a parent reads.
  static const TextStyle body = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 16 / 20 Bold. Every button label.
  static const TextStyle button = TextStyle(
    fontFamily: sans,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 14 / 20. One-line hints, the second line of a row, captions, the footer
  /// safety line. Not for paragraphs.
  static const TextStyle small = TextStyle(
    fontFamily: sans,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// 13 / 16 Bold. Tags, tab labels, the week tag, counters, "Done".
  /// The smallest text in the app.
  static const TextStyle label = TextStyle(
    fontFamily: sans,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Every named style, for tests and style sheets.
  static const Map<String, TextStyle> all = {
    'display': display,
    'title': title,
    'bumpy': bumpy,
    'bumpyStory': bumpyStory,
    'heading': heading,
    'bodyStrong': bodyStrong,
    'body': body,
    'button': button,
    'small': small,
    'label': label,
  };

  /// The scale laid over Material's slots, so widgets that read the theme
  /// (dialogs, list tiles, text fields, the date picker) use it untouched.
  static TextTheme theme(Color ink) => TextTheme(
    displayLarge: display.copyWith(fontSize: 40, height: 44 / 40),
    displayMedium: display,
    displaySmall: title.copyWith(fontSize: 28, height: 34 / 28),
    headlineLarge: title.copyWith(fontSize: 28, height: 34 / 28),
    headlineMedium: title,
    headlineSmall: title,
    titleLarge: title.copyWith(fontSize: 22, height: 28 / 22),
    titleMedium: heading,
    titleSmall: bodyStrong,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: small,
    labelLarge: button,
    labelMedium: label,
    labelSmall: label,
  ).apply(bodyColor: ink, displayColor: ink);
}
