# Requirements: This Week Tab

## R1 — Week card display
**WHEN** the This Week tab opens,
**THE SYSTEM SHALL** display the current gestational week (clamped 4–42)
with one approved baby-voice line from `week_cards.json` for that week.

## R2 — Full week range
**WHEN** validating content,
**THE SYSTEM SHALL** confirm every integer week from 4 to 42 inclusive
has at least one approved card in both Everyday and Halloween modes.

## R3 — Navigation
**WHEN** the mother taps the left or right arrow (or swipes),
**THE SYSTEM SHALL** show the adjacent week's card.
Current week is highlighted; she can browse any week 4–42.

## R4 — Size comparisons (app voice only, no clinical measurements)
**WHEN** a size comparison is shown,
**THE SYSTEM SHALL** use an everyday object comparison only
(e.g. "blueberry", "avocado") and never mention centimetres, grams,
or ounces.
Size comparison lines must be approved by Karan before shipping.

## R5 — Parity
**WHEN** switching modes,
**THE SYSTEM SHALL** show an equivalent card for the same week
in the alternate mode palette without any layout change.
