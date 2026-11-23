# Requirements: Pause

## R1 — Instant silence
**WHEN** the Pause icon is tapped from any screen,
**THE SYSTEM SHALL** immediately stop all baby speech, animations, counters,
and costume images. The transition must be synchronous — no fade delay.

## R2 — Neutral screen
**WHEN** paused,
**THE SYSTEM SHALL** display only: a small still moon mark, a single calm
sentence in App Voice, and the action buttons.
No baby avatar, no costume, no check-ins, no week number, no progress
of any kind.

## R3 — Compassionate tone
**WHEN** paused,
**THE SYSTEM SHALL** never display "sorry", "we miss you", guilt wording,
or ask the reason for pausing.

## R4 — Resume
**WHEN** the mother taps Resume,
**THE SYSTEM SHALL** restore the app to the same tab and state as before
pausing.

## R5 — Start Fresh
**WHEN** the mother taps Start Fresh,
**THE SYSTEM SHALL** show a confirmation dialog, then clear today's
check-in state only (not the due date or nickname) and return to Today tab.

## R6 — Erase
**WHEN** the mother taps Erase,
**THE SYSTEM SHALL** show a confirmation dialog, then clear all stored data
(due date, nickname, mode, check-ins) and return to the First Run screen.

## R7 — Persistence
**WHEN** the app is force-closed while paused,
**THE SYSTEM SHALL** reopen in the Paused screen on cold boot.
