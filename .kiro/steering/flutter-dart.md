---
inclusion: fileMatch
fileMatch: "lib/**/*.dart"
---
# Flutter & Dart Steering

## Coding Rules
- Follow Flutter standard idioms and lint rules in `analysis_options.yaml`.
- Prefer `const` constructors wherever possible for widget trees.
- State management: Lightweight, pure state models (e.g. `ValueNotifier` or simple `ChangeNotifier`). No heavy third-party state frameworks needed for this scope.
- Theme: Use `ThemeExtension` or custom `AppPalette` token container so widgets query `AppPalette.of(context)` rather than checking `isHalloween`.
- Motion: Respect `MediaQuery.disableAnimationsOf(context)` across all animated widgets.
- Touch Targets: Minimum 48x48 dp for all interactive elements.
