part of 'first_run_screen.dart';

// ── Shared pieces for every step ──────────────────────────────────────────

/// Large text (about 150 percent and up) stacks paired buttons.
bool _isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) > 22;

/// The same padding on every step, so headlines and buttons line up: the
/// page margin at the sides, one small step under the progress row.
const _stepPadding = EdgeInsets.fromLTRB(
  AppSpace.page,
  AppSpace.s,
  AppSpace.page,
  AppSpace.xl,
);

/// A step headline that screen readers announce as a heading. Headlines are
/// `title` (Fraunces). The line under it is the app's `body`, or Bumpy's
/// `bumpyStory` when Bumpy is the one speaking ([bumpySpeaks]).
class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.title,
    required this.palette,
    this.subtitle,
    this.bumpySpeaks = false,
  });

  final String title;
  final String? subtitle;
  final AppPalette palette;
  final bool bumpySpeaks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.title.copyWith(color: palette.moonlight),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.s),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: (bumpySpeaks ? AppText.bumpyStory : AppText.body).copyWith(
              color: palette.moonlightSoft,
            ),
          ),
        ],
      ],
    );
  }
}

/// Back and forward for a step. Side by side at normal text sizes; stacked,
/// forward first, when large text would squeeze the labels.
class _StepButtons extends StatelessWidget {
  const _StepButtons({
    required this.palette,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.loading = false,
  });

  final AppPalette palette;
  final VoidCallback onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final back = _SecondaryButton(
      label: 'Back',
      palette: palette,
      onPressed: onBack,
    );
    final forward = _PrimaryButton(
      label: primaryLabel,
      palette: palette,
      onPressed: onPrimary,
      loading: loading,
    );
    if (_isLargeText(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          forward,
          const SizedBox(height: AppSpace.m),
          back,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: back),
        const SizedBox(width: AppSpace.m),
        Expanded(child: forward),
      ],
    );
  }
}

/// The step's one main action. Shape, height and type come from the theme;
/// only the disabled colours are set, so a waiting "Next" still reads as the
/// accent piece on the dark page.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.palette,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final AppPalette palette;
  final VoidCallback? onPressed;
  final bool loading;

  /// Read by a screen reader while the button waits. Only the date step
  /// holds its "Next" back.
  static const disabledHint = 'Choose a date first';

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.accentText,
        // A waiting button is still readable: ink-soft on raised paper
        // (6.0:1 Everyday, 7.1:1 Halloween; a11y audit 2, fix 4).
        disabledBackgroundColor: palette.paperRaised,
        disabledForegroundColor: palette.inkSoft,
        minimumSize: const Size(double.infinity, AppSpace.target),
      ),
      child: loading
          ? Semantics(
              label: 'Saving',
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accentText,
                ),
              ),
            )
          : Text(label, textAlign: TextAlign.center),
    );
    // A dimmed button says why it waits.
    if (onPressed != null || loading) return button;
    return MergeSemantics(
      child: Semantics(hint: disabledHint, child: button),
    );
  }
}

/// "Back": an outlined button on the page (moonlight label, outline edge).
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final AppPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.moonlight,
        side: BorderSide(color: palette.outline, width: 1.5),
        minimumSize: const Size(double.infinity, AppSpace.target),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
