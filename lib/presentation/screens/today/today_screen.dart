import 'package:flutter/material.dart';
import '../../../content/content_loader.dart';
import '../../../content/content_paths.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/palette.dart';
import '../../../domain/models/app_state.dart';
import '../../../domain/models/content_record.dart';
import '../../../domain/models/guide.dart';
import '../../../domain/models/need.dart';
import '../../sheets/closet_sheet.dart';
import '../../widgets/bumpy_avatar.dart';
import '../../widgets/draft_tag.dart';
import '../../widgets/nursery_scene.dart';
import '../../widgets/visit_topics.dart';
import '../guide_screen.dart';
import '../visit_screen.dart';

part 'today_style.dart';
part 'nursery_card.dart';
part 'fact_card.dart';
part 'check_in_list.dart';
part 'visit_card.dart';

/// Today tab: a one-minute daily visit.
///
/// In one glance: who Bumpy is today and why (the costume is the need), one
/// small sourced fact from that need's guide, and what waits for the visit.
/// The three check-ins sit below as optional ticks.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.state});

  final AppState state;

  /// The safety line under the check-ins. Says "doctor or midwife".
  static const disclaimer =
      'This app is not medical advice. '
      'If you are worried about anything, call your doctor or midwife.';

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _hopController;
  late Animation<double> _hopAnimation;

  /// Cached today-lines once loaded.
  List<ContentRecord>? _records;

  /// Guides the gate lets through; a missing need has no fact on Today.
  Map<MaternalNeed, Guide> _guides = const {};

  bool _hopping = false;
  DateTime? _reviewingDay;
  bool _savingTopic = false;
  MaternalNeed? _failedTopic;
  bool _addingQuestion = false;
  String? _failedQuestion;

  Future<void> _saveForVisit(MaternalNeed need) async {
    if (_savingTopic) return;
    setState(() {
      _savingTopic = true;
      _failedTopic = null;
    });
    try {
      await widget.state.saveVisitTopics({...widget.state.visitTopics, need});
    } catch (_) {
      if (mounted) setState(() => _failedTopic = need);
    } finally {
      if (mounted) setState(() => _savingTopic = false);
    }
  }

  Future<void> _addQuestion(String text, MaternalNeed need) async {
    if (_addingQuestion) return;
    setState(() {
      _addingQuestion = true;
      _failedQuestion = null;
    });
    var saved = false;
    try {
      saved = await widget.state.addVisitQuestion(text, need: need);
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _addingQuestion = false;
      if (!saved) _failedQuestion = text;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hopAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -18,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -18,
          end: 0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 50,
      ),
    ]).animate(_hopController);

    _loadRecords();
    _loadGuides();
  }

  Future<void> _loadRecords() async {
    final records = await ContentLoader.load(ContentPaths.todayLines);
    if (mounted) setState(() => _records = records);
  }

  Future<void> _loadGuides() async {
    final guides = await ContentLoader.loadGuides();
    if (mounted) setState(() => _guides = guides);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _hopController.dispose();
    super.dispose();
  }

  Future<void> _onCheckIn(String id) async {
    final wasChecked = widget.state.isChecked(id);
    await widget.state.toggleCheckIn(id);
    if (mounted) setState(() {});

    if (mounted &&
        id == widget.state.todayNeed.name &&
        widget.state.isChecked(id) &&
        !wasChecked &&
        !_hopping &&
        !MediaQuery.disableAnimationsOf(context)) {
      _hopping = true;
      await _hopController.forward(from: 0);
      _hopping = false;
    }
  }

  // ── Line and fact resolution ──────────────────────────────────────────────

  ContentRecord? _babyLine(
    MaternalNeed need,
    bool needTicked,
    bool allDone,
    AppPalette palette,
  ) {
    final records = _records;
    if (records == null) return null;
    return ContentLoader.find(
      records: records,
      need: allDone ? 'ALL' : need.needName,
      category: allDone
          ? 'goodbye'
          : needTicked
          ? 'thank_you'
          : 'greeting',
      mode:
          palette.isHalloween && (widget.state.costumeOverride ?? need) == need
          ? 'halloween'
          : 'everyday',
    );
  }

  /// The same day count the need rotation uses (day 0 = its epoch).
  static int _dayNumber(DateTime day) {
    final epoch = AppConstants.rotationEpoch;
    return DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(epoch.year, epoch.month, epoch.day)).inDays;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = widget.state;
    final need = state.todayNeed;
    final needTicked = state.isChecked(need.name);
    final allDone =
        state.allChecked && state.checkInStatus == CheckInSaveStatus.saved;
    final checkIns = state.dailyCheckIns;
    final reviewing = DateUtils.isSameDay(_reviewingDay, state.today);
    final line = _babyLine(need, needTicked, allDone, palette);
    final savedForVisit = state.visitTopics.contains(need);
    final guide = _guides[need];
    final hasFact = guide != null && guide.facts.isNotEmpty;

    return LayoutBuilder(
      builder: (context, bounds) {
        final sideBySide = bounds.maxWidth >= 510;
        final nursery = _NurseryCard(
          state: state,
          need: need,
          palette: palette,
          // A short turned phone gets a smaller room, so Bumpy's line stays
          // in view beside the ticks.
          sceneHeight: !sideBySide
              ? 192
              : bounds.maxHeight < 420
              ? 112
              : 156,
          needTicked: needTicked,
          babyLine: line?.text ?? '',
          lineIsDraft: line?.isDraft ?? false,
          hopAnimation: _hopAnimation,
        );
        final fact = hasFact
            ? _FactCard(
                state: state,
                need: need,
                guide: guide,
                fact: guide.factFor(_dayNumber(state.today)),
                palette: palette,
                adding: _addingQuestion,
                addFailed:
                    guide.questions.isNotEmpty &&
                    _failedQuestion == guide.questions.first,
                onAddQuestion: (text) => _addQuestion(text, need),
              )
            : null;
        final visit = _VisitCard(
          state: state,
          palette: palette,
          need: need,
          // With a guide, the fact card's "add a question" does this job.
          showTopicControl: !hasFact,
          savedForVisit: savedForVisit,
          savingTopic: _savingTopic,
          saveFailed: _failedTopic == need && !savedForVisit,
          onSaveForVisit: () => _saveForVisit(need),
        );
        final checkInsPanel = _CheckInsPanel(
          state: state,
          need: need,
          checkIns: checkIns,
          palette: palette,
          allDone: allDone,
          reviewing: reviewing,
          onReview: () => setState(() => _reviewingDay = state.today),
          onEndReview: () => setState(() => _reviewingDay = null),
          onCheckIn: _onCheckIn,
        );
        if (sideBySide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A turned phone keeps Bumpy's answer beside the ticks:
                // Bumpy, the fact and the visit on the left; ticks right.
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        nursery,
                        const SizedBox(height: 16),
                        if (fact != null) ...[fact, const SizedBox(height: 16)],
                        visit,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: checkInsPanel,
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nursery,
              const SizedBox(height: 16),
              if (fact != null) ...[fact, const SizedBox(height: 16)],
              visit,
              const SizedBox(height: 24),
              checkInsPanel,
            ],
          ),
        );
      },
    );
  }
}
