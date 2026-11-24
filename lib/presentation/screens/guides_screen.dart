import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/guide.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import '../widgets/draft_tag.dart';
import '../widgets/need_word.dart';
import '../widgets/paper_portrait.dart';
import '../widgets/visit_topics.dart';
import 'guide_screen.dart';
import 'urgent_screen.dart';

/// Six need cards. A card whose guide passed the gate opens the guide page;
/// a hidden guide's card keeps its name, Bumpy in costume and the visit-list
/// control, and promises nothing more (no arrow, no accordion).
/// Everything stays inside the main shell so Pause immediately hides it.
class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key, required this.state});
  final AppState state;

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  late final _guides = ContentLoader.loadGuides();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return FutureBuilder<Map<MaternalNeed, Guide>>(
      future: _guides,
      builder: (context, snapshot) => ListView(
        // Build every card (only a dozen pieces), so the page and its
        // spoken order are complete even beyond the first screen.
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.page,
          AppSpace.l,
          AppSpace.page,
          AppSpace.xl,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              snapshot.data?.isNotEmpty == true ? 'Care guides' : 'Care topics',
              style: AppText.title.copyWith(color: palette.moonlight),
            ),
          ),
          const SizedBox(height: AppSpace.l),
          // Near the top, visible without scrolling (Amendment 3): a parent
          // who needs this list should never find it by luck.
          _UrgentRow(
            palette: palette,
            onOpen: () => UrgentScreen.open(context, widget.state),
          ),
          const SizedBox(height: AppSpace.l),
          VisitTopics(state: widget.state),
          const SizedBox(height: AppSpace.xl),
          for (final need in [
            widget.state.todayNeed,
            ...MaternalNeed.values.where((n) => n != widget.state.todayNeed),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.l),
              child: _NeedCard(
                need: need,
                isToday: need == widget.state.todayNeed,
                palette: palette,
                guide: snapshot.data?[need],
                skinTone: widget.state.skinTone,
                savedForVisit: widget.state.visitTopics.contains(need),
                onOpen: () => GuideScreen.open(context, widget.state, need),
                onVisitList: () =>
                    VisitTopics.edit(context, widget.state, include: need),
              ),
            ),
          const SizedBox(height: AppSpace.s),
          Text(
            AppConstants.disclaimer,
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: palette.moonlightSoft),
          ),
        ],
      ),
    );
  }
}

