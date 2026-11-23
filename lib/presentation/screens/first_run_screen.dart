import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../../domain/pregnancy.dart';
import '../widgets/pregnancy_date_picker.dart';
import '../widgets/paper_portrait.dart';
import '../widgets/skin_tone_picker.dart';
import '../../domain/models/skin_tone.dart';

/// First-run onboarding: 3 steps shown as a horizontal page flow.
///
/// Step 1 — Date (Due Date or LMP) with live gestational week preview.
/// Step 2 — Optional baby nickname.
/// Step 3 — Look selector (Halloween-first vs Everyday) + confirm.
///
/// All data is persisted locally via [AppState] / [PrefsService].
/// No network calls. No accounts.
class FirstRunScreen extends StatefulWidget {
  const FirstRunScreen({super.key, required this.state});

  final AppState state;

  @override
  State<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends State<FirstRunScreen> {
  final PageController _pages = PageController();
  int _step = 0; // 0, 1, 2

  // ── Step 1 state ─────────────────────────────────────────────────────────
  bool _useDueDate = true;
  DateTime? _pickedDate;

  /// Live gestational week computed from picked date; null until date chosen.
  int? get _previewWeek {
    if (_pickedDate == null) return null;
    final dueDate = _useDueDate
        ? _pickedDate!
        : PregnancyCalculator.dueDateFromLmp(_pickedDate!);
    return PregnancyCalculator.weekFromDueDate(
      dueDate: dueDate,
      currentDate: widget.state.today,
    );
  }

  // ── Step 2 state ─────────────────────────────────────────────────────────
  final TextEditingController _nicknameController = TextEditingController();

  // ── Step 3 state ─────────────────────────────────────────────────────────
  /// Tracks the look choice locally during onboarding before final save.
  late bool _pickHalloween;
  late SkinTone _skinTone;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pickHalloween = widget.state.isHalloween;
    _skinTone = widget.state.skinTone;
  }

