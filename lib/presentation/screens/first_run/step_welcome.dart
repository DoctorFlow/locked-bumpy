part of 'first_run_screen.dart';

// ── Step 1: Welcome ───────────────────────────────────────────────────────

class _StepWelcome extends StatelessWidget {
  const _StepWelcome({
    required this.palette,
    required this.skinTone,
    required this.onSwitchLamp,
    required this.onStart,
  });

  final AppPalette palette;
  final SkinTone skinTone;
  final VoidCallback onSwitchLamp;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: _stepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: NurseryScene(
              palette: palette,
              // Big on a tall phone, still leaving Start in view on a short one.
              height: (MediaQuery.sizeOf(context).height * 0.3).clamp(
                150.0,
                230.0,
              ),
              avatar: BumpyAvatar(
                need: MaternalNeed.iron,
                palette: palette,
                happy: true,
                skinTone: skinTone,
              ),
              cornerAction: FilledButton.tonalIcon(
                onPressed: onSwitchLamp,
                icon: Image.asset(
                  'assets/images/nursery-lamp.png',
                  width: 18,
                  height: 18,
                  color: palette.ink,
                  excludeFromSemantics: true,
                ),
                label: Text(
                  palette.isHalloween ? 'Try daylight' : 'Try moonlight',
                ),
                style: FilledButton.styleFrom(
                  foregroundColor: palette.ink,
                  backgroundColor: palette.paper,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              'Hello, I’m your Little Bumpy.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: palette.moonlight,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'I dress up as six everyday needs, share a chapter each week, '
            'and keep your questions for your doctor or midwife.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: palette.moonlight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          MergeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: palette.moonlightSoft,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Private: everything stays on this device.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.moonlightSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(label: 'Start', palette: palette, onPressed: onStart),
        ],
      ),
    );
  }
}
