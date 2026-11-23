# Spec: Pause

## Requirements
1. **WHEN** the mother taps the Pause icon on any screen, **THE SYSTEM SHALL** immediately silence all baby speech, animations, and counters.
2. **WHEN** paused, **THE SYSTEM SHALL** display only a compassionate neutral message in App Voice with a small still moon.
3. **WHEN** paused, **THE SYSTEM SHALL** never display "sorry", guilt messages, or ask why the user paused.
4. **WHEN** paused, **THE SYSTEM SHALL** provide Resume, Start Fresh, and Erase options.

## Tasks
- [x] 1. Implement basic Paused view with neutral message and Resume button
- [ ] 2. Implement Start Fresh and Erase options
- [ ] 3. Ensure persistent paused state survives app restart
