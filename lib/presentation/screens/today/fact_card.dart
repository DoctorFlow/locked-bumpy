part of 'today_screen.dart';

// ── One small fact from today's need, with its source and two quiet actions ─

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
    final quiet = TextButton.styleFrom(
      foregroundColor: palette.ink,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: const RoundedRectangleBorder(borderRadius: _controlCorners),
    );
    return _PaperCard(
      key: const ValueKey('today-fact'),
      palette: palette,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Good to know',
                    style: _T.bodyStrong.copyWith(color: palette.inkSoft),
                  ),
                ),
                if (guide.isDraft) DraftTag(palette: palette),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              fact.text,
              style: _T.body.copyWith(
                fontSize: 18,
                height: 26 / 18,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Source: ${fact.sourceOrg}',
              style: _T.body.copyWith(color: palette.inkSoft),
            ),
            if (question != null) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: palette.inkSoft.withValues(alpha: .3)),
              const SizedBox(height: 12),
              Text(
                'To ask your doctor or midwife',
                style: _T.body.copyWith(color: palette.inkSoft),
              ),
              Text(question, style: _T.bodyStrong.copyWith(color: palette.ink)),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                // Once added it is a plain note: the visit card below is the
                // one way into the list on Today.
                if (question != null && onList)
                  ConstrainedBox(
                    key: const ValueKey('fact-on-list'),
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 22,
                            color: palette.ink,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'On your visit list',
                              style: _T.bodyStrong.copyWith(color: palette.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (question != null)
                  Semantics(
                    liveRegion: true,
                    child: TextButton.icon(
                      key: const ValueKey('fact-add-question'),
                      style: quiet,
                      onPressed: adding ? null : () => onAddQuestion(question),
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: Text(
                        adding ? 'Adding…' : 'Add to my visit list',
                        style: _T.bodyStrong,
                      ),
                    ),
                  ),
                TextButton.icon(
                  key: const ValueKey('fact-open-guide'),
                  style: quiet,
                  onPressed: () => GuideScreen.open(context, state, need),
                  icon: const Icon(Icons.menu_book_outlined, size: 22),
                  label: Text(
                    'Open the ${_needWord(need).toLowerCase()} guide',
                    style: _T.bodyStrong,
                  ),
                ),
              ],
            ),
            if (addFailed)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Couldn’t add it on this device. Tap to try again.',
                    style: _T.body.copyWith(color: palette.ink),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
