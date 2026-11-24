import 'package:flutter/material.dart';
import 'app_text.dart';
import 'palette.dart';
import 'paper.dart';

/// The app's [ThemeData] for one look ([AppPalette.everyday] or
/// [AppPalette.halloween]).
///
/// Everything a stock Material widget would otherwise invent (the purple
/// colour scheme, Roboto, pill buttons, the grey date picker) is set here from
/// the palette and [AppText], so a screen that uses theme defaults is already
/// in the paper world. Screens add colour only where the surface needs it:
/// [AppPalette.moonlight] for text on the page.
ThemeData buildTheme(AppPalette p) {
  final scheme = _scheme(p);
  final text = AppText.theme(p.ink);
  final controlShape = WidgetStatePropertyAll<OutlinedBorder>(
    const RoundedRectangleBorder(borderRadius: AppRadii.control),
  );
  final disabledInk = p.ink.withValues(alpha: .38);
  final disabledFill = p.ink.withValues(alpha: .12);

  // What every button shares: type, corners, a 48 px target.
  ButtonStyle button({
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 12,
    ),
    TextStyle textStyle = AppText.button,
  }) => ButtonStyle(
    textStyle: WidgetStatePropertyAll(textStyle),
    shape: controlShape,
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: WidgetStatePropertyAll(padding),
    tapTargetSize: MaterialTapTargetSize.padded,
    elevation: const WidgetStatePropertyAll(0),
    visualDensity: VisualDensity.standard,
  );

  Color? whenSelected(Set<WidgetState> states, Color on, [Color? off]) =>
      states.contains(WidgetState.selected) ? on : off;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.skyBottom,
    canvasColor: p.paper,
    dividerColor: p.rule,
    fontFamily: AppText.sans,
    textTheme: text,
    // Phones get this anyway. The web and desktop builds would otherwise use
    // compact density and 40 px targets.
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [p],
    iconTheme: IconThemeData(color: p.ink, size: 24),

    // ── Buttons ────────────────────────────────────────────────────────────
    // Main action. FilledButton.tonal keeps its own colours from the scheme
    // (raised paper, ink), so only the shared parts are set on FilledButton.
    filledButtonTheme: FilledButtonThemeData(style: button()),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: button().copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? disabledFill : p.accent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? disabledInk : p.accentText,
        ),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: button().copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? disabledInk : p.ink,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.disabled)
                ? p.outline.withValues(alpha: .4)
                : p.outline,
            width: 1.5,
          ),
        ),
      ),
    ),
    // A text button is a link: no fill, so it is underlined.
    textButtonTheme: TextButtonThemeData(
      style: button(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        textStyle: AppText.button.copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
    ),

    // ── Paper surfaces ─────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: p.paper,
      surfaceTintColor: Colors.transparent,
      shadowColor: p.shadow,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(color: p.edge),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      shadowColor: p.shadow,
      elevation: 8,
      barrierColor: AppPalette.scrim,
      iconColor: p.accent,
      titleTextStyle: AppText.title.copyWith(color: p.ink),
      contentTextStyle: AppText.body.copyWith(color: p.ink),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: BorderSide(color: p.edge),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.paper,
      modalBackgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: AppPalette.scrim,
      shadowColor: p.shadow,
      elevation: 0,
      modalElevation: 0,
      dragHandleColor: p.outline,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.sheetTop,
        side: BorderSide(color: p.edge),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.rule, thickness: 1, space: 16),
    listTileTheme: ListTileThemeData(
      iconColor: p.inkSoft,
      titleTextStyle: AppText.body,
      subtitleTextStyle: AppText.small,
      minTileHeight: AppSpace.row,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: p.ink,
      collapsedIconColor: p.inkSoft,
      textColor: p.ink,
      collapsedTextColor: p.ink,
      shape: const Border(),
      collapsedShape: const Border(),
    ),

    // ── Inputs and choices ─────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: p.paperRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // A floated label is drawn at three quarters of this size: 13.5 px.
      labelStyle: AppText.body.copyWith(
        fontSize: 18,
        height: 24 / 18,
        color: p.inkSoft,
      ),
      floatingLabelStyle: AppText.heading.copyWith(color: p.ink),
      hintStyle: AppText.body.copyWith(color: p.inkSoft),
      helperStyle: AppText.small.copyWith(color: p.inkSoft),
      counterStyle: AppText.small.copyWith(color: p.inkSoft),
      errorStyle: AppText.small.copyWith(
        color: p.danger,
        fontWeight: FontWeight.w700,
      ),
      errorMaxLines: 3,
      prefixIconColor: p.inkSoft,
      suffixIconColor: p.inkSoft,
      border: _inputBorder(p.outline, 1.5),
      enabledBorder: _inputBorder(p.outline, 1.5),
      disabledBorder: _inputBorder(p.rule, 1.5),
      focusedBorder: _inputBorder(p.accent, 2),
      errorBorder: _inputBorder(p.danger, 1.5),
      focusedErrorBorder: _inputBorder(p.danger, 2),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: .28),
      selectionHandleColor: p.accent,
    ),
    // A chip is a small opaque paper piece, so it reads on a card and on the
    // page. Selected is an accent fill plus the tick.
    chipTheme: ChipThemeData(
      color: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? Color.alphaBlend(disabledFill, p.paper)
            : whenSelected(s, p.accent, p.paperRaised),
      ),
      labelStyle: AppText.small.copyWith(
        fontWeight: FontWeight.w700,
        color: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? disabledInk
              : whenSelected(s, p.accentText, p.ink)!,
        ),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (s) => BorderSide(color: whenSelected(s, p.accent, p.outline)!),
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.tag),
      showCheckmark: true,
      checkmarkColor: p.accentText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pressElevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => whenSelected(s, p.accent, Colors.transparent),
      ),
      checkColor: WidgetStatePropertyAll(p.accentText),
      side: BorderSide(color: p.outline, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    datePickerTheme: _datePicker(p, disabledInk),

    // ── Small parts ────────────────────────────────────────────────────────
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.rule,
      circularTrackColor: Colors.transparent,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.ink, borderRadius: AppRadii.tag),
      textStyle: AppText.small.copyWith(
        color: p.paper,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.ink,
      contentTextStyle: AppText.body.copyWith(color: p.paper),
      // The other look's accent is the one that reads on this look's ink.
      actionTextColor:
          (p.isHalloween ? AppPalette.everyday : AppPalette.halloween).accent,
    ),
  );
}

