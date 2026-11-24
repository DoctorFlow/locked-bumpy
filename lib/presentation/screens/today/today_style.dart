part of 'today_screen.dart';

// ── Today's few local pieces ───────────────────────────────────────────────
//
// Type, corners and paper come from the design system (`AppText`, `AppRadii`,
// `PaperCard`). Only what the system does not have yet lives here.

/// Card titles on Today ("Good to know", "For your visit"): the app's own
/// face (Atkinson Bold 18/24). Fraunces is kept for Bumpy's line, so only
/// Bumpy talks in the big serif (design critique 2, fix 2).
const TextStyle _cardTitle = AppText.heading;

/// A small paper tag lying on a card: raised paper, tag corners, lit edge.
BoxDecoration _paperTag(AppPalette p) => BoxDecoration(
  color: p.paperRaised,
  borderRadius: AppRadii.tag,
  border: Border.all(color: p.edge),
  boxShadow: paperShadows(p, raised: true),
);

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
