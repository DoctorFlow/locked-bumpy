import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../widgets/pause_button.dart';
import '../../content/chapter_loader.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/content_record.dart';
import '../../domain/models/need.dart';
import '../../domain/models/week_card.dart';
import '../../domain/pregnancy.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/draft_tag.dart';
import '../widgets/need_word.dart';
import '../widgets/nursery_scene.dart';
import '../widgets/visit_topics.dart';
import 'guide_screen.dart';
import 'guides_screen.dart' show TopicGuideRow;
import 'urgent_screen.dart';

part 'this_week_chapter.dart';

/// This Week tab — browse gestational weeks 4–42 with approved baby-voice cards.
class ThisWeekScreen extends StatefulWidget {
  const ThisWeekScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ThisWeekScreen> createState() => _ThisWeekScreenState();
}

class _ThisWeekScreenState extends State<ThisWeekScreen> {
  List<WeekCard>? _cards;
  List<Chapter> _chapters = const [];
  static const int _minWeek = AppConstants.minWeek;
  static const int _maxWeek = AppConstants.maxWeek;
  late int _currentWeek;
  late int _selectedWeek;
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.state.currentWeek ?? _minWeek;
    _selectedWeek = _currentWeek;
    _pages = PageController(initialPage: _selectedWeek - _minWeek);
    _loadCards();
  }

  @override
  void didUpdateWidget(ThisWeekScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.state.currentWeek ?? _minWeek;
    if (current == _currentWeek) return;
    final following = _selectedWeek == _currentWeek;
    _currentWeek = current;
    if (following) {
      _selectedWeek = current;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(current - _minWeek);
      });
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int week) {
    final index = week - _minWeek;
    if (MediaQuery.disableAnimationsOf(context) ||
        (_selectedWeek - week).abs() > 1) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _chooseWeek() async {
    final palette = AppPalette.of(context);
    final selected = _selectedWeek;
    final selectedKey = GlobalKey();
    var positioned = false;
    final week = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.paper,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      constraints: const BoxConstraints(maxWidth: 440),
      builder: (sheet) {
        if (!positioned) {
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
              maxHeight: MediaQuery.sizeOf(sheet).height * .73,
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
                            'Choose a week',
                            style: AppText.title.copyWith(color: palette.ink),
                          ),
                        ),
                      ),
                      PauseButton(
                        onPressed: widget.state.pause,
                        color: palette.ink,
                      ),
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
                      spacing: AppSpace.s,
                      runSpacing: AppSpace.s,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var n = _minWeek; n <= _maxWeek; n++)
                          Semantics(
                            key: n == selected ? selectedKey : null,
                            label: n == _currentWeek
                                ? 'Week $n, current week'
                                : 'Week $n',
                            selected: n == selected,
                            button: true,
                            excludeSemantics: true,
                            onTap: () => Navigator.pop(sheet, n),
                            // A week tile is a paper piece, not a link: no
                            // underline. Selected = accent fill plus a tick.
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(56, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.m,
                                ),
                                foregroundColor: n == selected
                                    ? palette.accentText
                                    : palette.ink,
                                backgroundColor: n == selected
                                    ? palette.accent
                                    : palette.paperRaised,
                                side: n == _currentWeek
                                    ? BorderSide(
                                        color: n == selected
                                            ? palette.accentDeep
                                            : palette.accent,
                                        width: 2,
                                      )
                                    : BorderSide(color: palette.outline),
                              ),
                              onPressed: () => Navigator.pop(sheet, n),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (n == selected) ...[
                                    const Icon(Icons.check_rounded, size: 16),
                                    const SizedBox(width: AppSpace.xs),
                                  ],
                                  Text('$n'),
                                ],
                              ),
                            ),
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
    if (mounted && week != null) _goTo(week);
  }

  Future<void> _loadCards() async {
    final chapters = ChapterLoader.load();
    final cards = await ContentLoader.loadWeekCards();
    final loaded = await chapters;
    if (mounted) {
      setState(() {
        _cards = cards;
        _chapters = loaded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final cards = _cards;

    if (cards == null) {
      return Center(child: CircularProgressIndicator(color: palette.accent));
    }

    final mode = palette.isHalloween ? 'halloween' : 'everyday';
    // At large text or on a short screen a fixed strip would leave the
    // chapter a slot about a third of the screen tall, so the strip moves to
    // the top of each page and scrolls away with it.
    final strip = !_stripScrolls(context);
    // Each week is a page that starts right under the top bar and scrolls on
    // its own. The fixed week strip sits below the pages, never on top of
    // them, so the last section always scrolls fully into view above it.
    Widget page(Key key, int week, Widget child) => CustomScrollView(
      key: key,
      slivers: [
        if (!strip)
          SliverToBoxAdapter(
            key: const ValueKey('week-strip-in-page'),
            child: _weekStrip(palette, week),
          ),
        // Bottom space of one week-bar height (48) plus a gap: the page's last
        // link (the guide or urgent link) ends well clear of the bar, never
        // flush against it (test lab round 4).
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.s,
            AppSpace.page,
            AppSpace.target + AppSpace.xl,
          ),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    );
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pages,
            itemCount: _maxWeek - _minWeek + 1,
            onPageChanged: (page) =>
                setState(() => _selectedWeek = page + _minWeek),
            itemBuilder: (context, index) {
              final week = _minWeek + index;
              final card = WeekCard.findFor(
                cards: cards,
                week: week,
                mode: mode,
              );
              final chapter = ChapterLoader.forWeek(_chapters, week);
              if (chapter != null) {
                return page(
                  PageStorageKey('chapter-week-$week'),
                  week,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ChapterPage(
                        chapter: chapter,
                        week: week,
                        card: card,
                        palette: palette,
                        state: widget.state,
                        isCurrentWeek: week == _currentWeek,
                        currentWeek: _currentWeek,
                        onReturn: () => _goTo(_currentWeek),
                        onVisit: () => VisitTopics.edit(context, widget.state),
                      ),
                      const SizedBox(height: AppSpace.l),
                      // The page ends as Today does: the quiet way to the
                      // urgent signs, on the page below the chapter card.
                      UrgentLink(
                        key: ValueKey('chapter-urgent-link-$week'),
                        state: widget.state,
                        palette: palette,
                      ),
                    ],
                  ),
                );
              }
              return page(
                PageStorageKey('week-$week'),
                week,
                _WeekCardView(
                  onVisit: () => VisitTopics.edit(context, widget.state),
                  onReturn: () => _goTo(_currentWeek),
                  portrait: week == _currentWeek
                      ? BumpyAvatar(
                          need:
                              widget.state.costumeOverride ??
                              widget.state.todayNeed,
                          palette: palette,
                          happy: false,
                          skinTone: widget.state.skinTone,
                        )
                      : null,
                  week: week,
                  card: card,
                  palette: palette,
                  isCurrentWeek: week == _currentWeek,
                ),
              );
            },
          ),
        ),
        if (strip)
          DecoratedBox(
            key: const ValueKey('week-strip-fixed'),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: palette.moonlightSoft.withValues(alpha: .25),
                ),
              ),
            ),
            child: _weekStrip(palette, _selectedWeek),
          ),
      ],
    );
  }

  /// True when the week strip scrolls with the page instead of staying
  /// fixed: text above 130 percent, or a screen under 600 tall.
  bool _stripScrolls(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) > 16 * 1.3 ||
      MediaQuery.sizeOf(context).height < 600;

  /// A quiet strip: no fills, soft moonlight. It is there when wanted and
  /// does not compete with the page. [week] is the week it moves from.
  Widget _weekStrip(AppPalette palette, int week) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.arrow_back_ios_new,
            label: 'Previous week',
            enabled: week > _minWeek,
            palette: palette,
            onTap: () => _goTo(week - 1),
          ),
          Flexible(
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: palette.moonlightSoft,
              ),
              onPressed: _chooseWeek,
              icon: const Icon(Icons.calendar_view_month_rounded, size: 20),
              // One line: at a large text size the words shrink to fit
              // between the arrows instead of wrapping.
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Choose week',
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          _NavButton(
            icon: Icons.arrow_forward_ios,
            label: 'Next week',
            enabled: week < _maxWeek,
            palette: palette,
            onTap: () => _goTo(week + 1),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// A week without a chapter page (none ship tonight, and a chapter hidden by
/// review status falls back here too): the week's own card as one paper page.
class _WeekCardView extends StatelessWidget {
  const _WeekCardView({
    required this.onVisit,
    required this.week,
    required this.card,
    required this.palette,
    required this.isCurrentWeek,
    required this.portrait,
    required this.onReturn,
  });

  final int week;
  final WeekCard? card;
  final AppPalette palette;
  final bool isCurrentWeek;
  final BumpyAvatar? portrait;
  final VoidCallback onReturn;
  final VoidCallback onVisit;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final beside =
        size.width >= 540 &&
        size.height <= 600 &&
        MediaQuery.textScalerOf(context).scale(14) <= 21;
    final short = beside && size.height < 380;
    final avatar = portrait;
    final room = avatar == null
        ? null
        : NurseryScene(
            palette: palette,
            avatar: avatar,
            height: beside ? (short ? 112 : 150) : 192,
          );
    final text = Padding(
      padding: short
          ? const EdgeInsets.symmetric(
              horizontal: AppSpace.m,
              vertical: AppSpace.s,
            )
          : const EdgeInsets.all(AppSpace.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isCurrentWeek) ...[
                Image.asset(
                  'assets/images/need-rest.png',
                  width: 40,
                  height: 40,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: AppSpace.m),
              ],
              Expanded(
                child: Wrap(
                  spacing: AppSpace.m,
                  runSpacing: AppSpace.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Week $week',
                        style: (short ? AppText.title : AppText.display)
                            .copyWith(color: palette.accent),
                      ),
                    ),
                    if (isCurrentWeek)
                      _HereTag(fill: palette.accent, ink: palette.accentText),
                    // Only a review build ever shows a draft or held card.
                    if (card?.isDraft ?? false)
                      DraftTag.of(palette: palette, held: card!.isHeld),
                  ],
                ),
              ),
            ],
          ),
          if (card != null) ...[
            SizedBox(height: short ? AppSpace.xs : AppSpace.m),
            Text(
              card!.babyLine,
              style: AppText.bumpyStory.copyWith(color: palette.ink),
            ),
          ],
          if (!isCurrentWeek) ...[
            const SizedBox(height: AppSpace.s),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: palette.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.m,
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to this week'),
              onPressed: onReturn,
            ),
          ],
          _WeekInvitation(
            key: ValueKey(week),
            week: week,
            palette: palette,
            onVisit: onVisit,
          ),
        ],
      ),
    );
    return PaperCard(
      child: room != null && beside
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: short ? 1 : 2, child: room),
                Expanded(flex: short ? 2 : 3, child: text),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [?room, text],
            ),
    );
  }
}

