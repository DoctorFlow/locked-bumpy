part of 'first_run_screen.dart';

// ── Step 2: Optional nickname ─────────────────────────────────────────────

class _Step2Nickname extends StatelessWidget {
  const _Step2Nickname({
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
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Give the baby a nickname?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.moonlight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Optional — skip if you prefer Little Bumpy.',
            style: TextStyle(fontSize: 14, color: palette.moonlightSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

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
                fontSize: 11,
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
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Back',
                  palette: palette,
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryButton(
                  label: 'Next',
                  palette: palette,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
