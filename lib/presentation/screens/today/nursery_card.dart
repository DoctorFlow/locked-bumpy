part of 'today_screen.dart';

// ── Nursery card: Bumpy, the costume-and-need pairing, and Bumpy's line ────

class _NurseryCard extends StatelessWidget {
  const _NurseryCard({
    required this.state,
    required this.need,
    required this.palette,
    required this.sceneHeight,
    required this.needTicked,
    required this.babyLine,
    required this.lineIsDraft,
    required this.hopAnimation,
  });

  final AppState state;
  final MaternalNeed need;
  final AppPalette palette;
  final double sceneHeight;
  final bool needTicked;
  final String babyLine;
  final bool lineIsDraft;
  final Animation<double> hopAnimation;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NurseryScene(
            palette: palette,
            height: sceneHeight,
            cornerAction: palette.isHalloween
                ? Tooltip(
                    message: 'Costume closet',
                    child: FilledButton.tonalIcon(
                      onPressed: () => ClosetSheet.open(context, state),
                      icon: const Icon(Icons.checkroom, size: 18),
                      label: const Text('Wardrobe'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: palette.paper,
                        foregroundColor: palette.ink,
                      ),
                    ),
                  )
                : null,
            compactCornerAction: palette.isHalloween
                ? IconButton.filledTonal(
                    key: const ValueKey('wardrobe-compact'),
                    tooltip: 'Wardrobe',
                    onPressed: () => ClosetSheet.open(context, state),
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(48),
                      minimumSize: const Size.square(48),
                      backgroundColor: palette.paper,
                      foregroundColor: palette.ink,
                    ),
                    icon: const Icon(Icons.checkroom, size: 24),
                  )
                : null,
            avatar: BumpyAvatar(
              need: state.costumeOverride ?? need,
              palette: palette,
              happy: needTicked,
              skinTone: state.skinTone,
              hopAnimation: hopAnimation,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The same stack in both looks and at every width: the
                // baby's name, the need tag, then Bumpy's line.
                Semantics(
                  header: true,
                  child: Text(
                    state.babyDisplayName,
                    style: AppText.label.copyWith(color: palette.inkSoft),
                  ),
                ),
                const SizedBox(height: 8),
                _NeedPairing(state: state, need: need, palette: palette),
                if (babyLine.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      babyLine,
                      // The one big serif on Today: Bumpy is talking.
                      style: AppText.bumpy.copyWith(
                        color: palette.ink,
                        fontSize: 26,
                        height: 32 / 26,
                        fontVariations: const [
                          FontVariation('opsz', 26),
                          FontVariation('wght', 600),
                          FontVariation('SOFT', 100),
                          FontVariation('WONK', 1),
                        ],
                      ),
                    ),
                  ),
                  if (lineIsDraft) ...[
                    const SizedBox(height: 4),
                    DraftTag(palette: palette),
                  ],
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The costume and the need it stands for, as one paper tag: the need's
/// icon, a strip of its colour and its name in words, so colour is never the
/// only signal. In the Halloween look it reads "Vampire night · Iron". When
/// the parent has dressed Bumpy in another costume the need stays.
class _NeedPairing extends StatelessWidget {
  const _NeedPairing({
    required this.state,
    required this.need,
    required this.palette,
  });

  final AppState state;
  final MaternalNeed need;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final dressedOther =
        palette.isHalloween &&
        state.costumeOverride != null &&
        state.costumeOverride != need;
    final title = palette.isHalloween && !dressedOther
        ? '${_costumeWord(need)} night · ${needWord(need)}'
        : 'Today · ${needWord(need)}';
    final spoken = palette.isHalloween && !dressedOther
        ? 'Today Bumpy is a ${_costumeWord(need).toLowerCase()}, '
              'for ${needWord(need).toLowerCase()}'
        : 'Today is for ${needWord(need).toLowerCase()}';
    final other = state.costumeOverride;
    return Semantics(
      container: true,
      label: dressedOther && other != null
          ? '$spoken. Dressed as a ${_costumeWord(other).toLowerCase()} for fun.'
          : spoken,
      excludeSemantics: true,
      child: DecoratedBox(
        key: const ValueKey('need-pairing'),
        decoration: _paperTag(palette),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // A strip of the need's own colour, like a paper edge.
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: need.color,
                  borderRadius: BorderRadius.only(
                    topLeft: AppRadii.tag.topLeft,
                    bottomLeft: AppRadii.tag.bottomLeft,
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        need.iconPath,
                        width: 28,
                        height: 28,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppText.heading.copyWith(
                                color: palette.ink,
                              ),
                            ),
                            if (dressedOther && other != null)
                              Text(
                                'Dressed as a ${_costumeWord(other).toLowerCase()} for fun',
                                style: AppText.small.copyWith(
                                  color: palette.inkSoft,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
