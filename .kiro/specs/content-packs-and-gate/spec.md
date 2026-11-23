# Spec: Content Packs and Gate

## Requirements
1. **WHEN** the application loads any text line, **THE SYSTEM SHALL** read it from a structured ContentRecord model.
2. **WHEN** content records are verified, **THE SYSTEM SHALL** only display records whose status is strictly `approved`.
3. **WHEN** a record contains any forbidden word from the banned list (guilt, harm, maternal body, kick/movement, death/undead, potion), **THE SYSTEM SHALL** reject the record during CI and hook runs.
4. **WHEN** a planted bad record is tested, **THE SYSTEM SHALL** demonstrably fail the gate test to prove gate legitimacy.

## Design
- `ContentRecord` domain model in Dart.
- Banned-words filter matching regex in `tool/` and `test/unit/content_gate_test.dart`.
- Content files bundled under `assets/content/`.

## Tasks
- [x] 1. Define initial Content Gate unit tests
- [ ] 2. Create `ContentRecord` class with id, need, category, mode, status, and approved_by
- [ ] 3. Create JSON content loader service with offline asset caching
- [ ] 4. Connect `content-check` hook to verify all shipped JSON packs
