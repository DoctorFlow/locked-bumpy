part of 'today_screen.dart';

// ── For your visit: the one home of the visit list on Today ───────────────
//
// The parent's newest own words sit in a slim strip right under Bumpy
// (`_OwnWordsStrip`), so the card shows the rest of the list, or an
// "add another" row when that question is all there is, and "Show at my
// visit". When today's need has no guide (so no fact card with its "add a question" action), it
// also holds the one-tap "Save <need> for my visit" topic control.

/// [text] trimmed, with a full stop only when it does not already end
/// in one (or in a question or exclamation mark), so a screen reader
/// never reads "?.".
String withFullStop(String text) {
  final t = text.trim();
  if (t.isEmpty) return t;
  return RegExp(r'[.?!\u2026]$').hasMatch(t) ? t : '$t.';
}

/// The parent's newest question in their own words, right under Bumpy's
/// line, so a parent who reopens the app at the appointment finds it at
/// once. A slim strip of paper; the whole strip opens "Show at my visit".
/// Absent when there is no question in the parent's own words.
class _OwnWordsStrip extends StatelessWidget {
  const _OwnWordsStrip({
    required this.state,
    required this.palette,
    required this.question,
  });

  final AppState state;
  final AppPalette palette;
  final String question;

  /// The small quiet label in front of the question.
  static const label = 'My question';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: ${withFullStop(question)} Show at my visit',
      excludeSemantics: true,
      onTap: () => VisitScreen.open(context, state),
      child: PaperCard(
        key: const ValueKey('own-words-strip'),
        child: InkWell(
          onTap: () => VisitScreen.open(context, state),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpace.target),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.m,
                AppSpace.s,
                AppSpace.s,
                AppSpace.s,
              ),
              child: Row(
                children: [
                  // The quiet label on its own line, then the words in
                  // quotes with the full width, up to two lines. The
                  // ellipsis shows only past two lines.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          key: const ValueKey('own-words-strip-label'),
                          style: AppText.label.copyWith(color: palette.inkSoft),
                        ),
                        Text(
                          '“$question”',
                          key: const ValueKey('own-words-strip-question'),
                          style: AppText.bodyStrong.copyWith(
                            color: palette.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Icon(Icons.chevron_right, size: 24, color: palette.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    // What the card shows below the strip: everything but the newest own
    // words, which the strip under Bumpy already holds. (text, is a question)
    final stripped = state.newestOwnQuestion;
    final rest = <(String, bool)>[
      for (final q in state.visitQuestionsOwnFirst)
        if (q.text != stripped) (q.text, true),
      for (final need in topics) (needWord(need), false),
    ];
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
    } else if (rest.isEmpty) {
      // The strip under Bumpy already shows the one question, so the card
      // does not repeat it: it offers to add another instead.
      children.addAll([
        const SizedBox(height: AppSpace.s),
        PaperCard(
          raised: true,
          child: Semantics(
            button: true,
            child: InkWell(
              key: const ValueKey('visit-add-another'),
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
                      Icon(Icons.add, size: 24, color: palette.ink),
                      const SizedBox(width: AppSpace.m),
                      Expanded(
                        child: Text(
                          'Another question? Add it here.',
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
      // The newest own words sit in the strip under Bumpy; the card shows
      // the next thing on the list (own words first, then a picked
      // question, then a topic). No count of the rest: the list is a help,
      // not a pile.
      final first = rest.first;
      final more = rest.length > 1;
      final isQuestion = first.$2;
      children.addAll([
        const SizedBox(height: AppSpace.s),
        // The parent's own question on a raised piece of paper, in quotes
        // like the chapter page's questions, so it reads as theirs and not
        // as a second heading.
        PaperCard(
          key: const ValueKey('visit-card-question-piece'),
          raised: true,
          padding: const EdgeInsets.all(AppSpace.m),
          child: Text(
            // A topic name alone ("Iron") is not a quote.
            isQuestion ? '“${first.$1}”' : first.$1,
            key: const ValueKey('visit-card-question'),
            style: AppText.body.copyWith(
              fontSize: 18,
              height: 26 / 18,
              color: palette.ink,
            ),
          ),
        ),
        if (more) ...[
          // Clear of the raised piece's shadow.
          const SizedBox(height: AppSpace.s),
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
