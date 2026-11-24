import '../../domain/models/need.dart';

/// The need as a parent reads it, in sentence case: "Iron", "Brain", "Bones",
/// "Water", "Rest", "Prenatal vitamin". One helper for Today, the wardrobe,
/// Guides and the visit list, so the word is the same everywhere.
String needWord(MaternalNeed need) =>
    need == MaternalNeed.vitamin ? 'Prenatal vitamin' : need.label;
