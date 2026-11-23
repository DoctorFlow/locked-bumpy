# Design: Costumes & Halloween Mode

## Costume → Need → Asset map
| Emoji | Costume | Need | Asset |
|---|---|---|---|
| 🧛 | Vampire | IRON | `assets/images/body-vampire.png` |
| 🧟 | Zombie | BRAIN | `assets/images/body-zombie.png` |
| 💀 | Skeleton | BONES | `assets/images/body-skeleton.png` |
| 🩹 | Mummy | WATER | `assets/images/body-mummy.png` |
| 👻 | Ghost | REST | `assets/images/body-ghost.png` |
| 🧙 | Witch | VITAMIN | `assets/images/body-witch.png` |
| 👶 | Onesie | (any, Everyday) | `assets/images/everyday.png` |

## MaternalNeed.assetPath helper (add to need.dart)
```dart
String assetPath(AppPalette palette) {
  if (!palette.isHalloween) return 'assets/images/everyday.png';
  return switch (this) {
    MaternalNeed.iron    => 'assets/images/body-vampire.png',
    MaternalNeed.brain   => 'assets/images/body-zombie.png',
    MaternalNeed.bones   => 'assets/images/body-skeleton.png',
    MaternalNeed.water   => 'assets/images/body-mummy.png',
    MaternalNeed.rest    => 'assets/images/body-ghost.png',
    MaternalNeed.vitamin => 'assets/images/body-witch.png',
  };
}
```

## Lamp switch animation
- `AnimatedTheme` wraps `MaterialApp` to lerp between palette tokens over 300ms.
- Avatar image cross-fades via `AnimatedSwitcher(duration: 300ms)` keyed on asset path.
- Lamp icon: `Icons.lightbulb` (on/Everyday) ↔ `Icons.lightbulb_outline` (off/Halloween).

## Closet Sheet (Rung 4)
- `ModalBottomSheet` triggered from a small wardrobe `IconButton` in `TopBar`.
- Shows a 2×3 grid of costume preview cards (name + emoji + color swatch).
- Tapping a card sets `AppState.costumeOverride` (cosmetic, does not affect `todayNeed`).
- State: `costumeOverride` is in-memory only (not persisted); resets on app restart.
