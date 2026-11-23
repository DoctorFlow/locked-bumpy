# Requirements: Closet Sheet

## R1 — Trigger
**WHEN** the mother taps the wardrobe icon in TopBar (Halloween mode only),
**THE SYSTEM SHALL** open the Closet bottom sheet.

## R2 — Six costume previews
**WHEN** the Closet sheet opens,
**THE SYSTEM SHALL** display all 6 costumes as a 2×3 grid:
each card shows the costume PNG (or emoji fallback), the costume name,
and its linked need name.

## R3 — Cosmetic only
**WHEN** a costume is selected in the Closet,
**THE SYSTEM SHALL** update the avatar display only — it must NOT change
the Need of the Day or affect the check-in tiles.

## R4 — Override cleared on new day
**WHEN** a new day starts,
**THE SYSTEM SHALL** clear any costume override and revert to today's need avatar.
(Override is in-memory only — not persisted.)

## R5 — Parity
**WHEN** in Everyday mode,
**THE SYSTEM SHALL** hide the Closet trigger icon (onesie has no costume variants).
The sheet feature exists only in Halloween mode.

## R6 — Paused immunity
**WHEN** the app is paused,
**THE SYSTEM SHALL** not show the Closet trigger icon.
