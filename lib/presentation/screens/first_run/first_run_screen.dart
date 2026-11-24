import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../content/content_loader.dart';
import '../../../content/content_paths.dart';
import '../../../core/theme/palette.dart';
import '../../../domain/models/app_state.dart';
import '../../../domain/models/need.dart';
import '../../../domain/pregnancy.dart';
import '../../widgets/pause_button.dart';
import '../../widgets/paper_choice.dart';
import '../../widgets/pregnancy_date_picker.dart';
import '../../widgets/paper_portrait.dart';
import '../../widgets/bumpy_avatar.dart';
import '../../widgets/nursery_scene.dart';
import '../../widgets/skin_tone_picker.dart';
import '../../../domain/models/skin_tone.dart';

part 'step_date.dart';
part 'step_nickname.dart';
part 'step_look.dart';
part 'onboarding_buttons.dart';

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
  DateTime? _dueDateChoice;
  DateTime? _periodStartChoice;
  DateTime? get _pickedDate =>
      _useDueDate ? _dueDateChoice : _periodStartChoice;

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
      onPause: widget.state.pause,
      selected: _pickedDate,
    );
    if (picked != null && mounted) {
      setState(() {
        if (_useDueDate) {
          _dueDateChoice = picked;
        } else {
          _periodStartChoice = picked;
        }
      });
    }
  }

  Future<void> _confirm() async {
    if (_pickedDate == null || _saving) return;
    setState(() => _saving = true);

    final dueDate = _useDueDate
        ? _pickedDate!
        : PregnancyCalculator.dueDateFromLmp(_pickedDate!);

    final saved = await widget.state.finishSetup(
      date: dueDate,
      halloween: _pickHalloween,
      tone: _skinTone,
      nickname: _nicknameController.text,
    );
    if (!mounted || saved || widget.state.isPaused) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Couldn’t save your setup on this device.'),
        action: SnackBarAction(label: 'Retry', onPressed: _confirm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _pickHalloween ? AppPalette.halloween : AppPalette.everyday;

    return Scaffold(
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
                  Row(
                    children: [
                      Expanded(
                        child: _step > 0
                            ? _StepIndicator(step: _step - 1, palette: palette)
                            : const SizedBox.shrink(),
                      ),
                      PauseButton(
                        onPressed: widget.state.pause,
                        color: palette.moonlight,
                      ),
                    ],
                  ),
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: _saving,
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
                            onToggleMode: (v) =>
                                setState(() => _useDueDate = v),
                            onPickDate: _pickDate,
                            onSwitchLamp: () => setState(
                              () => _pickHalloween = !_pickHalloween,
                            ),
                            onEnter: _pickedDate != null && !_saving
                                ? _confirm
                                : null,
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
                  ),
                ],
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
        children: List.generate(2, (i) {
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
