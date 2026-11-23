# Requirements: Content Packs and Gate

## R1 — ContentRecord model
**WHEN** any baby-voice or app-voice text line is loaded,
**THE SYSTEM SHALL** read it from a `ContentRecord` struct with fields:
`id`, `category` (greeting | thank_you | goodbye), `need` (IRON | BRAIN | BONES | WATER | REST | VITAMIN | ALL),
`mode` (everyday | halloween | both), `tone` (gentle | cheeky | both),
`text`, `status` (draft | needs_fix | approved | rejected),
`approved_by`, `approved_date`.

## R2 — Approval gate
**WHEN** the app renders any line,
**THE SYSTEM SHALL** only use records whose `status == "approved"`.
Any draft, needs_fix, or rejected record must throw a `ContentGateException` if
it reaches the render path.

## R3 — Banned-word gate
**WHEN** any record is loaded,
**THE SYSTEM SHALL** scan its `text` against the full banned-word list from
`voice.md` and reject the record (throw `ContentGateException`) if any match
is found — regardless of `status`.

## R4 — JSON bundle
**WHEN** the app is built,
**THE SYSTEM SHALL** bundle all content under `assets/content/`.
No network fetch, no runtime AI generation, no remote CDN.

## R5 — Planted failure proof
**WHEN** the CI content gate runs,
**THE SYSTEM SHALL** include at least one planted bad record
(banned word, draft status) that demonstrably fails the test,
proving the gate is real and not vacuous.

## R6 — Week coverage
**WHEN** the content gate validates the today-lines pack,
**THE SYSTEM SHALL** confirm every `MaternalNeed` has at minimum
one approved greeting, one approved thank_you, and one approved goodbye line
for each mode (everyday, halloween).
