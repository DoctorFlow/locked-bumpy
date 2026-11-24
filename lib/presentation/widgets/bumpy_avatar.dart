import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/need.dart';
import '../../domain/models/skin_tone.dart';
import 'paper_portrait.dart';

/// Full-body paper cut on the same square registration in both nursery looks.
class BumpyAvatar extends StatefulWidget {
  const BumpyAvatar({
    super.key,
    required this.need,
    required this.palette,
    required this.happy,
    this.hopAnimation,
    this.skinTone = SkinTone.peach,
  });

  final MaternalNeed need;
  final AppPalette palette;
  final bool happy;
  final SkinTone skinTone;
  final Animation<double>? hopAnimation;

  @override
  State<BumpyAvatar> createState() => _BumpyAvatarState();
}

class _BumpyAvatarState extends State<BumpyAvatar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheLook();
  }

  @override
  void didUpdateWidget(BumpyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.need != widget.need ||
        oldWidget.palette != widget.palette ||
        oldWidget.skinTone != widget.skinTone) {
      _precacheLook();
    }
  }

  /// Decode (and tint) both faces of the visible look ahead of time, so the
  /// 768 px paper never shows an empty box while the smile swaps in.
  void _precacheLook() {
    for (final happy in [false, true]) {
      final path = widget.need.assetPath(widget.palette, happy: happy);
      precacheImage(
        paperPortrait(path, widget.skinTone),
        context,
        // A damaged asset already falls back to the moon icon in build.
        onError: (_, _) {},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final need = widget.need;
    final palette = widget.palette;
    final happy = widget.happy;
    final path = need.assetPath(palette, happy: happy);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final look = palette.isHalloween
        ? '${need.costume.toLowerCase()} costume'
        : 'lavender onesie';
    final avatar = AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      child: Image(
        image: paperPortrait(path, widget.skinTone),
        key: ValueKey(path),
        width: 190,
        height: 190,
        fit: BoxFit.contain,
        // Keep the same space and spoken description if an asset is damaged.
        errorBuilder: (context, error, stack) => SizedBox.square(
          dimension: 190,
          child: Icon(Icons.nightlight_round, color: palette.moon, size: 40),
        ),
      ),
    );
    final hop = widget.hopAnimation;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      image: true,
      label: 'Bumpy in a $look${happy ? ', smiling' : ''}',
      excludeSemantics: true,
      child: reduceMotion || hop == null
          ? avatar
          : AnimatedBuilder(
              animation: hop,
              child: avatar,
              builder: (_, child) => Transform.translate(
                // Whole device pixels, so the paper is not resampled mid-hop.
                offset: Offset(
                  0,
                  (hop.value * pixelRatio).roundToDouble() / pixelRatio,
                ),
                child: child,
              ),
            ),
    );
  }
}
