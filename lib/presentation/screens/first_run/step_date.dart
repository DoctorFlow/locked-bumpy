part of 'first_run_screen.dart';

// ── Step 2: Date input ────────────────────────────────────────────────────

/// The three ways in to the date step. Each one ends in the same stored
/// value: a due date.
enum _DateWay { dueDate, weeks, lastPeriod }

class _StepDate extends StatelessWidget {
  const _StepDate({
    required this.palette,
    required this.way,
    required this.pickedDate,
    required this.pickedWeek,
    required this.previewWeek,
    required this.dueDate,
    required this.onWay,
    required this.onPickDate,
    required this.onBack,
    required this.onNext,
  });

  final AppPalette palette;
  final _DateWay way;
  final DateTime? pickedDate;
  final int? pickedWeek;
  final int? previewWeek;

  /// The due date every way leads to; null until a choice.
  final DateTime? dueDate;
  final ValueChanged<_DateWay> onWay;

  /// Opens the picker for the chosen way: the calendar, or the week grid.
  final VoidCallback onPickDate;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  static const _wayLabels = {
    _DateWay.dueDate: 'I know my due date',
    _DateWay.weeks: 'I know how many weeks',
    _DateWay.lastPeriod: 'I know when my last period started',
  };

  @override
  Widget build(BuildContext context) {
    final String action;
    final String valueText;
    final bool empty;
    final IconData icon;
    switch (way) {
      case _DateWay.weeks:
        action = 'Pick your week';
        empty = pickedWeek == null;
        valueText = empty ? 'Choose your week' : 'Week $pickedWeek';
        icon = Icons.calendar_view_week_rounded;
      case _DateWay.dueDate:
      case _DateWay.lastPeriod:
        final due = way == _DateWay.dueDate;
        action = due ? 'Pick your due date' : 'Pick your last period start';
        empty = pickedDate == null;
        valueText = empty
            ? (due ? 'Choose due date' : 'Choose period start date')
            : _fmt(pickedDate!);
        icon = Icons.calendar_today;
    }
    return SingleChildScrollView(
      padding: _stepPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeading(
            title: 'When am I due?',
            subtitle:
                'Your date opens the right chapter each week. '
                'It stays on this device.',
            palette: palette,
          ),
          const SizedBox(height: AppSpace.xl),
          _WayChoice(
            palette: palette,
            options: [for (final w in _DateWay.values) _wayLabels[w]!],
            selectedIndex: way.index,
            onSelect: (i) => onWay(_DateWay.values[i]),
          ),
          const SizedBox(height: AppSpace.l),

          // The date or week itself: a paper piece. Before a choice it is the
          // accent piece that asks to be tapped; after, plain paper with the
          // value.
          PaperChoice(
            key: const ValueKey('date-step-value'),
            label: '$action\n$valueText',
            onTap: onPickDate,
            focusColor: empty ? palette.accentText : palette.ink,
            borderRadius: AppRadii.control,
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSpace.row),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.l,
                vertical: AppSpace.m,
              ),
              decoration: BoxDecoration(
                color: empty ? palette.accent : palette.paper,
                borderRadius: AppRadii.control,
                border: Border.all(
                  color: empty ? palette.accent : palette.edge,
                ),
                boxShadow: paperShadows(palette, raised: true),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: empty ? palette.accentText : palette.accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Text(
                      valueText,
                      style: AppText.bodyStrong.copyWith(
                        color: empty ? palette.accentText : palette.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Live week preview ──────────────────────────────────────────
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            child: previewWeek == null || dueDate == null
                ? const SizedBox.shrink(key: ValueKey('empty'))
                : _WeekPreview(
                    key: ValueKey((previewWeek, dueDate)),
                    week: previewWeek!,
                    dueDate: dueDate!,
                    palette: palette,
                  ),
          ),

          const SizedBox(height: AppSpace.xl),
          _StepButtons(
            palette: palette,
            onBack: onBack,
            primaryLabel: 'Next',
            onPrimary: onNext,
          ),
          const SizedBox(height: AppSpace.xl),

          // The safety line: `small`, like every footer safety line.
          Text(
            AppConstants.disclaimer,
            style: AppText.small.copyWith(color: palette.moonlightSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) => dayMonthYear(d);
}

// ── The week grid (the "I know how many weeks" way) ──────────────────────

/// Weeks 4 to 42 as one grid of paper tiles in a sheet: one tap picks a
/// week. Every tile is at least 56 x 48 and grows with the text; the grid
/// wraps to the width and scrolls, so it holds at 320 px and 200% text.
Future<int?> _pickWeek(
  BuildContext context, {
  required AppPalette palette,
  required int? selected,
  required VoidCallback onPause,
}) {
  final selectedKey = GlobalKey();
  var positioned = false;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: palette.paper,
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : null,
    constraints: const BoxConstraints(maxWidth: 440),
    builder: (sheet) {
      if (!positioned && selected != null) {
        positioned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final anchor = selectedKey.currentContext;
          if (anchor != null) {
            Scrollable.ensureVisible(anchor, alignment: .45);
          }
        });
      }
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * .8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.s,
                  AppSpace.s,
                  AppSpace.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Pick your week',
                          style: AppText.title.copyWith(color: palette.ink),
                        ),
                      ),
                    ),
                    PauseButton(onPressed: onPause, color: palette.ink),
                    IconButton(
                      onPressed: () => Navigator.pop(sheet),
                      tooltip: 'Close',
                      icon: Icon(Icons.close, color: palette.ink),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.l,
                    AppSpace.xs,
                    AppSpace.l,
                    AppSpace.l,
                  ),
                  child: Wrap(
                    key: const ValueKey('week-grid'),
                    spacing: AppSpace.s,
                    runSpacing: AppSpace.s,
                    alignment: WrapAlignment.center,
                    children: [
                      for (var n = 4; n <= 42; n++)
                        _WeekTile(
                          key: n == selected ? selectedKey : null,
                          week: n,
                          selected: n == selected,
                          palette: palette,
                          onTap: () => Navigator.pop(sheet, n),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _WeekTile extends StatelessWidget {
  const _WeekTile({
    super.key,
    required this.week,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final int week;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Week $week',
      selected: selected,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      // A week tile is a paper piece, not a link: no underline. Selected =
      // accent fill plus a tick.
      child: FilledButton.tonal(
        key: ValueKey('week-tile-$week'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(56, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.m),
          foregroundColor: selected ? palette.accentText : palette.ink,
          backgroundColor: selected ? palette.accent : palette.paperRaised,
          side: BorderSide(color: selected ? palette.accent : palette.outline),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 16),
              const SizedBox(width: AppSpace.xs),
            ],
            Text('$week'),
          ],
        ),
      ),
    );
  }
}

// ── What the app now holds ────────────────────────────────────────────────

/// After any way in, the step says back plainly what the app will keep:
/// "Week 9. Due around 15 March." Read aloud when it appears or changes.
class _WeekPreview extends StatefulWidget {
  const _WeekPreview({
    super.key,
    required this.week,
    required this.dueDate,
    required this.palette,
  });

