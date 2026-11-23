# Tasks: Costumes & Halloween Mode

## Rung 1 (complete)
- [x] 1. Implement theme token switching and lamp toggle icon

## Rung 3 (due Fri 27 Nov) — Minimum Complete Entry
- [ ] 2. Add `MaternalNeed.assetPath(AppPalette)` helper to `need.dart`
- [ ] 3. Register assets in pubspec.yaml (blocked by baby-paper-doll task 2)
- [ ] 4. Build `BabyAvatar` widget with PNG rendering + emoji fallback (baby-paper-doll task 3)
- [ ] 5. Replace emoji placeholder in `TodayScreen` with `BabyAvatar`
- [ ] 6. Add `AnimatedSwitcher` on avatar for lamp-switch cross-fade
- [ ] 7. Parity test: Halloween TodayScreen InkWell count == Everyday TodayScreen InkWell count (already passing — verify still passes after PNG swap)

## Rung 4 (due Sun 29 Nov)
- [ ] 8. All 6 costume PNGs rendering (Ghost, Skeleton, Zombie added in Rung 3; verify Ghost + Skeleton + Zombie look correct)
- [ ] 9. Add `costumeOverride` nullable field to `AppState` (in-memory only, not persisted)
- [ ] 10. Build `ClosetSheet` bottom sheet (2×3 grid of costume cards)
- [ ] 11. Wire Closet trigger button to `TopBar`
