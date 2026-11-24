part of 'today_screen.dart';

// ── Local type, corners and paper for Today ────────────────────────────────
//
// These mirror `specs/DESIGN.md` (`AppText`, `AppRadii`, `PaperCard`) so
// Today already looks right before the look lane's theme files reach this
// branch. When they do, swap each `_T.x` for `AppText.x` and `_paper(...)`
// for `PaperCard`; the values are the same.

abstract final class _T {
  /// Bumpy's first-person line (Fraunces 600 once bundled).
  static const bumpy = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w600,
  );
  static const heading = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );
  static const bodyStrong = TextStyle(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(fontSize: 16, height: 24 / 16);
  static const small = TextStyle(fontSize: 14, height: 20 / 14);
  static const label = TextStyle(
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w700,
    letterSpacing: .3,
  );
}

/// Hand-cut corners: top-left, top-right, bottom-right, bottom-left.
const _cardCorners = BorderRadius.only(
  topLeft: Radius.circular(20),
  topRight: Radius.circular(15),
  bottomRight: Radius.circular(21),
  bottomLeft: Radius.circular(13),
);
const _controlCorners = BorderRadius.only(
  topLeft: Radius.circular(13),
  topRight: Radius.circular(10),
  bottomRight: Radius.circular(14),
  bottomLeft: Radius.circular(9),
);
const _tagCorners = BorderRadius.only(
  topLeft: Radius.circular(9),
  topRight: Radius.circular(7),
  bottomRight: Radius.circular(10),
  bottomLeft: Radius.circular(6),
);

Color _edge(AppPalette p) =>
    p.isHalloween ? const Color(0xFF4A3A60) : const Color(0xB3FFFFFF);
Color _shadow(AppPalette p) =>
    p.isHalloween ? const Color(0xFF05030A) : const Color(0xFF170F21);

/// A card on the page, or (raised) a piece lying on a card.
BoxDecoration _paper(AppPalette p, {bool raised = false}) => BoxDecoration(
  color: raised ? p.paperRaised : p.paper,
  borderRadius: raised ? _controlCorners : _cardCorners,
  border: Border.all(color: _edge(p)),
  boxShadow: [
    BoxShadow(
      color: _shadow(p).withValues(alpha: p.isHalloween ? 1 : .45),
      offset: const Offset(0, 2),
    ),
    if (!raised)
      BoxShadow(
        color: _shadow(p).withValues(alpha: p.isHalloween ? .45 : .22),
        offset: const Offset(0, 8),
        blurRadius: 14,
      ),
  ],
);

/// A paper card that clips its child to the hand-cut corners.
class _PaperCard extends StatelessWidget {
  const _PaperCard({
    super.key,
    required this.palette,
    required this.child,
    this.raised = false,
  });

  final AppPalette palette;
  final Widget child;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _paper(palette, raised: raised),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: raised ? _controlCorners : _cardCorners,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

/// Sentence-case name of a need, for the app's own voice.
String _needWord(MaternalNeed need) => switch (need) {
  MaternalNeed.vitamin => 'Prenatal vitamin',
  _ => need.label,
};

/// Sentence-case costume name ("Vampire").
String _costumeWord(MaternalNeed need) =>
    need.costume[0] + need.costume.substring(1).toLowerCase();

/// Check-in hint for the parent. Only the vitamin line differs from the
/// shared food hint, so it says "doctor or midwife".
String _checkInHint(MaternalNeed need) => need == MaternalNeed.vitamin
    ? 'The vitamin your doctor or midwife chose'
    : need.foodHint;
