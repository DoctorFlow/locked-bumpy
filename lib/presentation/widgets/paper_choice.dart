import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/theme/paper.dart';

/// A paper control with a visible keyboard focus ring and a single spoken label.
///
/// The touch target is never smaller than 48 x 48: a smaller [child] keeps its
/// own size and is centred in the target. The caller draws the selected state
/// (an accent edge or fill plus a tick, never colour alone); [selected] is
/// what a screen reader hears.
class PaperChoice extends StatefulWidget {
  const PaperChoice({
    super.key,
    required this.label,
    required this.onTap,
    required this.focusColor,
    required this.borderRadius,
    required this.child,
    this.selected,
    this.liveRegion = false,
  });

  final String label;
  final VoidCallback onTap;
  final Color focusColor;
  final BorderRadius borderRadius;
  final Widget child;
  final bool? selected;
  final bool liveRegion;

  @override
  State<PaperChoice> createState() => PaperChoiceState();
}

class PaperChoiceState extends State<PaperChoice> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      selected: widget.selected,
      liveRegion: widget.liveRegion,
      child: InkWell(
        onTap: widget.onTap,
        onFocusChange: (focused) => setState(() => _focused = focused),
        borderRadius: widget.borderRadius,
        child: DecoratedBox(
          // Paint the ring over paper-colored cards and segment backgrounds.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: _focused
                ? Border.all(color: widget.focusColor, width: 3)
                : null,
          ),
          child: _MinimumTarget(child: ExcludeSemantics(child: widget.child)),
        ),
      ),
    );
  }
}

/// Grows to at least [AppSpace.target] on each side and centres its child,
/// without changing the constraints the child is laid out with.
class _MinimumTarget extends SingleChildRenderObjectWidget {
  const _MinimumTarget({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinimumTarget();
}

class _RenderMinimumTarget extends RenderShiftedBox {
  _RenderMinimumTarget() : super(null);

  static const double _side = AppSpace.target;

  Size _sizeFor(BoxConstraints constraints, Size child) =>
      constraints.constrain(
        Size(math.max(child.width, _side), math.max(child.height, _side)),
      );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_side, super.computeMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(_side, super.computeMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_side, super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_side, super.computeMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _sizeFor(constraints, child?.getDryLayout(constraints) ?? Size.zero);

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    final distance = child?.getDryBaseline(constraints, baseline);
    if (child == null || distance == null) return null;
    final childSize = child.getDryLayout(constraints);
    return distance +
        (_sizeFor(constraints, childSize).height - childSize.height) / 2;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = _sizeFor(constraints, Size.zero);
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }
}
