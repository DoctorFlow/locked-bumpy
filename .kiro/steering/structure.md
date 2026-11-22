---
inclusion: always
---
# Architecture & Structure Steering

## Project Layout
```
lib/
├── core/
│   ├── constants/       # Fixed strings, limits, dates
│   ├── theme/           # Night nursery tokens (Everyday & Halloween)
│   └── utils/           # Date calculations, formatting
├── domain/
│   ├── models/          # ContentRecord, Need, Costume, CheckInState
│   └── pregnancy.dart   # Due date & gestational week logic
├── presentation/
│   ├── screens/         # FirstRun, Today, ThisWeek, Guides, Settings, Paused
│   ├── widgets/         # BabyAvatar, CheckInCard, LampSwitch, AppNavBar
│   └── sheets/          # ClosetSheet
└── content/             # Bundled JSON/records and ContentLoader
test/
├── property/            # kiri_check property tests
├── unit/                # Gestational week, content gate, parser tests
└── widget/              # Screen parity and mode switch tests
```
