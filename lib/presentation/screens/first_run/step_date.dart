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
          const SizedBox(height: 20),
          // Due Date / Last Period toggle
          _SegmentToggle(
            palette: palette,
            options: const ['Due Date', 'Last Period'],
            selectedIndex: useDueDate ? 0 : 1,
            onSelect: (i) => onToggleMode(i == 0),
          ),
          const SizedBox(height: 16),

          // Date picker card
          PaperChoice(
            label: '$dateAction\n$dateText',
            onTap: onPickDate,
            focusColor: pickedDate == null ? palette.accentText : palette.ink,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: pickedDate == null ? palette.accent : palette.paper,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: pickedDate == null
                        ? palette.accentText
                        : palette.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: pickedDate == null
                            ? palette.accentText
                            : palette.ink,
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

          const SizedBox(height: 24),
          _StepButtons(
            palette: palette,
            onBack: onBack,
            primaryLabel: 'Next',
            onPrimary: onNext,
          ),
          const SizedBox(height: 24),

          // Disclaimer
          Text(
            AppConstants.disclaimer,
            style: TextStyle(
              fontSize: 16,
              color: palette.moonlightSoft,
              height: 1.4,
            ),
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

// ── Week preview chip ─────────────────────────────────────────────────────

class _WeekPreview extends StatelessWidget {
  const _WeekPreview({super.key, required this.week, required this.palette});

  final int week;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.child_friendly, color: palette.accent, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'You are at week $week right now.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.moonlight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment toggle (Due Date / Last Period) ───────────────────────────────

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
      decoration: BoxDecoration(
        color: palette.paperRaised.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.moonlight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final active = i == selectedIndex;
          return Expanded(
            child: PaperChoice(
              label: options[i],
              selected: active,
              onTap: () => onSelect(i),
              focusColor: active ? palette.accentText : palette.moonlight,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  color: active ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: active ? palette.accentText : palette.moonlightSoft,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
