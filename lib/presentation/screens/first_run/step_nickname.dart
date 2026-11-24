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
          const SizedBox(height: 24),

          TextField(
            controller: controller,
            maxLength: 24,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(fontSize: 18, color: palette.ink),
            decoration: InputDecoration(
              hintText: 'e.g. Peanut, Sprout…',
              hintStyle: TextStyle(color: palette.inkSoft),
              filled: true,
              fillColor: palette.paper,
              counterStyle: TextStyle(
                color: palette.moonlightSoft,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),

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
