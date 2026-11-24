part of 'first_run_screen.dart';

// ── Step 5: Six costumes, six everyday needs ──────────────────────────────

/// The six needs in a tidy grid, each with its word only. The Halloween look
/// shows Bumpy in each costume; the Everyday look shows each need the way that
/// look does elsewhere: its icon, its colour and its word.
class _StepCostumes extends StatelessWidget {
  const _StepCostumes({
    required this.palette,
    required this.skinTone,
    required this.saving,
    required this.onBack,
    required this.onConfirm,
  });

  final AppPalette palette;
  final SkinTone skinTone;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final halloween = palette.isHalloween;
    return SingleChildScrollView(
      padding: _stepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!halloween) ...[
            // In the Everyday look the tiles are icons, so Bumpy stands
            // above them and says the line under the title.
            Center(
              child: SizedBox.square(
                key: const ValueKey('first-run-needs-bumpy'),
                dimension: 96,
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
            const SizedBox(height: AppSpace.s),
          ],
          _StepHeading(
            title: halloween
                ? 'Six costumes, six everyday needs'
                : 'Six everyday needs',
            subtitle: halloween
                ? 'Each day I wear one of them.'
                : 'Each day I show you one of them.',
            bumpySpeaks: true,
            palette: palette,
          ),
          const SizedBox(height: AppSpace.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpace.s;
              final width = constraints.maxWidth;
              // Three across down to a 320 px phone (88 px tiles hold the
              // 72 px picture); one per row at large text.
              final columns = _isLargeText(context)
                  ? 1
                  : (width - 2 * gap) / 3 >= 88
                  ? 3
                  : 2;
              const needs = MaternalNeed.values;
              // Rows of equal height, so a two-line word ("Prenatal
              // vitamin") never leaves its tile taller than its neighbours.
              return Column(
                children: [
                  for (var i = 0; i < needs.length; i += columns) ...[
                    if (i > 0) const SizedBox(height: gap),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var j = i; j < i + columns; j++) ...[
                            if (j > i) const SizedBox(width: gap),
                            Expanded(
                              child: j < needs.length
                                  ? _NeedTile(
                                      key: ValueKey(
                                        'first-run-need-${needs[j].name}',
                                      ),
                                      need: needs[j],
                                      palette: palette,
                                      skinTone: skinTone,
                                      wide: columns == 1,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _StepButtons(
            palette: palette,
            onBack: onBack,
            primaryLabel: 'Meet Bumpy',
            onPrimary: saving ? null : onConfirm,
            loading: saving,
          ),
        ],
      ),
    );
  }
}

class _NeedTile extends StatelessWidget {
  const _NeedTile({
    super.key,
    required this.need,
    required this.palette,
    required this.skinTone,
    required this.wide,
  });

  final MaternalNeed need;
  final AppPalette palette;
  final SkinTone skinTone;

  /// One tile per row (large text): picture beside the word.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final halloween = palette.isHalloween;
    final picture = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: need.color.withValues(alpha: 0.28),
        borderRadius: AppRadii.control,
        border: Border.all(color: need.color, width: 2),
      ),
      padding: EdgeInsets.all(halloween ? 2 : 14),
      child: halloween
          ? Image(
              image: paperPortrait(need.assetPath(palette), skinTone),
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            )
          : Image.asset(
              need.iconPath,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
    );
    final word = Text(
      needWord(need),
      textAlign: wide ? TextAlign.start : TextAlign.center,
      style: AppText.bodyStrong.copyWith(color: palette.ink),
    );
    return Semantics(
      container: true,
      label: halloween
          ? '${needWord(need)}, ${need.costume.toLowerCase()} costume'
          : needWord(need),
      excludeSemantics: true,
      child: PaperCard(
        padding: EdgeInsets.all(wide ? AppSpace.m : AppSpace.s),
        child: wide
            ? Row(
                children: [
                  picture,
                  const SizedBox(width: AppSpace.m),
                  Expanded(child: word),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  picture,
                  const SizedBox(height: AppSpace.s),
                  word,
                ],
              ),
      ),
    );
  }
}
