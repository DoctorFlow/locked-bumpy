part of 'first_run_screen.dart';

// ── Step 3: Optional nickname ─────────────────────────────────────────────

class _StepNickname extends StatelessWidget {
  const _StepNickname({
    required this.palette,
    required this.controller,
    required this.onBack,
    required this.onNext,
  });

  final AppPalette palette;
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: _stepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeading(
            title: 'Give the baby a nickname?',
            subtitle: 'Optional — skip if you prefer Little Bumpy.',
            palette: palette,
          ),
          const SizedBox(height: AppSpace.xl),

          TextField(
            controller: controller,
            maxLength: 24,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.words,
            style: AppText.body.copyWith(color: palette.ink),
            // The themed field: raised paper, outline edge, control corners.
            // Colours named so the contrast test can read them; only the
            // counter differs, because it sits on the page.
            decoration: InputDecoration(
              hintText: 'e.g. Peanut, Sprout…',
              hintStyle: AppText.body.copyWith(color: palette.inkSoft),
              fillColor: palette.paperRaised,
              counterStyle: AppText.label.copyWith(
                color: palette.moonlightSoft,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.l),

          _StepButtons(
            palette: palette,
            onBack: onBack,
            primaryLabel: 'Next',
            onPrimary: onNext,
          ),
        ],
      ),
    );
  }
}
