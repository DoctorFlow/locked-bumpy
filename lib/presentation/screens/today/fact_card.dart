part of 'today_screen.dart';

// ── One small fact from today's need, with its source and two quiet actions ─
//
// Kept short on purpose. The fact and the question are reading text (16 px or more);
// only the two one-line captions ("Source: …", "To ask …") are `small`.

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.state,
    required this.need,
    required this.guide,
    required this.fact,
    required this.palette,
    required this.adding,
    required this.addFailed,
    required this.onAddQuestion,
  });

  final AppState state;
  final MaternalNeed need;
  final Guide guide;
  final GuideFact fact;
  final AppPalette palette;
  final bool adding;
  final bool addFailed;
  final ValueChanged<String> onAddQuestion;

  @override
  Widget build(BuildContext context) {
    final question = guide.questions.isEmpty ? null : guide.questions.first;
    final onList = question != null && state.hasVisitQuestion(question);
    // Links on paper: the theme's text button, tighter at the sides so the
    // two actions line up with the text above.
    final quiet = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
    );
    return PaperCard(
      key: const ValueKey('today-fact'),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.l,
        AppSpace.l,
        AppSpace.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.s,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Good to know',
                  style: _cardTitle.copyWith(color: palette.ink),
                ),
              ),
              if (guide.isDraft) DraftTag(palette: palette),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(fact.text, style: AppText.body.copyWith(color: palette.ink)),
          // The source and the way into the guide share one line, which
          // keeps the card short (DESIGN brief: visit card in view).
          Wrap(
            spacing: AppSpace.m,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Source: ${fact.sourceOrg}',
                style: AppText.small.copyWith(color: palette.inkSoft),
              ),
              TextButton.icon(
                key: const ValueKey('fact-open-guide'),
                style: quiet,
                onPressed: () => GuideScreen.open(context, state, need),
                icon: const Icon(Icons.menu_book_outlined, size: 22),
                label: Text('Open the ${needWord(need).toLowerCase()} guide'),
              ),
            ],
          ),
          if (question != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              'To ask your doctor or midwife',
              style: AppText.small.copyWith(color: palette.inkSoft),
            ),
            Text(
              question,
              style: AppText.bodyStrong.copyWith(color: palette.ink),
            ),
          ],
          const SizedBox(height: AppSpace.s),
          // Once added it is a plain note: the visit card below is the one
          // way into the list on Today. The live region wraps both forms, so
          // "On your visit list" is announced when it replaces the button.
          if (question != null)
            Semantics(
              liveRegion: true,
              child: onList
                  ? ConstrainedBox(
                      key: const ValueKey('fact-on-list'),
                      constraints: const BoxConstraints(
                        minHeight: AppSpace.target,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 22,
                            color: palette.ink,
                          ),
                          const SizedBox(width: AppSpace.s),
                          Flexible(
                            child: Text(
                              'On your visit list',
                              style: AppText.bodyStrong.copyWith(
                                color: palette.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  // One action, one form: the full-width outlined button used
                  // on Guides, the guide page and the chapter page.
                  : OutlinedButton.icon(
                      key: const ValueKey('fact-add-question'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSpace.target),
                      ),
                      onPressed: adding ? null : () => onAddQuestion(question),
                      icon: const Icon(Icons.playlist_add, size: 22),
                      label: Text(
                        adding ? 'Adding…' : 'Add to my visit list',
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          const SizedBox(height: AppSpace.s),
          if (addFailed)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s),
                child: Text(
                  'Couldn’t add it on this device. Tap to try again.',
                  style: AppText.body.copyWith(color: palette.danger),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
