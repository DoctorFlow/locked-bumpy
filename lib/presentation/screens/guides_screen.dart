import 'package:flutter/material.dart';
import '../../content/content_loader.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/guide.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/draft_tag.dart';
import '../widgets/paper_portrait.dart';
import '../widgets/visit_topics.dart';
import 'guide_screen.dart';

/// Six need cards. A card whose guide passed the gate opens the guide page;
/// a hidden guide's card keeps its name, Bumpy and the visit-list control.
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
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            header: true,
            child: Text(
              snapshot.data?.isNotEmpty == true ? 'Care guides' : 'Care topics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.moonlight,
              ),
            ),
          ),
          const SizedBox(height: 16),
          VisitTopics(state: widget.state),
          const SizedBox(height: 16),
          for (final need in [
            widget.state.todayNeed,
            ...MaternalNeed.values.where((n) => n != widget.state.todayNeed),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
          Text(
            AppConstants.disclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.moonlightSoft, fontSize: 14),
          ),
        ],
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

  Widget _visitButton() => OutlinedButton.icon(
    onPressed: onVisitList,
    style: OutlinedButton.styleFrom(
      foregroundColor: palette.ink,
      minimumSize: const Size.fromHeight(48),
    ),
    icon: Icon(savedForVisit ? Icons.bookmark : Icons.bookmark_outline),
    label: Text(savedForVisit ? 'On my visit list' : 'Add to my visit list'),
  );

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final copy = guide;
    return Material(
      key: PageStorageKey(need),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      color: palette.paper,
      child: copy == null ? _hidden(context, shape) : _ready(copy),
    );
  }

  /// A guide that passed the gate: the card opens the guide page.
  Widget _ready(Guide copy) {
    final status = _status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Open the ${need.label} guide',
          child: InkWell(
            onTap: onOpen,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
                child: Row(
                  children: [
                    // Bumpy in this need's costume (the onesie in Everyday).
                    Image(
                      image: paperPortrait(need.assetPath(palette), skinTone),
                      width: 72,
                      height: 72,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => Image.asset(
                        need.iconPath,
                        width: 48,
                        height: 48,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            need.label,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (palette.isHalloween)
                            Text(
                              need.costume,
                              style: TextStyle(
                                color: palette.inkSoft,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (status != null)
                            Text(
                              status,
                              style: TextStyle(
                                color: palette.inkSoft,
                                fontSize: 14,
                              ),
                            ),
                          if (copy.isDraft)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: DraftTag(palette: palette),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: palette.inkSoft),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: _visitButton(),
        ),
      ],
    );
  }

  /// A hidden guide: the need card stays, as before, with its name, Bumpy in
  /// the costume and the visit-list control.
  Widget _hidden(BuildContext context, ShapeBorder shape) {
    final status = _status;
    return ExpansionTile(
      key: PageStorageKey(('hidden', need)),
      expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      shape: shape,
      collapsedShape: shape,
      iconColor: palette.ink,
      collapsedIconColor: palette.inkSoft,
      leading: Image.asset(
        need.iconPath,
        width: 40,
        height: 40,
        excludeFromSemantics: true,
      ),
      title: Text(
        need.label,
        style: TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
      ),
      subtitle: status != null
          ? Text(status, style: TextStyle(color: palette.inkSoft))
          : null,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: BumpyAvatar(
            need: need,
            palette: palette,
            happy: false,
            skinTone: skinTone,
          ),
        ),
        if (palette.isHalloween)
          Text(
            need.costume,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 12),
        _visitButton(),
      ],
    );
  }
}
