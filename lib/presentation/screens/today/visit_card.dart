part of 'today_screen.dart';

// ── For your visit: the first question in words and "Show at my visit" ────

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.state, required this.palette});

  final AppState state;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final questions = state.visitQuestions;
    final topics = MaternalNeed.values
        .where(state.visitTopics.contains)
        .toList();
    if (questions.isEmpty && topics.isEmpty) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('visit-invite'),
          style: TextButton.styleFrom(
            foregroundColor: palette.moonlight,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => VisitTopics.edit(context, state),
          icon: const Icon(Icons.edit_note, size: 22),
          label: const Text(
            'A question for your doctor or midwife? Add it here.',
          ),
        ),
      );
    }
    // The parent's own words come first; a guide question or a topic after.
    final own = state.visitQuestion;
    final first = own.isNotEmpty
        ? own
        : questions.isNotEmpty
        ? questions.first.text
        : topics.first.label;
    final more = questions.length + topics.length - 1;
    return Material(
      key: const ValueKey('visit-card'),
      color: palette.paperRaised,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'For your visit',
                style: TextStyle(
                  color: palette.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              first,
              style: TextStyle(
                color: palette.ink,
                fontSize: 18,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (more > 0) ...[
              const SizedBox(height: 4),
              Text(
                more == 1
                    ? 'And 1 more on your list'
                    : 'And $more more on your list',
                style: TextStyle(color: palette.inkSoft, fontSize: 14),
              ),
            ],
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: palette.ink,
                foregroundColor: palette.paper,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => VisitScreen.open(context, state),
              icon: const Icon(Icons.fullscreen, size: 20),
              label: const Text(
                'Show at my visit',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
