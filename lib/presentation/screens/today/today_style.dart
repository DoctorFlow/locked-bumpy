part of 'today_screen.dart';

// ── Today's few local pieces ───────────────────────────────────────────────
//
// Type, corners and paper come from the design system (`AppText`, `AppRadii`,
// `PaperCard`). Only what the system does not have yet lives here.

/// Card titles on Today ("Good to know", "For your visit"): the story face,
/// one step under `AppText.title` so a card title never outshouts Bumpy's
/// line. The system has no Fraunces card-title style yet (noted in
/// `roles/apply-a.md`).
final TextStyle _cardTitle = AppText.title.copyWith(
  fontSize: 20,
  height: 26 / 20,
  fontVariations: const [
    FontVariation('opsz', 20),
    FontVariation('wght', 700),
    FontVariation('SOFT', 100),
    FontVariation('WONK', 0),
  ],
);

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
