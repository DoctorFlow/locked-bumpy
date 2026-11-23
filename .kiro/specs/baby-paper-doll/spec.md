# Spec: Baby Paper Doll Vector Avatar

## Requirements
1. **WHEN** rendering the baby avatar, **THE SYSTEM SHALL** compose transparent vector SVG parts on a 512x512 artboard in painter's order (shadow, halo, body, outfit, head, face, costume).
2. **WHEN** an outfit or costume is swapped, **THE SYSTEM SHALL** preserve the exact face zone bounds and anchors.
3. **WHEN** paused, **THE SYSTEM SHALL** render zero baby avatar elements.

## Tasks
- [x] 1. Prototype baby character container in `lib/main.dart`
- [ ] 2. Create `BabyAvatarComposer` widget using `flutter_svg`
- [ ] 3. Map costume vector layers from assets
