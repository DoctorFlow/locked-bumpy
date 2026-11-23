# Design: Pause

## PausedScreen layout
```
┌─────────────────────────────┐
│                             │
│          ◯  (still moon)    │
│                             │
│   Everything is paused.     │
│                             │
│   Take all the time you     │
│   need. We are right here   │
│   whenever you are ready.   │
│                             │
│   [ Resume ]                │
│                             │
│   [ Start Fresh ]           │
│   [ Erase all data ]        │
│                             │
└─────────────────────────────┘
```

## Start Fresh dialog
- Title: "Start a fresh day?"
- Body: "Today's check-ins will reset. Your date and nickname stay."
- Buttons: "Yes, start fresh" (accent) | "Never mind" (outline)
- Action: `AppState.clearTodayCheckIns()` → navigate to Today tab, unpause.

## Erase dialog
- Title: "Erase everything?"
- Body: "This removes your date, nickname, and check-ins. It cannot be undone."
- Buttons: "Yes, erase" (destructive red) | "Never mind" (outline)
- Action: `AppState.eraseAll()` → `PrefsService.clearAll()` → back to FirstRun.

## AppState additions needed
```dart
Future<void> clearTodayCheckIns() async { ... }   // clears check-ins, unpauses
Future<void> eraseAll() async { ... }             // clears all prefs, resets state
```

## PrefsService additions needed
```dart
Future<void> clearAll() => _prefs.clear();
```

## Persistence
`isPaused` is already saved to prefs on every toggle.
On cold boot, `AppState.load()` reads `_prefs.isPaused` → if true, main.dart
shows `PausedScreen` immediately. This is already wired; just needs a test.
