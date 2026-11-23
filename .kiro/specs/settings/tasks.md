# Tasks: Settings Screen

## Rung 3 (due Fri 27 Nov)
- [ ] 1. Add `AppConstants.appVersion` and `AppConstants.privacyStatement`
- [ ] 2. Create `SettingsScreen` widget in `lib/presentation/screens/settings_screen.dart`
         — app name + version, mode toggle, privacy statement, disclaimer, Erase button
- [ ] 3. Add gear `IconButton` to `TopBar` → pushes `SettingsScreen` via `Navigator.push`
- [ ] 4. Wire Erase button to `state.eraseAll()` with confirmation dialog
         (reuse dialog code from PausedScreen)
- [ ] 5. Widget test: Settings shows version string, disclaimer, and privacy statement

## Rung 5 (due Tue 1 Dec)
- [ ] 6. Verify Settings parity (Everyday == Halloween element count)
