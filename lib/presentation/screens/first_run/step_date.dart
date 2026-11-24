part of 'first_run_screen.dart';

// ── Step 2: Date input ────────────────────────────────────────────────────

class _StepDate extends StatelessWidget {
  const _StepDate({
    required this.palette,
    required this.useDueDate,
    required this.pickedDate,
    required this.previewWeek,
    required this.onToggleMode,
    required this.onPickDate,
    required this.onBack,
    required this.onNext,
  });

  final AppPalette palette;
  final bool useDueDate;
  final DateTime? pickedDate;
  final int? previewWeek;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onPickDate;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final dateAction = useDueDate
        ? 'Pick your due date'
        : 'Pick your last period start';
    final dateText = pickedDate == null
        ? (useDueDate ? 'Choose due date' : 'Choose period start date')
        : _fmt(pickedDate!);
    final empty = pickedDate == null;
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
          _SegmentToggle(
            palette: palette,
            options: const ['Due date', 'Last period'],
            selectedIndex: useDueDate ? 0 : 1,
            onSelect: (i) => onToggleMode(i == 0),
          ),
          const SizedBox(height: AppSpace.l),

          // The date itself: a paper piece. Before a choice it is the accent
          // piece that asks to be tapped; after, plain paper with the date.
          PaperChoice(
            label: '$dateAction\n$dateText',
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
                    Icons.calendar_today,
                    color: empty ? palette.accentText : palette.accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Text(
                      dateText,
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
            child: previewWeek == null
                ? const SizedBox.shrink(key: ValueKey('empty'))
                : _WeekPreview(
                    key: ValueKey(previewWeek),
                    week: previewWeek!,
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

  static String _fmt(DateTime d) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month]} ${d.day}, ${d.year}';
  }
}

// ── Week preview ──────────────────────────────────────────────────────────

class _WeekPreview extends StatelessWidget {
  const _WeekPreview({super.key, required this.week, required this.palette});

  final int week;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.l),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.l,
          vertical: AppSpace.m,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadii.control,
          border: Border.all(color: palette.outline, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Moonlight, not accent: accent on the page is too faint.
            Icon(Icons.child_friendly, color: palette.moonlight, size: 20),
            const SizedBox(width: AppSpace.s),
            Flexible(
              child: Text(
                'You are at week $week right now.',
                style: AppText.bodyStrong.copyWith(color: palette.moonlight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment toggle (Due date / Last period) ───────────────────────────────

class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({
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
      child: Row(
        children: List.generate(options.length, (i) {
          final active = i == selectedIndex;
          final ink = active ? palette.accentText : palette.moonlight;
          return Expanded(
            child: PaperChoice(
              label: options[i],
              selected: active,
              onTap: () => onSelect(i),
              focusColor: active ? palette.accentText : palette.moonlight,
              borderRadius: AppRadii.tag,
              child: Container(
                constraints: const BoxConstraints(minHeight: AppSpace.target),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpace.s,
                  horizontal: AppSpace.s,
                ),
                decoration: BoxDecoration(
                  color: active ? palette.accent : Colors.transparent,
                  borderRadius: AppRadii.tag,
                ),
                // Selected is the accent fill plus a tick, never colour alone.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (active) ...[
                      Icon(Icons.check_rounded, size: 18, color: ink),
                      const SizedBox(width: AppSpace.xs),
                    ],
                    Flexible(
                      child: Text(
                        options[i],
                        textAlign: TextAlign.center,
                        style: AppText.small.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
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