/// The one row that opens the shared urgent list. Plain ink on paper with a
/// heavy ink edge and an ink icon tile: calm, but clearly not like the
/// playful need cards above it.
class _UrgentRow extends StatelessWidget {
  const _UrgentRow({required this.palette, required this.onOpen});
  final AppPalette palette;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkedEdge(
      color: palette.ink,
      child: PaperCard(
        key: const ValueKey('urgent-row'),
        child: Semantics(
          button: true,
          label: UrgentScreen.rowLabel,
          excludeSemantics: true,
          // The node takes the tap on web and with a screen reader; without
          // its own onTap the row would do nothing there.
          onTap: onOpen,
          child: InkWell(
            onTap: onOpen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.m,
                  AppSpace.s,
                  AppSpace.m,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.ink,
                        borderRadius: AppRadii.tag,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.s),
                        child: Icon(
                          Icons.health_and_safety_outlined,
                          color: palette.paper,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.m),
                    Expanded(
                      child: Text(
                        UrgentScreen.rowLabel,
                        style: AppText.heading.copyWith(color: palette.ink),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: palette.ink, size: 28),
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

/// A 2 px edge in [color] drawn over a [PaperCard] (card corners). The
/// theme's card has only the 1 px lit edge; the serious pieces need more.
class InkedEdge extends StatelessWidget {
  const InkedEdge({
    super.key,
    required this.color,
    required this.child,
    this.borderRadius = AppRadii.card,
  });
  final Color color;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: borderRadius,
      border: Border.all(color: color, width: 2),
    ),
    child: child,
  );
}

/// Bumpy wearing [need]'s costume, in either look: the costume is the idea
/// of the app, so the Everyday look shows the same costume by day.
String costumePortraitPath(MaternalNeed need) =>
    need.assetPath(AppPalette.halloween);

/// Bumpy in costume on a small raised piece of paper, with the need's own
/// paper icon pinned in the corner.
class NeedPortrait extends StatelessWidget {
  const NeedPortrait({
    super.key,
    required this.need,
    required this.skinTone,
    this.size = 88,
  });
  final MaternalNeed need;
  final SkinTone skinTone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final path = costumePortraitPath(need);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.paperRaised,
                  borderRadius: AppRadii.control,
                  border: Border.all(color: palette.edge),
                  boxShadow: paperShadows(palette, raised: true),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xs),
                child: Image(
                  key: ValueKey(path),
                  image: paperPortrait(path, skinTone),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Image.asset(
                    need.iconPath,
                    width: size / 2,
                    height: size / 2,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: -AppSpace.xs,
              bottom: -AppSpace.xs,
              child: Image.asset(
                need.iconPath,
                width: 28,
                height: 28,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({
    required this.need,
    required this.isToday,
    required this.palette,
    required this.guide,
    required this.skinTone,
    required this.savedForVisit,
    required this.onOpen,
    required this.onVisitList,
  });
  final MaternalNeed need;
  final bool isToday;
  final AppPalette palette;
  final Guide? guide;
  final SkinTone skinTone;
  final bool savedForVisit;
  final VoidCallback onOpen;
  final VoidCallback onVisitList;

  String? get _status => isToday || savedForVisit
      ? [
          if (isToday) 'Today’s need',
          if (savedForVisit) 'On your visit list',
        ].join(' · ')
      : null;

  /// Six of these sit on the page, so each says its need aloud; the spoken
  /// label still holds the visible words.
  Widget _visitButton() => Semantics(
    button: true,
    excludeSemantics: true,
    label: savedForVisit
        ? 'On my visit list: ${needWord(need)}'
        : 'Add ${needWord(need)} to my visit list',
    onTap: onVisitList,
    child: VisitListButton(
      label: savedForVisit ? 'On my visit list' : 'Add to my visit list',
      saved: savedForVisit,
      onPressed: onVisitList,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final copy = guide;
    final status = _status;
    final top = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.l,
        AppSpace.s,
        AppSpace.m,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeedPortrait(need: need, skinTone: skinTone, size: 72),
          const SizedBox(width: AppSpace.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Its own heading node, so heading navigation reaches each
                // need inside the card's button.
                Semantics(
                  container: true,
                  header: true,
                  child: Text(
                    needWord(need),
                    style: AppText.heading.copyWith(color: palette.ink),
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                CostumeTag(costume: need.costume, palette: palette),
                if (status != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    status,
                    style: AppText.small.copyWith(color: palette.inkSoft),
                  ),
                ],
              ],
            ),
          ),
          // Level with the need word, not floating halfway down the card.
          if (copy != null)
            Icon(Icons.chevron_right, color: palette.ink, size: 28)
          else
            const SizedBox(width: AppSpace.s),
        ],
      ),
    );
    // The point runs the full width of the card under the portrait row, so
    // it reads as a paragraph, not a narrow column beside the picture.
    final summary = copy == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              0,
              AppSpace.l,
              AppSpace.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A health sentence is never cut: the card grows to hold
                // the whole summary, caveat included.
                Text(
                  copy.point,
                  key: ValueKey('guide-summary-${need.name}'),
                  style: AppText.body.copyWith(color: palette.ink),
                ),
                if (copy.isDraft)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.s),
                    child: DraftTag(palette: palette),
                  ),
              ],
            ),
          );
    return PaperCard(
      key: PageStorageKey(need),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (copy == null)
            top
          else
            Semantics(
              button: true,
              label: 'Open the ${needWord(need)} guide',
              onTapHint: 'Open the guide',
              child: InkWell(
                onTap: onOpen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [top, ?summary],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              0,
              AppSpace.l,
              AppSpace.l,
            ),
            child: _visitButton(),
          ),
        ],
      ),
    );
  }
}

/// "Add to my visit list" in its one form on Guides, the guide page and the
/// chapter page: a full-width outlined button, 48 tall, with the list-plus
/// icon (a tick on the list once saved). Words stay with the caller.
class VisitListButton extends StatelessWidget {
  const VisitListButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.saved = false,
    this.semanticsLabel,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool saved;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSpace.target),
    ),
    onPressed: onPressed,
    icon: Icon(saved ? Icons.playlist_add_check : Icons.playlist_add, size: 22),
    label: Text(
      label,
      textAlign: TextAlign.center,
      semanticsLabel: semanticsLabel,
    ),
  );
}

/// The costume word as a small paper tag (capitals live only in `label`).
class CostumeTag extends StatelessWidget {
  const CostumeTag({super.key, required this.costume, required this.palette});
  final String costume;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${costume[0].toUpperCase()}${costume.substring(1).toLowerCase()} '
        'costume',
    excludeSemantics: true,
    child: _tag(),
  );

  Widget _tag() => DecoratedBox(
    decoration: BoxDecoration(
      color: palette.paperRaised,
      borderRadius: AppRadii.tag,
      border: Border.all(color: palette.edge),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s,
        vertical: AppSpace.xs,
      ),
      child: Text(
        costume,
        style: AppText.label.copyWith(color: palette.inkSoft),
      ),
    ),
  );
}
