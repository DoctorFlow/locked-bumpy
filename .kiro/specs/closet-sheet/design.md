# Design: Closet Sheet

## Trigger placement
`TopBar` — when `palette.isHalloween`, show a 👗 `IconButton` between the
lamp and pause buttons.

## Sheet layout
```
┌─────────────────────────────┐
│  Tonight's Wardrobe 👗       │
│                              │
│  ┌────────┐  ┌────────┐     │
│  │ 🧛     │  │ 🧟     │     │
│  │Vampire │  │ Zombie │     │
│  │ IRON   │  │ BRAIN  │     │
│  └────────┘  └────────┘     │
│  ┌────────┐  ┌────────┐     │
│  │ 💀     │  │ 🩹     │     │
│  │Skeleton│  │ Mummy  │     │
│  │ BONES  │  │ WATER  │     │
│  └────────┘  └────────┘     │
│  ┌────────┐  ┌────────┐     │
│  │ 👻     │  │ 🧙     │     │
│  │ Ghost  │  │ Witch  │     │
│  │  REST  │  │VITAMIN │     │
│  └────────┘  └────────┘     │
└─────────────────────────────┘
```

## AppState change needed
```dart
MaternalNeed? _costumeOverride;    // in-memory only, never persisted
MaternalNeed? get costumeOverride => _costumeOverride;

void setCostumeOverride(MaternalNeed? need) {
  _costumeOverride = need;
  notifyListeners();
}
```

## TodayScreen change
Avatar reads `state.costumeOverride ?? state.todayNeed` for the image.
Check-in tiles always use `state.todayNeed` — override never touches them.

## ClosetSheet widget
```dart
class ClosetSheet extends StatelessWidget {
  const ClosetSheet({super.key, required this.state});
  final AppState state;
}
```
Called via `showModalBottomSheet(context: context, builder: (_) => ClosetSheet(state: state))`.
