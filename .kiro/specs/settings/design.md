# Design: Settings Screen

## Layout
```
┌─────────────────────────────┐
│  ← Settings                  │
│                              │
│  Little Bumpy  v1.0.0        │
│                              │
│  ─────── Appearance ───────  │
│  Look:  [ Everyday | 🎃 ]   │  ← reuses _SegmentToggle from onboarding
│                              │
│  ─────── Privacy ──────────  │
│  "No data ever leaves your   │
│   phone. No accounts.        │
│   No tracking. No ads."      │
│                              │
│  ─────── Medical ──────────  │
│  "This app is not medical    │
│   advice. If you are worried │
│   about anything, call your  │
│   doctor."                   │
│                              │
│  ─────── Data ─────────────  │
│  [ Erase all data ]          │  ← destructive, outlined red
│                              │
└─────────────────────────────┘
```

## Implementation notes
- Stateless `SettingsScreen` widget; reads `AppState` via constructor.
- Mode toggle calls `state.toggleMode()` — same code path as lamp button.
- Erase calls `state.eraseAll()` with confirmation dialog (reuse from PausedScreen).
- Version string: read from `pubspec.yaml` via `package_info_plus` or hardcoded constant.
  For Rung 3 scope: hardcode `'v1.0.0'` in AppConstants to avoid extra dependency.
- Access point: add a small gear `IconButton` to `TopBar` (right side, next to pause).

## AppConstants addition
```dart
static const String appVersion = 'v1.0.0';
static const String privacyStatement =
    'No data ever leaves your phone. No accounts. No tracking. No ads.';
```
