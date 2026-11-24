import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import 'bumpy_avatar.dart';

/// The same paper room welcomes the parent and holds the daily visit.
///
/// Three layers, back to front: the sky (the top of the backdrop picture),
/// a paper hill in [AppPalette.hill] with a soft shadow where Bumpy stands,
/// and Bumpy. The hill is drawn, not cropped from the picture, so Bumpy has
/// ground under the feet at every size the room is shown.
class NurseryScene extends StatefulWidget {
  const NurseryScene({
    super.key,
    required this.palette,
    required this.avatar,
    this.cornerAction,
    this.compactCornerAction,
    this.height = 204,
  });
  final AppPalette palette;
  final BumpyAvatar avatar;
  final Widget? cornerAction;

  /// The same action as [cornerAction] as a 48 x 48 icon-only button, shown
  /// instead of it in a room narrower than [compactBelow], so the labelled
  /// chip never covers Bumpy's head.
  final Widget? compactCornerAction;
  final double height;

  /// Rooms narrower than this show [compactCornerAction].
  static const double compactBelow = 340;

  /// One backdrop per look, sized for the widest card on a 3x phone.
  static String backdropFor(AppPalette palette) => palette.isHalloween
      ? 'assets/images/nursery-halloween.webp'
      : 'assets/images/nursery-everyday.webp';

  /// Height of Bumpy's picture in a room of [height].
  static double spriteHeightFor(double height) =>
      height < 194 ? height - 4 : 190;

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
    return LayoutBuilder(
      builder: (context, bounds) => _buildRoom(
        context,
        compact:
            widget.compactCornerAction != null &&
            bounds.maxWidth < NurseryScene.compactBelow,
      ),
    );
  }

  Widget _buildRoom(BuildContext context, {required bool compact}) {
    final palette = widget.palette;
    final height = widget.height;
    // The icon-only button does not grow with the text size, so it always
    // sits in the room's corner.
    final cornerAction = compact
        ? widget.compactCornerAction
        : widget.cornerAction;
    final separateAction =
        !compact &&
        cornerAction != null &&
        MediaQuery.textScalerOf(context).scale(14) > 21;
    final sprite = NurseryScene.spriteHeightFor(height);
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
          Positioned.fill(
            child: CustomPaint(
              painter: _GroundPainter(
                hill: palette.hill,
                shadow: palette.shadow,
                night: palette.isHalloween,
                sprite: sprite,
                // Bumpy stays on the ground when motion is reduced.
                hop: MediaQuery.disableAnimationsOf(context)
                    ? null
                    : widget.avatar.hopAnimation,
              ),
            ),
          ),
          SizedBox(
            height: sprite,
            child: FittedBox(child: widget.avatar),
          ),
          if (cornerAction != null && !separateAction)
            // 12 in, clear of the card's 20 px corner cut.
            Positioned(top: 12, left: 12, child: cornerAction),
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

/// The hill Bumpy stands on and the shadow under the feet.
///
/// Every measure is a share of Bumpy's picture height, so the ground keeps
/// its place under the feet from the 112 px room to the 204 px one.
class _GroundPainter extends CustomPainter {
  _GroundPainter({
    required this.hill,
    required this.shadow,
    required this.night,
    required this.sprite,
    this.hop,
  }) : super(repaint: hop);

  final Color hill;
  final Color shadow;
  final bool night;
  final double sprite;
  final Animation<double>? hop;

  /// The hill crest above the floor of the room: behind Bumpy's legs.
  static const double _crest = .22;

  /// Bumpy's feet end here in every picture (measured: 0.938 from the top).
  static const double _feet = .062;

  /// Shadow width and height. The widest costume foot print is 0.59.
  static const double _shadowWidth = .62;
  static const double _shadowHeight = .085;

  /// The hop the shadow answers to, in logical pixels.
  static const double _fullHop = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final side = math.min(sprite, w);
    final rise = side * _crest;
    final drop = math.min(w * .055, rise * .5);

    // A second hill further back, the same paper seen through the air.
    final far = Path()
      ..moveTo(-.15 * w, h)
      ..lineTo(-.15 * w, h - rise * .55)
      ..quadraticBezierTo(.2 * w, h - rise * 1.55, .62 * w, h - rise * .5)
      ..lineTo(.62 * w, h)
      ..close();
    canvas.drawPath(far, Paint()..color = hill.withValues(alpha: .45));

    final crest = Path()
      ..moveTo(0, h - rise + drop)
      ..quadraticBezierTo(w / 2, h - rise - drop, w, h - rise + drop);
    final ground = Path.from(crest)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = hill);
    // The cut edge of the paper catches the light.
    canvas.save();
    canvas.clipPath(ground);
    canvas.drawPath(
      crest,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Color.lerp(hill, const Color(0xFFFFFFFF), night ? .10 : .22)!,
    );
    canvas.restore();

    // The higher the hop, the smaller and fainter the shadow.
    final lift = ((-(hop?.value ?? 0)) / _fullHop).clamp(0.0, 1.0);
    final width = side * _shadowWidth * (1 - .2 * lift);
    final depth = side * _shadowHeight * (1 - .2 * lift);
    final strength = (night ? .6 : .34) * (1 - .35 * lift);
    final radius = width / 2;
    canvas.save();
    canvas.translate(w / 2, h - side * _feet);
    canvas.scale(1, depth / width);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            shadow.withValues(alpha: strength),
            shadow.withValues(alpha: strength * .6),
            shadow.withValues(alpha: 0),
          ],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroundPainter old) =>
      old.hill != hill ||
      old.shadow != shadow ||
      old.night != night ||
      old.sprite != sprite ||
      old.hop != hop;
}
