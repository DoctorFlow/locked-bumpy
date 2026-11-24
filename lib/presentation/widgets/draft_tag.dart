import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

/// A small, quiet pill beside text that is visible only because this is a
/// review build. A release build never shows a draft, so never this tag.
///
/// [DraftTag.held] marks a stamped record that `assets/content/held.json`
/// holds back for the physician's re-check; it is gated exactly like a draft.
class DraftTag extends StatelessWidget {
  const DraftTag({super.key, this.palette})
    : label = 'Draft',
      semanticsLabel = 'Draft, not reviewed';

  const DraftTag.held({super.key, this.palette})
    : label = 'Held',
      semanticsLabel = 'Held for a re-check';

  /// The tag for a record: Held when [held], otherwise Draft.
  factory DraftTag.of({Key? key, AppPalette? palette, required bool held}) =>
      held
      ? DraftTag.held(key: key, palette: palette)
      : DraftTag(key: key, palette: palette);

  /// Defaults to the look in the theme.
  final AppPalette? palette;

  /// The word on the pill.
  final String label;

  /// What a screen reader says.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? AppPalette.of(context);
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.paperRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.inkSoft),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, size: 16, color: p.inkSoft),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: p.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin strip across the top of a review build, so no screenshot from it
/// can be mistaken for the release. Used by `MaterialApp.builder`.
class ReviewBanner extends StatelessWidget {
  const ReviewBanner({super.key, required this.child});

  final Widget? child;

  static const message = 'Review build: draft text is marked';

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      children: [
        Material(
          color: p.accent,
          child: SafeArea(
            bottom: false,
            child: Semantics(
              container: true,
              label: message,
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.accentText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