class _WeekInvitation extends StatefulWidget {
  const _WeekInvitation({
    super.key,
    required this.week,
    required this.palette,
    required this.onVisit,
  });

  final int week;
  final AppPalette palette;
  final VoidCallback onVisit;

  @override
  State<_WeekInvitation> createState() => _WeekInvitationState();
}

class _WeekInvitationState extends State<_WeekInvitation> {
  static const ideas = [
    'Pick a song you’d love Bumpy to know. Play it for yourself today.',
    'What’s a story you loved as a child? Read the first page aloud if you feel like it.',
    'Picture a place you’d love to show Bumpy. What would you point out first?',
    'Think of a family saying that makes you smile. Try saying it to Bumpy.',
    'What’s one ordinary thing you can’t wait to do together? Imagine an afternoon doing just that.',
    'Choose a nickname just for today. It can be as silly as you like.',
  ];
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final preparation = switch (widget.week) {
      <= 13 =>
        'Save your care team’s number in your phone. If you’re unsure who to call between visits, bring that question along.',
      <= 23 =>
        'Think back to your last visit. Was there something you wanted to ask on the way home?',
      <= 31 =>
        'Picture your next visit. What would you like your care team to explain in your own words?',
      _ =>
        'Think through getting to your next visit. Is there anything about timing, travel or support you want to ask about?',
    };
    final body = AppText.body.copyWith(color: palette.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.xl),
        _SectionTitle(
          'One thing to get ready',
          icon: Icons.checklist_rounded,
          marker: palette.accent,
          palette: palette,
        ),
        const SizedBox(height: AppSpace.s),
        Text(preparation, style: body),
        const SizedBox(height: AppSpace.m),
        OutlinedButton.icon(
          onPressed: widget.onVisit,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('My question for the visit'),
        ),
        const SizedBox(height: AppSpace.xl),
        _TintedPiece(
          tint: palette.accent,
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                'Something to look forward to',
                icon: Icons.wb_sunny_rounded,
                marker: palette.accent,
                palette: palette,
              ),
              const SizedBox(height: AppSpace.s),
              Semantics(
                liveRegion: true,
                child: Text(
                  ideas[(widget.week - 4 + _offset) % ideas.length],
                  style: body,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: palette.ink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: AppSpace.m,
                  ),
                ),
                onPressed: () => setState(() => _offset++),
                child: const Text('Try another idea'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Previous and next week: plain moonlight arrows on the page, no fill, so
/// the strip stays quieter than the page above it.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: IconButton(
        onPressed: enabled ? onTap : null,
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSpace.target, AppSpace.target),
          foregroundColor: palette.moonlightSoft,
          disabledForegroundColor: palette.moonlightSoft.withValues(
            alpha: 0.35,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
        ),
        icon: Icon(icon, semanticLabel: label, size: 20),
      ),
    );
  }
}
