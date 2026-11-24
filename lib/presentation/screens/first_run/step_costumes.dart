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
          _StepHeading(
            title: halloween
                ? 'Six costumes, six everyday needs'
                : 'Six everyday needs',
            subtitle: halloween
                ? 'Each day I wear one of them.'
                : 'Each day I show you one of them.',
            palette: palette,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final width = constraints.maxWidth;
              final columns = _isLargeText(context)
                  ? 1
                  : (width - 2 * gap) / 3 >= 96
                  ? 3
                  : 2;
              final tileWidth = (width - (columns - 1) * gap) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final need in MaternalNeed.values)
                    SizedBox(
                      width: tileWidth,
                      child: _NeedTile(
                        key: ValueKey('first-run-need-${need.name}'),
                        need: need,
                        palette: palette,
                        skinTone: skinTone,
                        wide: columns == 1,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _StepButtons(
            palette: palette,
            onBack: onBack,
            primaryLabel: 'Enter the nursery',
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
        borderRadius: BorderRadius.circular(16),
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
      need.label,
      textAlign: wide ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: palette.ink,
        height: 1.2,
      ),
    );
    return Semantics(
      container: true,
      label: halloween
          ? '${need.label}, ${need.costume.toLowerCase()} costume'
          : need.label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: wide
            ? Row(
                children: [
                  picture,
                  const SizedBox(width: 14),
                  Expanded(child: word),
                ],
              )
            : Column(children: [picture, const SizedBox(height: 8), word]),
      ),
    );
  }
}
