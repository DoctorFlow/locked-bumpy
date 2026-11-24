part of 'today_screen.dart';

// ── Check-ins: three optional ticks, the saved summary and save status ─────

class _CheckInsPanel extends StatelessWidget {
  const _CheckInsPanel({
    required this.state,
    required this.need,
    required this.checkIns,
    required this.palette,
    required this.allDone,
    required this.reviewing,
    required this.onReview,
    required this.onEndReview,
    required this.onCheckIn,
  });

  final AppState state;
  final MaternalNeed need;
  final List<MaternalNeed> checkIns;
  final AppPalette palette;
  final bool allDone;
  final bool reviewing;
  final VoidCallback onReview;
  final VoidCallback onEndReview;
  final ValueChanged<String> onCheckIn;

  @override
  Widget build(BuildContext context) {
    final summary = allDone && !reviewing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary)
          _SavedCheckIns(
            needs: checkIns,
            palette: palette,
            onReview: onReview,
            onWeek: () => state.setTab(1),
          )
        else
          Semantics(
            header: true,
            child: Text(
              allDone ? 'Saved check-ins' : "Today's check-ins",
              style: AppText.heading.copyWith(color: palette.moonlight),
            ),
          ),
        // Always shown, so the rows never jump under a finger mid-tap.
        if (!summary) ...[
          const SizedBox(height: 4),
          Text(
            allDone
                ? 'Tap a checked row to undo it.'
                : 'Tick any that fit your day.',
            style: AppText.body.copyWith(color: palette.moonlightSoft),
          ),
        ],
        const SizedBox(height: 8),
        if (!summary)
          PaperCard(
            raised: true,
            child: Column(
              children: [
                for (final item in checkIns) ...[
                  if (item != checkIns.first)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 12,
                      color: palette.rule,
                    ),
                  _CheckInTile(
                    key: ValueKey(item),
                    title: item == need
                        ? '${need.needName} · Need of the Day'
                        : item.label,
                    subtitle: _checkInHint(item),
                    need: item,
                    isTicked: state.isChecked(item.name),
                    palette: palette,
                    onTap: () => onCheckIn(item.name),
                  ),
                ],
              ],
            ),
          ),
        if (state.checkInStatus != CheckInSaveStatus.saved)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.s),
              // Never bare on the page: the save status is a paper piece.
              child: PaperCard(
                raised: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.m,
                  AppSpace.m,
                  AppSpace.m,
                  AppSpace.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      state.checkInStatus == CheckInSaveStatus.saving
                          ? 'Saving check-ins…'
                          : 'Your check-ins couldn’t be saved on this device.',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: palette.ink),
                    ),
                    if (state.checkInStatus == CheckInSaveStatus.failed)
                      TextButton(
                        onPressed: state.retryCheckIns,
                        child: const Text('Retry save'),
                      )
                    else
                      const SizedBox(height: AppSpace.s),
                  ],
                ),
              ),
            ),
          ),
        if (allDone && reviewing)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: palette.moonlight),
            onPressed: onEndReview,
            child: const Text('Back to summary'),
          ),
        // The way into This Week; the summary card carries its own.
        if (!summary) ...[
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: const ValueKey('today-week-link'),
              // Outlined on the page: moonlight label, outline edge.
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.moonlight,
                side: BorderSide(color: palette.outline, width: 1.5),
              ),
              onPressed: () => state.setTab(1),
              icon: const Icon(Icons.auto_stories_outlined, size: 22),
              label: Text(
                'Get ready for week ${state.currentWeek ?? AppConstants.minWeek}',
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        Text(
          TodayScreen.disclaimer,
          style: AppText.small.copyWith(color: palette.moonlightSoft),
          textAlign: TextAlign.center,
        ),
        // Beside the safety line, a quiet link to the urgent signs: a text
        // button (underlined, 48 px) in moonlight, which reads on the page in
        // both looks.
        Center(
          child: TextButton(
            key: const ValueKey('today-urgent-link'),
            style: TextButton.styleFrom(foregroundColor: palette.moonlight),
            onPressed: () => UrgentScreen.open(context, state),
            child: const Text(
              'When to get help right away',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedCheckIns extends StatelessWidget {
  const _SavedCheckIns({
    required this.needs,
    required this.palette,
    required this.onReview,
    required this.onWeek,
  });
  final List<MaternalNeed> needs;
  final AppPalette palette;
  final VoidCallback onReview;
  final VoidCallback onWeek;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      raised: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final need in needs)
                  Image.asset(
                    need.iconPath,
                    height: 28,
                    width: 28,
                    excludeFromSemantics: true,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                'Today’s check-ins are saved',
                style: _cardTitle.copyWith(color: palette.ink),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              needs.map(_needWord).join(' · '),
              style: AppText.body.copyWith(color: palette.inkSoft),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpace.target),
              ),
              onPressed: onWeek,
              icon: const Icon(Icons.auto_stories_outlined, size: 22),
              label: const Text(
                'Open this week’s card',
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: onReview,
              child: const Text('Review saved check-ins'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable check-in tile ─────────────────────────────────────────────────

class _CheckInTile extends StatelessWidget {
  const _CheckInTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.need,
    required this.isTicked,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final MaternalNeed need;
  final bool isTicked;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title check-in',
      checked: isTicked,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Image.asset(
                need.iconPath,
                width: 28,
                height: 28,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.bodyStrong.copyWith(color: palette.ink),
                    ),
                    // A one-line hint: DESIGN.md `small`, so a tick row stays
                    // short enough to tap whole at 200 percent text.
                    Text(
                      subtitle,
                      style: AppText.small.copyWith(color: palette.inkSoft),
                    ),
                  ],
                ),
              ),
              if (isTicked)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Done',
                      style: AppText.label.copyWith(color: palette.ink),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isTicked ? palette.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTicked ? palette.accent : palette.outline,
                    width: 2,
                  ),
                ),
                child: isTicked
                    ? Icon(
                        Icons.check_rounded,
                        size: 22,
                        color: palette.accentText,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
