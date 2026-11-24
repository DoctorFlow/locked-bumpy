import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/paper.dart';
import '../../../domain/models/app_state.dart';
import '../../../domain/models/need.dart';
import '../../../domain/pregnancy.dart';
import '../../widgets/pause_button.dart';
import '../../widgets/paper_choice.dart';
import '../../widgets/pregnancy_date_picker.dart';
import '../../widgets/paper_portrait.dart';
import '../../widgets/bumpy_avatar.dart';
import '../../widgets/need_word.dart';
import '../../widgets/nursery_scene.dart';
import '../../widgets/skin_tone_picker.dart';
import '../../../domain/models/skin_tone.dart';

part 'step_welcome.dart';
part 'step_date.dart';
part 'step_nickname.dart';
part 'step_look.dart';
part 'step_costumes.dart';
part 'onboarding_buttons.dart';

/// First-run onboarding: five short steps shown as a horizontal page flow.
///
/// 1 Welcome: who Bumpy is, what the app holds, and that it stays private.
/// 2 Date (due date, weeks, or last period) with a live week preview.
///   Required.
/// 3 Optional baby nickname.
/// 4 Look (Halloween or Everyday) and skin tone.
/// 5 Six costumes, six everyday needs, shown the way the chosen look shows
///   them, then the parent enters the nursery.
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
  static const _stepCount = 5;

  final PageController _pages = PageController();
  // Sits under the look being tried, so the date picker opens in that look.
  final GlobalKey _themed = GlobalKey();
  int _step = 0;

  // ── Date state ───────────────────────────────────────────────────────────
  _DateWay _way = _DateWay.dueDate;
  DateTime? _dueDateChoice;
  DateTime? _periodStartChoice;
  int? _weekChoice;
  bool get _useDueDate => _way == _DateWay.dueDate;
  DateTime? get _pickedDate => switch (_way) {
    _DateWay.dueDate => _dueDateChoice,
    _DateWay.lastPeriod => _periodStartChoice,
    _DateWay.weeks => null,
  };

  /// The due date the chosen way leads to: the one value every way saves.
  /// A week becomes the due date that puts today on the first day of it.
  DateTime? get _dueDateToSave => switch (_way) {
    _DateWay.dueDate => _dueDateChoice,
    _DateWay.lastPeriod =>
      _periodStartChoice == null
          ? null
          : PregnancyCalculator.dueDateFromLmp(_periodStartChoice!),
    _DateWay.weeks =>
      _weekChoice == null
          ? null
          : PregnancyCalculator.dueDateForWeek(
              week: _weekChoice!,
              currentDate: widget.state.today,
            ),
  };

  /// Live gestational week from the chosen way; null until a choice.
  int? get _previewWeek {
    final dueDate = _dueDateToSave;
    if (dueDate == null) return null;
    return PregnancyCalculator.weekFromDueDate(
      dueDate: dueDate,
      currentDate: widget.state.today,
    );
  }

  // ── Nickname state ───────────────────────────────────────────────────────
  final TextEditingController _nicknameController = TextEditingController();

  // ── Look state ───────────────────────────────────────────────────────────
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

  void _back() {
    if (_step > 0 && !_saving) _goTo(_step - 1);
  }

  Future<void> _pickDate() async {
    widget.state.refreshDay();
    if (_way == _DateWay.weeks) {
      final week = await _pickWeek(
        _themed.currentContext ?? context,
        palette: _pickHalloween ? AppPalette.halloween : AppPalette.everyday,
        selected: _weekChoice,
        onPause: widget.state.pause,
      );
      if (week != null && mounted) setState(() => _weekChoice = week);
      return;
    }
    final picked = await pickPregnancyDate(
      _themed.currentContext ?? context,
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

  /// Choosing "I know how many weeks" with no week yet opens the week grid
  /// at once: the parent has just said they know it.
  void _chooseWay(_DateWay way) {
    final changed = way != _way;
    setState(() => _way = way);
    if (changed && way == _DateWay.weeks && _weekChoice == null) {
      _pickDate();
    }
  }

  Future<void> _confirm() async {
    final dueDate = _dueDateToSave;
    if (dueDate == null || _saving) return;
    setState(() => _saving = true);

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
    void toggleLook() => setState(() => _pickHalloween = !_pickHalloween);

    return PopScope(
      // System back walks back through the steps; on the welcome it leaves.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      // The look being tried is the theme too, so the chips, the nickname
      // field and the date picker match the page they sit on.
      child: Theme(
        data: buildTheme(palette),
        child: Scaffold(
          key: _themed,
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
                          const SizedBox(width: 48),
                          Expanded(
                            child: _StepIndicator(
                              step: _step,
                              count: _stepCount,
                              palette: palette,
                            ),
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
                            onPageChanged: (i) {
                              if (i != _step) setState(() => _step = i);
                            },
                            children: [
                              _StepWelcome(
                                palette: palette,
                                skinTone: _skinTone,
                                onSwitchLamp: toggleLook,
                                onStart: () => _goTo(1),
                              ),
                              _StepDate(
                                palette: palette,
                                way: _way,
                                pickedDate: _pickedDate,
                                pickedWeek: _weekChoice,
                                previewWeek: _previewWeek,
                                onWay: _chooseWay,
                                onPickDate: _pickDate,
                                onBack: _back,
                                onNext: _dueDateToSave != null
                                    ? () => _goTo(2)
                                    : null,
                              ),
                              _StepNickname(
                                palette: palette,
                                skinTone: _skinTone,
                                controller: _nicknameController,
                                onBack: _back,
                                onNext: () => _goTo(3),
                              ),
                              _StepLook(
                                palette: palette,
                                skinTone: _skinTone,
                                onTone: (tone) =>
                                    setState(() => _skinTone = tone),
                                isHalloween: _pickHalloween,
                                onToggle: (v) =>
                                    setState(() => _pickHalloween = v),
                                onBack: _back,
                                onNext: () => _goTo(4),
                              ),
                              _StepCostumes(
                                palette: palette,
                                skinTone: _skinTone,
                                saving: _saving,
                                onBack: _back,
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
        ),
      ),
    );
  }
}

// ── Progress: dots plus a plain "2 of 5" ─────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.count,
    required this.palette,
  });

  final int step;
  final int count;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Step ${step + 1} of $count',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpace.m,
        runSpacing: AppSpace.xs,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(count, (i) {
              final active = i == step;
              return AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= step
                      ? palette.accent
                      : palette.moonlightSoft.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          Text(
            '${step + 1} of $count',
            style: AppText.label.copyWith(color: palette.moonlightSoft),
          ),
        ],
      ),
    );
  }
}
