part of 'first_run_screen.dart';

// ── Step 3: Optional nickname ─────────────────────────────────────────────

class _StepNickname extends StatelessWidget {
  const _StepNickname({
    required this.palette,
    required this.skinTone,
    required this.controller,
    required this.onBack,
    required this.onNext,
  });

  final AppPalette palette;
  final SkinTone skinTone;
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
            subtitle: 'Optional. Leave it blank if you prefer Little Bumpy.',
            palette: palette,
          ),
          const SizedBox(height: AppSpace.xl),
          // Bumpy on a paper card, wearing the name as it is typed.
          _NamedBumpy(
            palette: palette,
            skinTone: skinTone,
            controller: controller,
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

/// Bumpy on a card with a paper name tag that follows the field: the
/// nickname as typed, or "Little Bumpy" while it is empty.
class _NamedBumpy extends StatelessWidget {
  const _NamedBumpy({
    required this.palette,
    required this.skinTone,
    required this.controller,
  });

  final AppPalette palette;
  final SkinTone skinTone;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // A short phone keeps the field and Next on the first screen.
    final short = MediaQuery.sizeOf(context).height < 700;
    return PaperCard(
      key: const ValueKey('first-run-nickname-bumpy'),
      padding: EdgeInsets.all(short ? AppSpace.m : AppSpace.l),
      child: Column(
        children: [
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: short ? 72 : 112,
              child: FittedBox(
                child: BumpyAvatar(
                  need: MaternalNeed.iron,
                  palette: palette,
                  happy: true,
                  skinTone: skinTone,
                ),
              ),
            ),
          ),
          SizedBox(height: short ? AppSpace.s : AppSpace.m),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final name = value.text.trim();
              return DecoratedBox(
                key: const ValueKey('first-run-name-tag'),
                decoration: BoxDecoration(
                  color: palette.paperRaised,
                  borderRadius: AppRadii.tag,
                  border: Border.all(color: palette.edge),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.m,
                    vertical: AppSpace.s,
                  ),
                  child: Text(
                    name.isEmpty ? 'Little Bumpy' : name,
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong.copyWith(color: palette.ink),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
