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
    // Start is pinned under the story, outside the scroll, so it is always
    // on the first screen. Above it the room, title, story and privacy line
    // sit centred in the space they have, so a tall phone has no empty
    // bottom third and a short one scrolls the story, not the button.
    final story = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: AppRadii.card,
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
            // A narrow room keeps Bumpy's head clear: the lamp alone.
            compactCornerAction: IconButton.filledTonal(
              key: const ValueKey('welcome-lamp-compact'),
              tooltip: palette.isHalloween ? 'Try daylight' : 'Try moonlight',
              onPressed: onSwitchLamp,
              style: IconButton.styleFrom(
                foregroundColor: palette.ink,
                backgroundColor: palette.paper,
                fixedSize: const Size.square(48),
                minimumSize: const Size.square(48),
              ),
              icon: Image.asset(
                'assets/images/nursery-lamp.png',
                width: 22,
                height: 22,
                color: palette.ink,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        // Bumpy introduces itself: the title in the story face, then
        // Bumpy's own words (`bumpyStory`), never the app's face.
        Semantics(
          header: true,
          child: Text(
            'Hello, I’m your Little Bumpy.',
            textAlign: TextAlign.center,
            style: AppText.title.copyWith(color: palette.moonlight),
          ),
        ),
        const SizedBox(height: AppSpace.s),
        Text(
          'I dress up as six everyday needs, share a chapter each week, '
          'and keep your questions for your doctor or midwife.',
          textAlign: TextAlign.center,
          style: AppText.bumpyStory.copyWith(color: palette.moonlight),
        ),
        const SizedBox(height: AppSpace.l),
        MergeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 18, color: palette.moonlightSoft),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Private: everything stays on this device.',
                  style: AppText.bodyStrong.copyWith(
                    color: palette.moonlightSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    const storyPadding = EdgeInsets.fromLTRB(
      AppSpace.page,
      AppSpace.s,
      AppSpace.page,
      AppSpace.s,
    );
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const ValueKey('welcome-story'),
              padding: storyPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - storyPadding.vertical)
                      .clamp(0.0, double.infinity),
                ),
                child: story,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.m,
            AppSpace.page,
            AppSpace.xl,
          ),
          child: _PrimaryButton(
            label: 'Start',
            palette: palette,
            onPressed: onStart,
          ),
        ),
      ],
    );
  }
}
