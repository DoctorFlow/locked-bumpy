import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/content_record.dart';
import '../../domain/models/need.dart';
import '../sheets/closet_sheet.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/nursery_scene.dart';

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
    final records = await ContentLoader.load('assets/content/today_lines.json');
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
          mode: palette.isHalloween ? 'halloween' : 'everyday',
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
    final allDone = state.allChecked;
    final checkIns = state.dailyCheckIns;
    final babyLine = _babyLine(need, needTicked, allDone, palette);

    return LayoutBuilder(
      builder: (context, bounds) {
        final sideBySide = bounds.maxWidth >= 600;
        final nursery = Material(
          color: palette.paper,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NurseryScene(
                palette: palette,
                height: sideBySide ? 156 : 204,
                cornerAction: palette.isHalloween
                    ? Tooltip(
                        message: 'Costume closet',
                        child: FilledButton.tonalIcon(
                          onPressed: () => ClosetSheet.open(context, state),
                          icon: const Icon(Icons.checkroom, size: 18),
                          label: const Text('Wardrobe'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: palette.paper,
                            foregroundColor: palette.ink,
                          ),
                        ),
                      )
                    : null,
                avatar: BumpyAvatar(
                  need: state.costumeOverride ?? need,
                  palette: palette,
                  happy: needTicked,
                  skinTone: state.skinTone,
                  hopAnimation: _hopAnimation,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            state.babyDisplayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        Text(
                          state.costumeOverride != null && palette.isHalloween
                              ? 'TODAY · ${need.needName}'
                              : need.tag(palette),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: .5,
                            fontWeight: FontWeight.w600,
                            color: palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    if (babyLine.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          babyLine,
                          style: TextStyle(
                            fontSize: 21,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
        final checkInsPanel = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                "Today's check-ins",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: palette.moonlight,
                ),
              ),
            ),
            if (state.completedCheckIns.isEmpty) ...[
              const SizedBox(height: 3),
              Text(
                'Tap a row when you’ve done it.',
                style: TextStyle(color: palette.moonlightSoft, fontSize: 14),
              ),
            ],
            const SizedBox(height: 10),
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
                      onTap: () => _onCheckIn(item.name),
                    ),
                  ],
                ],
              ),
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
