# Tasks: Baby Paper Doll Avatar

## Rung 3 (due Fri 27 Nov)
- [x] 1. Prototype baby character container (emoji placeholder in TodayScreen)
- [ ] 2. Register `assets/images/` and `assets/content/` in `pubspec.yaml`
- [ ] 3. Create `BabyAvatar` widget in `lib/presentation/widgets/baby_avatar.dart`
       — reads `palette.isHalloween` and `need` to pick correct PNG asset
       — `hopAnimation` optional param wired to existing AnimationController
       — `Image.asset` with error-builder emoji fallback
       — respects `MediaQuery.disableAnimationsOf`
- [ ] 4. Replace emoji placeholder in `TodayScreen._buildBabyAvatar` with `BabyAvatar`
- [ ] 5. Add widget test: BabyAvatar renders Image.asset (not emoji) when assets are present

## Rung 4 (due Sun 29 Nov)
- [ ] 6. Add `BabyAvatar` to `ThisWeekScreen` card header (Rung 4 — after week cards exist)
