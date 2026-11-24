import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import 'bumpy_avatar.dart';

/// The same paper room welcomes the parent and holds the daily visit.
class NurseryScene extends StatefulWidget {
  const NurseryScene({
    super.key,
    required this.palette,
    required this.avatar,
    this.cornerAction,
    this.height = 204,
  });
  final AppPalette palette;
  final BumpyAvatar avatar;
  final Widget? cornerAction;
  final double height;

  /// One backdrop per look, sized for the widest card on a 3x phone.
  static String backdropFor(AppPalette palette) => palette.isHalloween
      ? 'assets/images/nursery-halloween.webp'
      : 'assets/images/nursery-everyday.webp';

  @override
  State<NurseryScene> createState() => _NurserySceneState();
}

class _NurserySceneState extends State<NurseryScene> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheBackdrop();
  }

  @override
  void didUpdateWidget(NurseryScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.palette != widget.palette) _precacheBackdrop();
  }

  void _precacheBackdrop() {
    precacheImage(
      AssetImage(NurseryScene.backdropFor(widget.palette)),
      context,
      // A missing backdrop already falls back to the sky colour in build.
      onError: (_, _) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final height = widget.height;
    final cornerAction = widget.cornerAction;
    final separateAction =
        cornerAction != null && MediaQuery.textScalerOf(context).scale(14) > 21;
    final room = SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Image.asset(
              NurseryScene.backdropFor(palette),
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.85),
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => ColoredBox(color: palette.skyBottom),
            ),
          ),
          SizedBox(
            height: height < 194 ? height - 4 : 190,
            child: FittedBox(child: widget.avatar),
          ),
          if (cornerAction != null && !separateAction)
            Positioned(top: 6, left: 6, child: cornerAction),
        ],
      ),
    );
    if (!separateAction) return room;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: cornerAction,
          ),
        ),
        room,
      ],
    );
  }
}