  @override
  void dispose() {
    _pages.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(step);
    } else {
      _pages.animateToPage(
        step,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickDate() async {
    widget.state.refreshDay();
    final picked = await pickPregnancyDate(
      context,
      today: widget.state.today,
      useDueDate: _useDueDate,
      selected: _pickedDate,
    );
    if (picked != null && mounted) setState(() => _pickedDate = picked);
  }

  Future<void> _confirm() async {
    if (_pickedDate == null || _saving) return;
    setState(() => _saving = true);

    final dueDate = _useDueDate
        ? _pickedDate!
        : PregnancyCalculator.dueDateFromLmp(_pickedDate!);

    final nickname = _nicknameController.text.trim();

    // Persist look choice if it changed during onboarding.
    if (_pickHalloween != widget.state.isHalloween) {
      await widget.state.toggleMode();
    }
    await widget.state.saveSkinTone(_skinTone);
    await widget.state.saveNickname(nickname);
    await widget.state.saveDueDate(dueDate);
    // isFirstRun flips to false → parent rebuilds to main shell.
  }

  @override
  Widget build(BuildContext context) {
    final palette = _pickHalloween ? AppPalette.halloween : AppPalette.everyday;

    return Theme(
      data: Theme.of(context).copyWith(extensions: [palette]),
      child: Scaffold(
        backgroundColor: palette.skyBottom,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.skyTop, palette.skyBottom],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _StepIndicator(step: _step, palette: palette),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _Step1Date(
                            palette: palette,
                            skinTone: _skinTone,
                            useDueDate: _useDueDate,
                            pickedDate: _pickedDate,
                            previewWeek: _previewWeek,
                            onToggleMode: (v) => setState(() {
                              _useDueDate = v;
                              _pickedDate = null;
                            }),
                            onPickDate: _pickDate,
                            onNext: _pickedDate != null ? () => _goTo(1) : null,
                          ),
                          _Step2Nickname(
                            palette: palette,
                            controller: _nicknameController,
                            onBack: () => _goTo(0),
                            onNext: () => _goTo(2),
                          ),
                          _Step3Look(
                            palette: palette,
                            skinTone: _skinTone,
                            onTone: (tone) => setState(() => _skinTone = tone),
                            isHalloween: _pickHalloween,
                            saving: _saving,
                            onToggle: (v) => setState(() => _pickHalloween = v),
                            onBack: () => _goTo(1),
                            onConfirm: _confirm,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step indicator dots ───────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.palette});

  final int step;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final active = i == step;
          return AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active
                  ? palette.accent
                  : palette.moonlightSoft.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Date input ────────────────────────────────────────────────────

class _Step1Date extends StatelessWidget {
  const _Step1Date({
    required this.palette,
    required this.skinTone,
    required this.useDueDate,
    required this.pickedDate,
    required this.previewWeek,
    required this.onToggleMode,
    required this.onPickDate,
    required this.onNext,
  });

  final AppPalette palette;
  final bool useDueDate;
  final SkinTone skinTone;
  final DateTime? pickedDate;
  final int? previewWeek;
  final ValueChanged<bool> onToggleMode;
  final VoidCallback onPickDate;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image(
              image: paperPortrait(
                MaternalNeed.iron.assetPath(AppPalette.everyday),
                skinTone,
              ),
              width: 112,
              height: 112,
              semanticLabel: 'Little Bumpy in a lavender onesie',
            ),
          ),
          const SizedBox(height: 20),

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
          const SizedBox(height: 8),
          Text(
            'Tell me when to expect you.',
            style: TextStyle(fontSize: 15, color: palette.moonlightSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Due Date / Last Period toggle
          _SegmentToggle(
            palette: palette,
            options: const ['Due Date', 'Last Period'],
            selectedIndex: useDueDate ? 0 : 1,
            onSelect: (i) => onToggleMode(i == 0),
          ),
          const SizedBox(height: 16),

          // Date picker card
          Semantics(
            label: useDueDate
                ? 'Pick your due date'
                : 'Pick your last period start',
            button: true,
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: palette.paper,
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
                    Icon(Icons.calendar_today, color: palette.accent, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        pickedDate == null
                            ? 'Tap to pick a date'
                            : _fmt(pickedDate!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: pickedDate == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: pickedDate == null
                              ? palette.inkSoft
                              : palette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Live week preview ──────────────────────────────────────────
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 250),
            child: previewWeek == null
                ? const SizedBox(height: 56, key: ValueKey('empty'))
                : _WeekPreview(
                    key: ValueKey(previewWeek),
                    week: previewWeek!,
                    palette: palette,
                  ),
          ),

          const SizedBox(height: 20),
          _PrimaryButton(label: 'Next', palette: palette, onPressed: onNext),
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

// ── Step 2: Optional nickname ─────────────────────────────────────────────

class _Step2Nickname extends StatelessWidget {
  const _Step2Nickname({
    required this.palette,
    required this.controller,
    required this.onBack,
    required this.onNext,
  });

  final AppPalette palette;
  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Give the baby a nickname?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.moonlight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Optional — skip if you prefer Little Bumpy.',
            style: TextStyle(fontSize: 14, color: palette.moonlightSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          TextField(
            controller: controller,
            maxLength: 24,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(fontSize: 18, color: palette.ink),
            decoration: InputDecoration(
              hintText: 'e.g. Peanut, Sprout…',
              hintStyle: TextStyle(color: palette.inkSoft),
              filled: true,
              fillColor: palette.paper,
              counterStyle: TextStyle(
                color: palette.moonlightSoft,
                fontSize: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Back',
                  palette: palette,
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryButton(
                  label: 'Next',
                  palette: palette,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Look selector ─────────────────────────────────────────────────

class _Step3Look extends StatelessWidget {
  const _Step3Look({
    required this.palette,
    required this.skinTone,
    required this.onTone,
    required this.isHalloween,
    required this.saving,
    required this.onToggle,
    required this.onBack,
    required this.onConfirm,
  });

  final AppPalette palette;
  final bool isHalloween;
  final bool saving;
  final SkinTone skinTone;
  final ValueChanged<SkinTone> onTone;
  final ValueChanged<bool> onToggle;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick a look.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.moonlight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You can switch any time with the lamp.',
            style: TextStyle(fontSize: 14, color: palette.moonlightSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
              final width = largeText
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final look in [
                    AppPalette.halloween,
                    AppPalette.everyday,
                  ])
                    SizedBox(
                      width: width,
                      child: _LookCard(
                        label: look.isHalloween ? 'Halloween' : 'Everyday',
                        description: look.isHalloween
                            ? 'Midnight plum, pumpkin moon'
                            : 'Warm cream, storybook',
                        selected: look.isHalloween == isHalloween,
                        look: look,
                        skinTone: skinTone,
                        onTap: () => onToggle(look.isHalloween),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SkinTonePicker(
            selected: skinTone,
            onSelected: onTone,
            foreground: palette.moonlight,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Back',
                  palette: palette,
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PrimaryButton(
                  label: "Let's go",
                  palette: palette,
                  onPressed: saving ? null : onConfirm,
                  loading: saving,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
}

class _LookCard extends StatelessWidget {
  const _LookCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.look,
    required this.skinTone,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final AppPalette look;
  final SkinTone skinTone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label. $description',
      excludeSemantics: true,
      onTap: onTap,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: look.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? look.accent : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.3 : 0.15),
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image(
                  image: paperPortrait(
                    MaternalNeed.iron.assetPath(look),
                    skinTone,
                  ),
                  width: 96,
                  height: 96,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: look.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: look.inkSoft,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              if (selected)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: look.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 13, color: look.accentText),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: look.ink.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared button widgets ─────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.palette,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final AppPalette palette;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.accentText,
        disabledBackgroundColor: palette.accent.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final AppPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.moonlightSoft,
        side: BorderSide(color: palette.moonlightSoft.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
            child: GestureDetector(
              onTap: () => onSelect(i),
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
