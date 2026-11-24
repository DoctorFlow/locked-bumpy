part of 'today_screen.dart';

// ── Check-ins panel: the three rows, the saved summary and save status ─────

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (allDone && !reviewing)
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
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: palette.moonlight,
              ),
            ),
          ),
        if (state.completedCheckIns.isEmpty || (allDone && reviewing)) ...[
          const SizedBox(height: 3),
          Text(
            allDone
                ? 'Tap a checked row to undo it.'
                : 'Tap a row when you’ve done it.',
            style: TextStyle(color: palette.moonlightSoft, fontSize: 14),
          ),
        ],
        const SizedBox(height: 10),
        if (!allDone || reviewing)
          Material(
            color: palette.paperRaised,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final item in checkIns) ...[
                  if (item != checkIns.first)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: palette.inkSoft.withValues(alpha: .22),
                    ),
                  _CheckInTile(
                    key: ValueKey(item),
                    title: item == need
                        ? '${need.needName} · Need of the Day'
                        : item.label,
                    subtitle: item.foodHint,
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
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Text(
                    state.checkInStatus == CheckInSaveStatus.saving
                        ? 'Saving check-ins…'
                        : 'Your check-ins couldn’t be saved on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.moonlight),
                  ),
                  if (state.checkInStatus == CheckInSaveStatus.failed)
                    TextButton(
                      onPressed: state.retryCheckIns,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: palette.moonlight,
                      ),
                      child: const Text('Retry save'),
                    ),
                ],
              ),
            ),
          ),
        if (allDone && reviewing)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: palette.moonlight),
            onPressed: onEndReview,
            child: const Text('Back to summary'),
          ),
        const SizedBox(height: 8),
        Text(
          state.daysTogetherCount == 1
              ? '1 day together'
              : '${state.daysTogetherCount} days together',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.moonlightSoft, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Text(
          AppConstants.disclaimer,
          style: TextStyle(
            fontSize: 11,
            color: palette.moonlightSoft,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
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
    return Material(
      color: palette.paperRaised,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              children: [
                for (final need in needs)
                  Image.asset(
                    need.iconPath,
                    height: 26,
                    width: 26,
                    excludeFromSemantics: true,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                'Today’s check-ins are saved',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              needs.map((need) => need.label).join(' · '),
              style: TextStyle(color: palette.inkSoft, fontSize: 14),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: palette.ink,
                side: BorderSide(color: palette.inkSoft),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: onWeek,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text(
                'Open this week’s card',
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: palette.ink),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Image.asset(
                need.iconPath,
                width: 32,
                height: 32,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: palette.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: palette.inkSoft),
                    ),
                  ],
                ),
              ),
              if (isTicked)
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Done',
                      style: TextStyle(fontSize: 12, color: palette.ink),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isTicked ? palette.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTicked ? palette.accent : palette.inkSoft,
                    width: 2,
                  ),
                ),
                child: isTicked
                    ? Icon(
                        Icons.check_rounded,
                        size: 18,
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
