part of 'first_run_screen.dart';

// ── Step 3: Look selector ─────────────────────────────────────────────────

class _Step3Look extends StatelessWidget {
  const _Step3Look({
    required this.palette,
    required this.skinTone,
    required this.onTone,
    required this.isHalloween,
    required this.saving,
    required this.onToggle,
    required this.onBack,
    required this.onConfirm,
  });

  final AppPalette palette;
  final bool isHalloween;
  final bool saving;
  final SkinTone skinTone;
  final ValueChanged<SkinTone> onTone;
  final ValueChanged<bool> onToggle;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick a look.',
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
            'You can switch any time with the lamp.',
            style: TextStyle(fontSize: 14, color: palette.moonlightSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
              final width = largeText
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final look in [
                    AppPalette.halloween,
                    AppPalette.everyday,
                  ])
                    SizedBox(
                      width: width,
                      child: _LookCard(
                        label: look.isHalloween ? 'Halloween' : 'Everyday',
                        description: look.isHalloween
                            ? 'Midnight plum, pumpkin moon'
                            : 'Warm cream, storybook',
                        selected: look.isHalloween == isHalloween,
                        look: look,
                        skinTone: skinTone,
                        onTap: () => onToggle(look.isHalloween),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SkinTonePicker(
            selected: skinTone,
            onSelected: onTone,
            foreground: palette.moonlight,
          ),
          const SizedBox(height: 24),

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
                  label: "Let's go",
                  palette: palette,
                  onPressed: saving ? null : onConfirm,
                  loading: saving,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            AppConstants.disclaimer,
            style: TextStyle(
              fontSize: 11,
              color: palette.moonlightSoft,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LookCard extends StatelessWidget {
  const _LookCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.look,
    required this.skinTone,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final AppPalette look;
  final SkinTone skinTone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperChoice(
      label: '$label. $description',
      selected: selected,
      onTap: onTap,
      focusColor: look.ink,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: look.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? look.accent : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.3 : 0.15),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image(
                image: paperPortrait(
                  MaternalNeed.iron.assetPath(look),
                  skinTone,
                ),
                width: 96,
                height: 96,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: look.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: look.inkSoft, height: 1.3),
            ),
            const SizedBox(height: 10),
            if (selected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: look.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 13, color: look.accentText),
              )
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: look.ink.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
