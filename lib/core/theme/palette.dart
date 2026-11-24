import 'package:flutter/material.dart';

/// Colour roles for Little Bumpy: cut paper on a table, by day and by night.
///
/// Text pairs keep at least 4.5:1 and control edges at least 3:1 in both
/// looks (the ratios are listed in the factory's `specs/DESIGN.md` and
/// asserted in `test/widget/look_system_test.dart`):
///
/// * [ink] and [inkSoft] are for text on [paper] and [paperRaised].
/// * [moonlight] and [moonlightSoft] are for text on the page ([skyTop] to
///   [skyBottom]).
/// * [accent] is a fill, or text on paper. It is not text on the page.
/// * [outline] is the only edge colour that reads on paper and on the page.
class AppPalette extends ThemeExtension<AppPalette> {
  /// The table everything lies on: the page, top to bottom.
  final Color skyTop;
  final Color skyBottom;

  /// The ground under Bumpy, sampled from each nursery backdrop.
  final Color hill;

  /// Cards, sheets, dialogs and the tab bar.
  final Color paper;

  /// A piece lying on a card: rows, tags, inputs, quiet buttons.
  final Color paperRaised;

  final Color ink;
  final Color inkSoft;
  final Color moonlight;
  final Color moonlightSoft;
  final Color moon;

  /// The main action, the selected state and the week number.
  final Color accent;
  final Color accentText;

  /// The hard shadow under an accent piece.
  final Color accentDeep;

  /// Edges of controls (outlined buttons, inputs, unticked boxes). At least
  /// 3:1 on paper, raised paper and the page.
  final Color outline;

  /// Hairlines and dividers on paper. Decorative only.
  final Color rule;

  /// The one-pixel lit edge on every paper piece.
  final Color edge;

  /// Paper shadows. Never pure black, never a glow.
  final Color shadow;

  /// Errors and destructive actions on paper, and the text on a danger fill.
  final Color danger;
  final Color onDanger;

  /// Tab bar fill and the colour of an unselected tab.
  final Color tabBar;
  final Color tabBarText;
  final bool isHalloween;

  const AppPalette({
    required this.skyTop,
    required this.skyBottom,
    required this.hill,
    required this.paper,
    required this.paperRaised,
    required this.ink,
    required this.inkSoft,
    required this.moonlight,
    required this.moonlightSoft,
    required this.moon,
    required this.accent,
    required this.accentText,
    required this.accentDeep,
    required this.outline,
    required this.rule,
    required this.edge,
    required this.shadow,
    required this.danger,
    required this.onDanger,
    required this.tabBar,
    required this.tabBarText,
    required this.isHalloween,
  });

  static const everyday = AppPalette(
    skyTop: Color(0xFF3B2A4F),
    skyBottom: Color(0xFF2E2040),
    hill: Color(0xFFB48D9D),
    paper: Color(0xFFFBF3E6),
    paperRaised: Color(0xFFF1E3CF),
    ink: Color(0xFF2E2040),
    inkSoft: Color(0xFF5E4D6E),
    moonlight: Color(0xFFF6EEDF),
    moonlightSoft: Color(0xFFCBBEDA),
    moon: Color(0xFFF5E2B0),
    accent: Color(0xFF9A3F6B),
    accentText: Color(0xFFFFF8EE),
    accentDeep: Color(0xFF6E2749),
    outline: Color(0xFF8A7799),
    rule: Color(0xFFDDCCB9),
    edge: Color(0xB3FFFFFF),
    shadow: Color(0xFF170F21),
    danger: Color(0xFFA1322E),
    onDanger: Color(0xFFFFF8EE),
    tabBar: Color(0xFFFBF3E6),
    tabBarText: Color(0xFF5E4D6E),
    isHalloween: false,
  );

