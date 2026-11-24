import 'package:flutter/material.dart';
import '../../../content/content_loader.dart';
import '../../../content/content_paths.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/palette.dart';
import '../../../domain/models/app_state.dart';
import '../../../domain/models/content_record.dart';
import '../../../domain/models/need.dart';
import '../../sheets/closet_sheet.dart';
import '../../widgets/bumpy_avatar.dart';
import '../../widgets/nursery_scene.dart';
import '../../widgets/visit_topics.dart';

part 'nursery_card.dart';
part 'check_in_list.dart';

/// Today tab — daily loop under 30 seconds.
/// Baby-voice lines are loaded from [ContentLoader] (bundled JSON, offline).
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.state});

  final AppState state;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _hopController;
  late Animation<double> _hopAnimation;

  /// Cached today-lines once loaded.
  List<ContentRecord>? _records;

  bool _hopping = false;
  DateTime? _reviewingDay;
  bool _savingTopic = false;
  MaternalNeed? _failedTopic;

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
  }

  Future<void> _loadRecords() async {
    final records = await ContentLoader.load(ContentPaths.todayLines);
    if (mounted) setState(() => _records = records);
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

  // ── Line resolution ───────────────────────────────────────────────────────

  String _babyLine(
    MaternalNeed need,
    bool needTicked,
    bool allDone,
    AppPalette palette,
  ) {
    final records = _records;
    if (records == null) return '';
    return ContentLoader.find(
          records: records,
          need: allDone ? 'ALL' : need.needName,
          category: allDone
              ? 'goodbye'
              : needTicked
              ? 'thank_you'
              : 'greeting',
          mode:
              palette.isHalloween &&
                  (widget.state.costumeOverride ?? need) == need
              ? 'halloween'
              : 'everyday',
        )?.text ??
        '';
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
    final babyLine = _babyLine(need, needTicked, allDone, palette);
    final savedForVisit = state.visitTopics.contains(need);

    return LayoutBuilder(
      builder: (context, bounds) {
        final sideBySide = bounds.maxWidth >= 510;
        final nursery = _NurseryCard(
          state: state,
          need: need,
          palette: palette,
          sideBySide: sideBySide,
          needTicked: needTicked,
          babyLine: babyLine,
          savedForVisit: savedForVisit,
          savingTopic: _savingTopic,
          saveFailed: _failedTopic == need && !savedForVisit,
          hopAnimation: _hopAnimation,
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
                Expanded(child: SingleChildScrollView(child: nursery)),
                const SizedBox(width: 16),
                Expanded(child: SingleChildScrollView(child: checkInsPanel)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [nursery, const SizedBox(height: 20), checkInsPanel],
          ),
        );
      },
    );
  }
}
