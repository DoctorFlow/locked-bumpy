---
inclusion: always
---
# Technical Steering

## Environment & Tooling
- **Framework:** Flutter 3.44.4+
- **Language:** Dart 3.12.2+
- **Platforms:** Android (APK / AAB) and Web (`--no-web-resources-cdn`).
- **Dependencies:**
  - `flutter_svg`: Vector graphics rendering for paper-doll baby & icons.
  - `kiri_check`: Property-based testing engine.
- **Strict Network Isolation:**
  - Zero external HTTP requests at runtime.
  - No analytics SDKs, no ad trackers, no remote font fetching at runtime.
  - All fonts, assets, and content records are bundled directly with the application.
