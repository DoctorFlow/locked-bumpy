import 'package:flutter/material.dart';
import '../widgets/pause_button.dart';
import '../widgets/paper_choice.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/paper.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import '../widgets/bumpy_avatar.dart';
import '../widgets/need_word.dart';
import '../widgets/paper_portrait.dart';

class ClosetSheet extends StatefulWidget {
  const ClosetSheet({super.key, required this.state});
  final AppState state;

  static Future<void> open(BuildContext context, AppState state) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 440),
      backgroundColor: AppPalette.of(context).paper,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (_) => ClosetSheet(state: state),
    );
  }

  @override
  State<ClosetSheet> createState() => _ClosetSheetState();
}

class _ClosetSheetState extends State<ClosetSheet> {
  late MaternalNeed _preview;

  @override
  void initState() {
    super.initState();
    _preview = widget.state.costumeOverride ?? widget.state.todayNeed;
    widget.state.addListener(_onChange);
  }

  bool get _available =>
      widget.state.isHalloween &&
      !widget.state.isPaused &&
      !widget.state.isFirstRun;

  void _onChange() {
    if (!_available && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    final state = widget.state;
    final palette = AppPalette.of(context);
    final name = _costumeName(_preview);
    final size = MediaQuery.sizeOf(context);
    final shortPhone = size.width <= 375 && size.height <= 600;
    // One line at every phone width: beside the two 48 px buttons a 320 px
    // sheet leaves about 190 px, so the title shrinks to fit there rather
    // than wrap. With enlarged system text it wraps instead, so the
    // parent's chosen size is never scaled away.
    final title = Text(
      'Tonight’s wardrobe',
      key: const ValueKey('closet-title'),
      maxLines: _largeText(context) ? null : 1,
      softWrap: _largeText(context),
      style: AppText.title.copyWith(color: palette.ink),
    );
    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: _largeText(context)
                ? title
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: title,
                  ),
          ),
        ),
        PauseButton(onPressed: state.pause, color: palette.ink),
        IconButton(
          tooltip: 'Close wardrobe',
          icon: Icon(Icons.close, color: palette.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
    final rail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaperCard(
          raised: true,
          child: Center(
            child: BumpyAvatar(
              need: _preview,
              palette: palette,
              skinTone: state.skinTone,
              happy: state.isChecked(state.todayNeed.name),
            ),
          ),
        ),
        SizedBox(height: shortPhone ? AppSpace.s : AppSpace.m),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                (constraints.maxWidth >= 320 ||
                        (constraints.maxWidth >= 282 &&
                            MediaQuery.textScalerOf(context).scale(14) <=
                                17)) &&
                    MediaQuery.textScalerOf(context).scale(14) <= 21
                ? 3
                : 2;
            final width =
                (constraints.maxWidth - AppSpace.s * (columns - 1)) / columns;
            final needs = MaternalNeed.values;
            // Rows of [columns] tiles. Each row is as tall as its tallest
            // tile and every tile stretches to it, so the grid stays even
            // when a need word wraps.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var start = 0; start < needs.length; start += columns) ...[
                  if (start > 0) const SizedBox(height: AppSpace.s),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = start; i < start + columns; i++) ...[
                          if (i > start) const SizedBox(width: AppSpace.s),
                          SizedBox(
                            width: width,
                            child: i < needs.length
                                ? _CostumeCard(
                                    thumbnailSize: shortPhone ? 64 : 96,
                                    need: needs[i],
                                    skinTone: state.skinTone,
                                    palette: palette,
                                    selected: _preview == needs[i],
                                    onTap: () =>
                                        setState(() => _preview = needs[i]),
                                  )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
    final footer = Padding(
      padding: const EdgeInsets.only(top: AppSpace.m, bottom: AppSpace.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Wear it for this visit. Today’s check-in stays the same.',
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: palette.inkSoft),
          ),
          const SizedBox(height: AppSpace.s),
          FilledButton(
            onPressed: () {
              state.setCostumeOverride(_preview);
              Navigator.of(context).pop();
            },
            child: Text('Wear $name'),
          ),
        ],
      ),
    );
    final compact =
        MediaQuery.sizeOf(context).height < 450 ||
        MediaQuery.textScalerOf(context).scale(14) > 21;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
        child: compact
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpace.m),
                    header,
                    const SizedBox(height: AppSpace.s),
                    rail,
                    footer,
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpace.m),
                  header,
                  const SizedBox(height: AppSpace.s),
                  Flexible(child: SingleChildScrollView(child: rail)),
                  footer,
                ],
              ),
      ),
    );
  }
}

/// System text enlarged past 130%: let the title wrap at its full size.
bool _largeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(24) > 24 * 1.3;

String _costumeName(MaternalNeed need) =>
    need.costume[0] + need.costume.substring(1).toLowerCase();

class _CostumeCard extends StatelessWidget {
  const _CostumeCard({
    required this.thumbnailSize,
    required this.need,
    required this.palette,
    required this.selected,
    required this.skinTone,
    required this.onTap,
  });
  final double thumbnailSize;
  final MaternalNeed need;
  final AppPalette palette;
  final bool selected;
  final SkinTone skinTone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = _costumeName(need);
    // Selected = a 3 px accent edge and a tick badge on the corner: never
    // colour alone. Passthrough: the card fills its slot, so the ring fits.
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        PaperCard(
          raised: true,
          child: PaperChoice(
            key: ValueKey('closet-${need.name}'),
            selected: selected,
            label: 'Try $name, ${needWord(need)}',
            onTap: onTap,
            focusColor: palette.ink,
            borderRadius: AppRadii.control,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xs,
                AppSpace.s,
                AppSpace.xs,
                AppSpace.s,
              ),
              child: Column(
                children: [
                  Image(
                    image: paperPortrait(need.assetPath(palette), skinTone),
                    height: thumbnailSize,
                    width: thumbnailSize,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong.copyWith(color: palette.ink),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  // Icon above the word on all six tiles: the same rhythm
                  // everywhere, and "Prenatal vitamin" wraps under its
                  // icon instead of beside it.
                  // The need's paper icon, drawn as decoration so the
                  // sheet's only Image widgets stay the six portraits.
                  SizedBox.square(
                    key: ValueKey('closet-need-icon-${need.name}'),
                    dimension: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(need.iconPath),
                          onError: (_, _) {},
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    needWord(need),
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(color: palette.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (selected) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.control,
                  border: Border.all(color: palette.accent, width: 3),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: -AppSpace.xs,
            end: -AppSpace.xs,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.paper, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.check, size: 18, color: palette.accentText),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
