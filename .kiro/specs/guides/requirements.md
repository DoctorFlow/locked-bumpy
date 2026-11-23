# Requirements: Guides Tab

## R1 — App voice only
**WHEN** the Guides tab is open,
**THE SYSTEM SHALL** use App Voice throughout — calm, neutral, unadorned.
No baby first-person narration on this tab.

## R2 — Six guide cards
**WHEN** the Guides tab renders,
**THE SYSTEM SHALL** display one card per maternal need:
Iron, Brain (Omega-3 / folate), Bones, Water, Rest, Vitamin.

## R3 — Physician-approved content
**WHEN** clinical amounts or specific foods are shown,
**THE SYSTEM SHALL** conclude with "Your doctor decides the amount."
All guide bodies must have `status == "approved"` and `approved_by == "Karan"`.

## R4 — Questions to ask section
**WHEN** a guide card is expanded,
**THE SYSTEM SHALL** show a "Questions to ask your doctor" list,
framing every item as a question for the mother to raise at her next visit.
No imperatives, no doses, no "you should".

## R5 — Disclaimer
**WHEN** the Guides tab renders,
**THE SYSTEM SHALL** show the standard disclaimer at the bottom:
"This app is not medical advice. If you are worried about anything, call your doctor."

## R6 — Parity
**WHEN** switching modes,
**THE SYSTEM SHALL** render the same card structure and content
in both Everyday and Halloween palettes.