ColorScheme _scheme(AppPalette p) => ColorScheme(
  brightness: p.isHalloween ? Brightness.dark : Brightness.light,
  primary: p.accent,
  onPrimary: p.accentText,
  primaryContainer: p.paperRaised,
  onPrimaryContainer: p.ink,
  // FilledButton.tonal and other quiet pieces: raised paper with ink.
  secondary: p.inkSoft,
  onSecondary: p.paper,
  secondaryContainer: p.paperRaised,
  onSecondaryContainer: p.ink,
  tertiary: p.accent,
  onTertiary: p.accentText,
  tertiaryContainer: p.paperRaised,
  onTertiaryContainer: p.ink,
  error: p.danger,
  onError: p.onDanger,
  errorContainer: p.paperRaised,
  onErrorContainer: p.ink,
  surface: p.paper,
  onSurface: p.ink,
  onSurfaceVariant: p.inkSoft,
  surfaceDim: p.paper,
  surfaceBright: p.paperRaised,
  surfaceContainerLowest: p.paper,
  surfaceContainerLow: p.paper,
  surfaceContainer: p.paper,
  surfaceContainerHigh: p.paper,
  surfaceContainerHighest: p.paperRaised,
  outline: p.outline,
  outlineVariant: p.rule,
  shadow: p.shadow,
  scrim: AppPalette.scrim,
  inverseSurface: p.ink,
  onInverseSurface: p.paper,
  inversePrimary:
      (p.isHalloween ? AppPalette.everyday : AppPalette.halloween).accent,
  surfaceTint: Colors.transparent,
);

OutlineInputBorder _inputBorder(Color color, double width) =>
    OutlineInputBorder(
      borderRadius: AppRadii.control,
      borderSide: BorderSide(color: color, width: width),
    );

DatePickerThemeData _datePicker(AppPalette p, Color disabledInk) {
  // Selected day or year: an accent piece. Today: an accent outline.
  WidgetStateProperty<Color?> ink(Color resting) =>
      WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? p.accentText
            : s.contains(WidgetState.disabled)
            ? disabledInk
            : resting,
      );
  final fill = WidgetStateProperty.resolveWith<Color?>(
    (s) => s.contains(WidgetState.selected) ? p.accent : Colors.transparent,
  );
  return DatePickerThemeData(
    backgroundColor: p.paper,
    surfaceTintColor: Colors.transparent,
    shadowColor: p.shadow,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadii.card,
      side: BorderSide(color: p.edge),
    ),
    headerBackgroundColor: p.paperRaised,
    headerForegroundColor: p.ink,
    headerHeadlineStyle: AppText.title.copyWith(fontSize: 28, height: 34 / 28),
    headerHelpStyle: AppText.small.copyWith(fontWeight: FontWeight.w700),
    subHeaderForegroundColor: p.ink,
    toggleButtonTextStyle: AppText.bodyStrong,
    weekdayStyle: AppText.label.copyWith(color: p.inkSoft),
    dayStyle: AppText.small,
    dayForegroundColor: ink(p.ink),
    dayBackgroundColor: fill,
    dayShape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadii.tag),
    ),
    todayForegroundColor: ink(p.accent),
    todayBackgroundColor: fill,
    todayBorder: BorderSide(color: p.accent, width: 1.5),
    yearStyle: AppText.body,
    yearForegroundColor: ink(p.ink),
    yearBackgroundColor: fill,
    yearShape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadii.control),
    ),
    dividerColor: p.rule,
    // OK is the main action: an accent piece with no underline. Cancel is a
    // quiet ink link, so it never outshines OK. The stock action bar is only
    // 52 tall with 8 px at the side, so the piece is drawn 40 tall inside a
    // 48 px touch target and clears the dialog's rounded corner.
    confirmButtonStyle: TextButton.styleFrom(
      backgroundColor: p.accent,
      foregroundColor: p.accentText,
      minimumSize: const Size(88, 40),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: AppText.button,
    ),
    cancelButtonStyle: TextButton.styleFrom(foregroundColor: p.ink),
  );
}
