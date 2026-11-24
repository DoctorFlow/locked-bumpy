part of 'first_run_screen.dart';

// ── Step 4: Look selector ─────────────────────────────────────────────────

class _StepLook extends StatelessWidget {
  const _StepLook({
    required this.palette,
    required this.skinTone,
    required this.onTone,
    required this.isHalloween,
    required this.onToggle,
    required this.onBack,
    required this.onNext,
  });

  final AppPalette palette;
  final bool isHalloween;
  final SkinTone skinTone;
  final ValueChanged<SkinTone> onTone;
  final ValueChanged<bool> onToggle;
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
            title: 'Pick a look.',
            subtitle: 'You can switch any time with the lamp.',
            palette: palette,
          ),
          const SizedBox(height: AppSpace.xl),

          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = _isLargeText(context);
              final width = largeText
                  ? constraints.maxWidth
                  : (constraints.maxWidth - AppSpace.m) / 2;
              return Wrap(
                spacing: AppSpace.m,
                runSpacing: AppSpace.m,
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
          const SizedBox(height: AppSpace.xl),
          SkinTonePicker(
            selected: skinTone,
            onSelected: onTone,
            foreground: palette.moonlight,
          ),
          const SizedBox(height: 24),

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
      borderRadius: AppRadii.card,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpace.m),
        // A paper card of that look; selected = accent edge plus the tick.
        decoration: BoxDecoration(
          color: look.paper,
          borderRadius: AppRadii.card,
          border: Border.all(
            color: selected ? look.accent : look.edge,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: paperShadows(look, raised: true),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppText.heading.copyWith(color: look.ink),
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                _SelectedMark(selected: selected, look: look),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppText.small.copyWith(color: look.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.selected, required this.look});

  final bool selected;
  final AppPalette look;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? look.accent : null,
        shape: BoxShape.circle,
        border: selected ? null : Border.all(color: look.outline, width: 1.5),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 16, color: look.accentText)
          : null,
    );
  }
}
