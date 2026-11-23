# Requirements: Baby Paper Doll Avatar

## R1 — Asset-driven rendering
**WHEN** the baby avatar is shown,
**THE SYSTEM SHALL** render it using the PNG assets from `assets/images/`
(everyday.png, body-vampire.png, body-mummy.png, body-witch.png,
body-ghost.png, body-skeleton.png, body-zombie.png).

## R2 — Mode-driven swap (no boolean branch)
**WHEN** mode changes via the lamp,
**THE SYSTEM SHALL** swap the displayed image by reading `AppPalette.isHalloween`
and `AppState.todayNeed` — not by branching on a raw boolean in the widget.

## R3 — Hop animation compatibility
**WHEN** the need-of-the-day check-in is ticked,
**THE SYSTEM SHALL** apply the existing hop `Transform.translate` animation
to the composed avatar widget, not just the emoji placeholder.

## R4 — Reduce-motion respect
**WHEN** `MediaQuery.disableAnimationsOf(context)` is true,
**THE SYSTEM SHALL** show the avatar statically with zero transform.

## R5 — Paused immunity
**WHEN** the app is paused,
**THE SYSTEM SHALL** render no avatar image or emoji — only the still moon mark.

## R6 — Fallback
**WHEN** an asset file fails to load (corrupt build),
**THE SYSTEM SHALL** fall back to the emoji placeholder without crashing.
