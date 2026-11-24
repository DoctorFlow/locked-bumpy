part of 'first_run_screen.dart';

// ── Step 1: Date input ────────────────────────────────────────────────────

class _WelcomeNursery extends StatefulWidget {
  const _WelcomeNursery({
    required this.palette,
    required this.skinTone,
    required this.onSwitchLamp,
  });
  final AppPalette palette;
  final SkinTone skinTone;
  final VoidCallback onSwitchLamp;

  @override
  State<_WelcomeNursery> createState() => _WelcomeNurseryState();
}

class _WelcomeNurseryState extends State<_WelcomeNursery> {
  bool _checked = false;
  late final _records = ContentLoader.load(ContentPaths.todayLines);

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Material(
      color: palette.paper,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: NurseryScene(
              palette: palette,
              avatar: BumpyAvatar(
                need: MaternalNeed.iron,
                palette: palette,
                happy: _checked,
                skinTone: widget.skinTone,
              ),
              cornerAction: FilledButton.tonalIcon(
                onPressed: widget.onSwitchLamp,
                icon: Image.asset(
                  'assets/images/nursery-lamp.png',
                  width: 18,
                  height: 18,
                  color: palette.ink,
                  excludeFromSemantics: true,
                ),
                label: Text(
                  palette.isHalloween ? 'Try daylight' : 'Try moonlight',
                ),
                style: FilledButton.styleFrom(
                  foregroundColor: palette.ink,
                  backgroundColor: palette.paper,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ),
          FutureBuilder(
            future: _records,
            builder: (context, snapshot) {
              final line = ContentLoader.find(
                records: snapshot.data ?? [],
                need: MaternalNeed.iron.needName,
                category: 'thank_you',
                mode: palette.isHalloween ? 'halloween' : 'everyday',
              )?.text;
              final label = _checked
                  ? line ?? 'Check-in preview complete'
                  : 'Try a sample check-in';
              return PaperChoice(
                liveRegion: _checked,
                label: _checked
                    ? '$label. Sample only, nothing saved. Reset preview'
                    : 'Try a sample check-in',
                onTap: _toggle,
                focusColor: palette.ink,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        MaternalNeed.iron.iconPath,
                        width: 30,
                        height: 30,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_checked)
                              Text(
                                'Sample only · nothing saved',
                                style: TextStyle(
                                  color: palette.inkSoft,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        _checked ? Icons.replay : Icons.touch_app_outlined,
                        size: 21,
                        color: palette.inkSoft,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggle() => setState(() => _checked = !_checked);
}

class _Step1Date extends StatelessWidget {
  const _Step1Date({
    required this.palette,
    required this.skinTone,
    required this.useDueDate,
    required this.pickedDate,
    required this.previewWeek,
    required this.onToggleMode,
    required this.onPickDate,
    required this.onEnter,
    required this.onSwitchLamp,
    required this.onNext,
  });

  final AppPalette palette;
  final bool useDueDate;
  final SkinTone skinTone;
  final DateTime? pickedDate;
  final int? previewWeek;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onPickDate;
  final VoidCallback onSwitchLamp;
  final VoidCallback? onEnter;
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
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hello, Little Bumpy.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: palette.moonlight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'A little check-in with your baby each day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.moonlightSoft, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _WelcomeNursery(
            palette: palette,
            skinTone: skinTone,
            onSwitchLamp: onSwitchLamp,
          ),
          const SizedBox(height: 22),
          Text(
            'Your date picks the weekly cards. It stays on this device.',
            style: TextStyle(fontSize: 15, color: palette.moonlightSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                        fontSize: 16,
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

          const SizedBox(height: 20),
          if (pickedDate != null)
            _PrimaryButton(
              label: 'Enter the nursery',
              palette: palette,
              onPressed: onEnter,
            ),
          if (onNext != null)
            TextButton(
              onPressed: onNext,
              style: TextButton.styleFrom(foregroundColor: palette.moonlight),
              child: const Text('Choose name and appearance first'),
            ),
          const SizedBox(height: 20),

          // Disclaimer
          Text(
            AppConstants.disclaimer,
            style: TextStyle(
              fontSize: 11,
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
                  fontSize: 14,
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
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
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
