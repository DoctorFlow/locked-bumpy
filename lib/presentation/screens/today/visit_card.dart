part of 'today_screen.dart';

// ── For your visit: the one home of the visit list on Today ───────────────
//
// It shows the first question in words and "Show at my visit". When today's
// need has no guide (so no fact card with its "add a question" action), it
// also holds the one-tap "Save <need> for my visit" topic control.

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.state,
    required this.palette,
    required this.need,
    required this.showTopicControl,
    required this.savedForVisit,
    required this.savingTopic,
    required this.saveFailed,
    required this.onSaveForVisit,
  });

  final AppState state;
  final AppPalette palette;
  final MaternalNeed need;
  final bool showTopicControl;
  final bool savedForVisit;
  final bool savingTopic;
  final bool saveFailed;
  final VoidCallback onSaveForVisit;

  @override
  Widget build(BuildContext context) {
    final questions = state.visitQuestions;
    final topics = MaternalNeed.values
        .where(state.visitTopics.contains)
        .toList();
    final empty = questions.isEmpty && topics.isEmpty;
    final quiet = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      alignment: AlignmentDirectional.centerStart,
    );

    final children = <Widget>[
      Semantics(
        header: true,
        child: Text(
          'For your visit',
          style: _cardTitle.copyWith(color: palette.ink),
        ),
      ),
    ];
    if (empty) {
      children.addAll([
        const SizedBox(height: AppSpace.s),
        // A raised row on the card, not a link: the whole row is the button.
        PaperCard(
          raised: true,
          child: Semantics(
            button: true,
            child: InkWell(
              key: const ValueKey('visit-invite'),
              onTap: () => VisitTopics.edit(context, state),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSpace.row),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.m,
                    vertical: AppSpace.s,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, size: 24, color: palette.ink),
                      const SizedBox(width: AppSpace.m),
                      Expanded(
                        child: Text(
                          'A question for your doctor or midwife? Add it here.',
                          style: AppText.bodyStrong.copyWith(
                            color: palette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.s),
                      ExcludeSemantics(
                        child: Icon(
                          Icons.chevron_right,
                          size: 24,
                          color: palette.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    } else {
      // The parent's newest own words come first, so they see them the
      // moment the app opens; else a picked question, else a topic. No count
      // of the rest: the list is a help, not a pile.
      final own = state.newestOwnQuestion;
      final first = own.isNotEmpty
          ? own
          : questions.isNotEmpty
          ? state.visitQuestionsOwnFirst.first.text
          : needWord(topics.first);
      final more = questions.length + topics.length > 1;
      children.addAll([
        const SizedBox(height: 4),
        Text(
          first,
          key: const ValueKey('visit-card-question'),
          style: AppText.heading.copyWith(color: palette.ink),
        ),
        if (more) ...[
          const SizedBox(height: 4),
          Text(
            'More on your list',
            style: AppText.body.copyWith(color: palette.inkSoft),
          ),
        ],
      ]);
    }
    if (showTopicControl) {
      children.add(
        Semantics(
          liveRegion: true,
          child: TextButton.icon(
            key: const ValueKey('visit-topic-today'),
            style: quiet,
            icon: CustomPaint(
              size: const Size.square(28),
              painter: _PaperPocket(palette, savedForVisit),
            ),
            label: Text(
              savedForVisit
                  ? '${needWord(need)} saved · View visit list'
                  : savingTopic
                  ? 'Saving…'
                  : 'Save ${needWord(need)} for my visit',
            ),
            onPressed: savingTopic
                ? null
                : savedForVisit
                ? () => VisitTopics.edit(context, state)
                : onSaveForVisit,
          ),
        ),
      );
      if (saveFailed) {
        children.add(
          Semantics(
            liveRegion: true,
            child: Text(
              'Couldn’t save to your visit list. Tap to try again.',
              style: AppText.body.copyWith(color: palette.danger),
            ),
          ),
        );
      }
    }
    if (!empty) {
      children.addAll([
        const SizedBox(height: 12),
        // The card's one main action: a plain accent button.
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpace.target),
          ),
          onPressed: () => VisitScreen.open(context, state),
          icon: const Icon(Icons.fullscreen, size: 22),
          label: const Text('Show at my visit', textAlign: TextAlign.center),
        ),
      ]);
    }

    return PaperCard(
      key: ValueKey(empty ? 'visit-empty' : 'visit-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
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
      paint.color = palette.paperRaised;
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
    paint.color = palette.accent;
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
