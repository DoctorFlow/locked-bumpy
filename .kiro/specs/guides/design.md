# Design: Guides Tab

## GuideArticle model
```dart
class GuideArticle {
  final String need;         // 'IRON' | 'BRAIN' | 'BONES' | 'WATER' | 'REST' | 'VITAMIN'
  final String title;        // e.g. 'Iron'
  final String body;         // 2–3 sentences, App Voice, no banned words
  final List<String> questions; // questions to ask physician
  final String status;       // 'approved'
  final String approvedBy;   // 'Karan'
  final String approvedDate;
}
```

Stored in `assets/content/guide_articles.json`.

## GuidesScreen layout
```
┌─────────────────────────────┐
│  Physician Guides            │
│                              │
│  ┌────────────────────────┐  │
│  │ 🔴 Iron                │  │
│  │ Body text 2–3 sentences│  │
│  │ Your doctor decides... │  │
│  │ [Questions ▼]          │  │
│  └────────────────────────┘  │
│  ┌────────────────────────┐  │
│  │ 🟢 Brain / Folate      │  │
│  │ ...                    │  │
│  └────────────────────────┘  │
│  ...×6                       │
│                              │
│  This app is not medical...  │
└─────────────────────────────┘
```

- `ListView` of `ExpansionTile`-based cards.
- Colour dot = `AppPalette.needXxx` colour for the need.
- Questions section expands/collapses; default closed.
- No network calls; content loaded via `ContentLoader` from bundled JSON.