  static const halloween = AppPalette(
    skyTop: Color(0xFF1A1224),
    skyBottom: Color(0xFF120C19),
    hill: Color(0xFF785476),
    paper: Color(0xFF2A1F38),
    paperRaised: Color(0xFF382A4B),
    ink: Color(0xFFF3E9DA),
    inkSoft: Color(0xFFC9B9D9),
    moonlight: Color(0xFFF3E9DA),
    moonlightSoft: Color(0xFFB6A6C8),
    moon: Color(0xFFF0A45C), // Pumpkin moon
    accent: Color(0xFFF0A45C),
    accentText: Color(0xFF1A1224),
    accentDeep: Color(0xFFB86A2A),
    outline: Color(0xFF8A7799),
    rule: Color(0xFF564362),
    edge: Color(0xFF4A3A60),
    shadow: Color(0xFF05030A),
    danger: Color(0xFFFF8A80),
    onDanger: Color(0xFF2E2040),
    tabBar: Color(0xFF2A1F38),
    tabBarText: Color(0xFFC9B9D9),
    isHalloween: true,
  );

  // Erase is displayed on the dark sky in both looks. On paper use [danger]:
  // this pink is only 2.1:1 on Everyday paper.
  static const eraseAccent = Color(0xFFFF8A80);
  static const eraseInk = Color(0xFF2E2040);

  /// What dims the page behind a sheet or dialog: the night table, not black.
  static const scrim = Color(0x99120C19);

  // Six need colours, sampled from the paper icons (identical in both looks).
  // They are paper, never text.
  static const needIron = Color(0xFFB43C48); // Leaf / vampire
  static const needBrain = Color(0xFFCC6C84); // Round brain / zombie
  static const needBones = Color(0xFF9C6C48); // Bone / skeleton
  static const needWater = Color(0xFF4890B4); // Water drop / mummy
  static const needRest = Color(0xFF9C90CC); // Crescent moon / ghost
  static const needVitamin = Color(0xFFD89C30); // Pill / witch

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? everyday;
  }

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? skyTop,
    Color? skyBottom,
    Color? hill,
    Color? paper,
    Color? paperRaised,
    Color? ink,
    Color? inkSoft,
    Color? moonlight,
    Color? moonlightSoft,
    Color? moon,
    Color? accent,
    Color? accentText,
    Color? accentDeep,
    Color? outline,
    Color? rule,
    Color? edge,
    Color? shadow,
    Color? danger,
    Color? onDanger,
    Color? tabBar,
    Color? tabBarText,
    bool? isHalloween,
  }) {
    return AppPalette(
      skyTop: skyTop ?? this.skyTop,
      skyBottom: skyBottom ?? this.skyBottom,
      hill: hill ?? this.hill,
      paper: paper ?? this.paper,
      paperRaised: paperRaised ?? this.paperRaised,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      moonlight: moonlight ?? this.moonlight,
      moonlightSoft: moonlightSoft ?? this.moonlightSoft,
      moon: moon ?? this.moon,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      accentDeep: accentDeep ?? this.accentDeep,
      outline: outline ?? this.outline,
      rule: rule ?? this.rule,
      edge: edge ?? this.edge,
      shadow: shadow ?? this.shadow,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      tabBar: tabBar ?? this.tabBar,
      tabBarText: tabBarText ?? this.tabBarText,
      isHalloween: isHalloween ?? this.isHalloween,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      skyTop: Color.lerp(skyTop, other.skyTop, t)!,
      skyBottom: Color.lerp(skyBottom, other.skyBottom, t)!,
      hill: Color.lerp(hill, other.hill, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paperRaised: Color.lerp(paperRaised, other.paperRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      moonlight: Color.lerp(moonlight, other.moonlight, t)!,
      moonlightSoft: Color.lerp(moonlightSoft, other.moonlightSoft, t)!,
      moon: Color.lerp(moon, other.moon, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      edge: Color.lerp(edge, other.edge, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      tabBar: Color.lerp(tabBar, other.tabBar, t)!,
      tabBarText: Color.lerp(tabBarText, other.tabBarText, t)!,
      isHalloween: t < 0.5 ? isHalloween : other.isHalloween,
    );
  }
}
