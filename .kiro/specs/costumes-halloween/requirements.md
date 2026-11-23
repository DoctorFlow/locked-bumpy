# Requirements: Costumes & Halloween Mode

## R1 — Lamp toggle drives palette only
**WHEN** the lamp is toggled,
**THE SYSTEM SHALL** switch `AppPalette` via `AppState.toggleMode()`.
No widget may branch on a raw `isHalloween` boolean — all branching
must happen through `AppPalette.of(context)`.

## R2 — Six costume images
**WHEN** in Halloween mode,
**THE SYSTEM SHALL** display the PNG asset that matches today's `MaternalNeed`:
Vampire (IRON), Mummy (WATER), Witch (VITAMIN),
Ghost (REST), Skeleton (BONES), Zombie (BRAIN).

## R3 — Everyday onesie
**WHEN** in Everyday mode,
**THE SYSTEM SHALL** display `assets/images/everyday.png` regardless of need.

## R4 — 100% interactive parity
**WHEN** switching modes,
**THE SYSTEM SHALL** keep identical screen structure, check-in count,
button positions, and touch targets. Only colors, images, and text change.

## R5 — Closet sheet (Rung 4)
**WHEN** the mother opens the Closet sheet,
**THE SYSTEM SHALL** display all 6 costume options and allow her to preview
them without changing today's actual check-in need.
Closet selection is cosmetic only — it does not change the Need of the Day.
