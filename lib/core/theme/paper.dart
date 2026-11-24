import 'package:flutter/material.dart';
import 'palette.dart';

/// The seven spacing steps. Nothing in between.
abstract final class AppSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Side margin of every screen, and the padding inside a card.
  static const double page = l;

  /// The smallest touch target, and the smallest row.
  static const double target = 48;
  static const double row = 56;
}

/// Hand-cut corners: slightly uneven, like paper cut with scissors.
/// Order is top-left, top-right, bottom-right, bottom-left.
abstract final class AppRadii {
  /// Cards and dialogs.
  static const BorderRadius card = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(15),
    bottomRight: Radius.circular(21),
    bottomLeft: Radius.circular(13),
  );

  /// Buttons, inputs, rows and the tab marker.
  static const BorderRadius control = BorderRadius.only(
    topLeft: Radius.circular(13),
    topRight: Radius.circular(10),
    bottomRight: Radius.circular(14),
    bottomLeft: Radius.circular(9),
  );

  /// Tags, chips and tooltips.
  static const BorderRadius tag = BorderRadius.only(
    topLeft: Radius.circular(9),
    topRight: Radius.circular(7),
    bottomRight: Radius.circular(10),
    bottomLeft: Radius.circular(6),
  );

  /// The top of a bottom sheet.
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(18),
  );
}

/// The shadow a paper piece casts: a hard edge right under it and, for a card
/// on the page, a soft one further down. One lamp, top left.
List<BoxShadow> paperShadows(AppPalette p, {bool raised = false}) => [
  BoxShadow(
    color: p.shadow.withValues(alpha: p.isHalloween ? 1 : .45),
    offset: const Offset(0, 2),
  ),
  if (!raised)
    BoxShadow(
      color: p.shadow.withValues(alpha: p.isHalloween ? .45 : .22),
      offset: const Offset(0, 8),
      blurRadius: 14,
    ),
];

/// One piece of cut paper: a card on the page, or with [raised] a smaller
/// piece lying on a card. Ink, taps and clipping work inside it.
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.raised = false,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;

  /// A piece on a card: raised paper, control corners, hard shadow only.
  final bool raised;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final corners = raised ? AppRadii.control : AppRadii.card;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: raised ? p.paperRaised : p.paper,
        borderRadius: corners,
        boxShadow: paperShadows(p, raised: raised),
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: corners,
          border: Border.all(color: p.edge),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: corners,
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
