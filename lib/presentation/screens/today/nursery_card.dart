part of 'today_screen.dart';

// ── Nursery card: Bumpy, the baby line and "Save for my visit" ─────────────

class _NurseryCard extends StatelessWidget {
  const _NurseryCard({
    required this.state,
    required this.need,
    required this.palette,
    required this.sideBySide,
    required this.needTicked,
    required this.babyLine,
    required this.savedForVisit,
    required this.savingTopic,
    required this.saveFailed,
    required this.hopAnimation,
    required this.onSaveForVisit,
  });

  final AppState state;
  final MaternalNeed need;
  final AppPalette palette;
  final bool sideBySide;
  final bool needTicked;
  final String babyLine;
  final bool savedForVisit;
  final bool savingTopic;
  final bool saveFailed;
  final Animation<double> hopAnimation;
  final VoidCallback onSaveForVisit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.paper,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NurseryScene(
            palette: palette,
            height: sideBySide ? 156 : 204,
            cornerAction: palette.isHalloween
                ? Tooltip(
                    message: 'Costume closet',
                    child: FilledButton.tonalIcon(
                      onPressed: () => ClosetSheet.open(context, state),
                      icon: const Icon(Icons.checkroom, size: 18),
                      label: const Text('Wardrobe'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: palette.paper,
                        foregroundColor: palette.ink,
                      ),
                    ),
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
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        state.babyDisplayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    Text(
                      state.costumeOverride != null && palette.isHalloween
                          ? 'TODAY · ${need.needName}'
                          : need.tag(palette),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: .5,
                        fontWeight: FontWeight.w600,
                        color: palette.inkSoft,
                      ),
                    ),
                  ],
                ),
                if (babyLine.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      babyLine,
                      style: TextStyle(
                        fontSize: 21,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Semantics(
                  liveRegion: true,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.ink,
                      minimumSize: const Size(0, 48),
                    ),
                    icon: Uri.base.queryParameters['visit-control'] == 'plain'
                        ? Icon(
                            savedForVisit
                                ? Icons.bookmark
                                : Icons.bookmark_add_outlined,
                            size: 28,
                          )
                        : CustomPaint(
                            size: const Size.square(28),
                            painter: _PaperPocket(palette, savedForVisit),
                          ),
                    label: Text(
                      savedForVisit
                          ? '${need.label} saved · View visit list'
                          : savingTopic
                          ? 'Saving…'
                          : 'Save ${need.label} for my visit',
                    ),
                    onPressed: savingTopic
                        ? null
                        : savedForVisit
                        ? () => VisitTopics.edit(context, state)
                        : onSaveForVisit,
                  ),
                ),
                if (saveFailed)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Couldn’t save to your visit list. Tap to try again.',
                      style: TextStyle(color: palette.ink),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperPocket extends CustomPainter {
  const _PaperPocket(this.palette, this.saved);

  final AppPalette palette;
  final bool saved;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    final paint = Paint()..color = palette.inkSoft;
    canvas.drawPath(
      Path()
        ..moveTo(2, 8)
        ..lineTo(25, 6)
        ..lineTo(24, 19)
        ..lineTo(3, 21)
        ..close(),
      paint,
    );
    if (saved) {
      paint.color = palette.isHalloween
          ? const Color(0xffffeac5)
          : const Color(0xfffffae8);
      canvas.drawPath(
        Path()
          ..moveTo(7, 3)
          ..lineTo(20, 1)
          ..lineTo(22, 15)
          ..lineTo(9, 17)
          ..close(),
        paint,
      );
    }
    paint.color = palette.isHalloween
        ? const Color(0xffd7a4bc)
        : const Color(0xff90526e);
    canvas.drawPath(
      Path()
        ..moveTo(2, 9)
        ..lineTo(13, 14)
        ..lineTo(25, 7)
        ..lineTo(24, 21)
        ..lineTo(14, 26)
        ..lineTo(4, 22)
        ..close(),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PaperPocket old) =>
      old.saved != saved || old.palette != palette;
}
