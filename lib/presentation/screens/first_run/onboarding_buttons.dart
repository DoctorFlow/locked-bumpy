part of 'first_run_screen.dart';

// ── Shared pieces for every step ──────────────────────────────────────────

/// Large text (about 150 percent and up) stacks paired buttons.
bool _isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) > 22;

/// The same padding on every step, so headlines and buttons line up.
const _stepPadding = EdgeInsets.fromLTRB(24, 12, 24, 24);

/// A step headline that screen readers announce as a heading.
class _StepHeading extends StatelessWidget {
  const _StepHeading({
    required this.title,
    required this.palette,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final AppPalette palette;

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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: palette.moonlight,
              height: 1.2,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: palette.moonlightSoft,
              height: 1.35,
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
        children: [forward, const SizedBox(height: 12), back],
      );
    }
    return Row(
      children: [
        Expanded(child: back),
        const SizedBox(width: 12),
        Expanded(child: forward),
      ],
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.accentText,
        disabledBackgroundColor: palette.accent.withValues(alpha: 0.35),
        disabledForegroundColor: palette.accentText.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          : Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}

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
        side: BorderSide(color: palette.moonlightSoft.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