  final int week;
  final DateTime dueDate;
  final AppPalette palette;

  static String sentence(int week, DateTime dueDate) =>
      'Week $week. Due around ${dayMonthYear(dueDate, withYear: false)}.';

  @override
  State<_WeekPreview> createState() => _WeekPreviewState();
}

class _WeekPreviewState extends State<_WeekPreview> {
  @override
  void initState() {
    super.initState();
    // A new choice brings the line into view if it landed below the fold
    // (320 px wide, large text), so it is seen before Next.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only the step's own scroll view: never the page flow around it.
      final box = context.findRenderObject();
      final position = Scrollable.maybeOf(context)?.position;
      if (box == null || position == null) return;
      position.ensureVisible(
        box,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.l),
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Container(
          key: const ValueKey('date-step-say-back'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.l,
            vertical: AppSpace.m,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.control,
            border: Border.all(color: palette.outline, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Moonlight, not accent: accent on the page is too faint.
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.child_friendly,
                    color: palette.moonlight,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _WeekPreview.sentence(widget.week, widget.dueDate),
                      style: AppText.bodyStrong.copyWith(
                        color: palette.moonlight,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'You can change this later in Settings.',
                      style: AppText.small.copyWith(
                        color: palette.moonlightSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── The three ways in, one under the other ────────────────────────────────

/// One row per way, full width, so the longer labels fit at 320 px and grow
/// with the text. Selected = accent fill plus a tick, never colour alone.
class _WayChoice extends StatelessWidget {
  const _WayChoice({
    required this.palette,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  final AppPalette palette;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        borderRadius: AppRadii.control,
        border: Border.all(color: palette.outline, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(options.length, (i) {
          final active = i == selectedIndex;
          final ink = active ? palette.accentText : palette.moonlight;
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.xs),
            child: PaperChoice(
              label: options[i],
              selected: active,
              onTap: () => onSelect(i),
              focusColor: active ? palette.accentText : palette.moonlight,
              borderRadius: AppRadii.tag,
              child: Container(
                constraints: const BoxConstraints(minHeight: AppSpace.target),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpace.s,
                  horizontal: AppSpace.m,
                ),
                decoration: BoxDecoration(
                  color: active ? palette.accent : Colors.transparent,
                  borderRadius: AppRadii.tag,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: active
                          ? Icon(Icons.check_rounded, size: 18, color: ink)
                          : null,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        options[i],
                        style: AppText.bodyStrong.copyWith(color: ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
