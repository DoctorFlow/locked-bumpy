# Tasks: Master Hackathon Plan
> One line per deliverable. Owner spec linked. Update [x] as each lands.

---

## ✅ Rung 1 — Mon 23 Nov — Hello, Baby (DONE)

- [x] Flutter project + Android + Web targets
- [x] AppPalette tokens (Everyday + Halloween)
- [x] PregnancyCalculator (LMP / due date → week 4–42)
- [x] AppState ChangeNotifier + PrefsService
- [x] NeedRotation 6-day deterministic cycle
- [x] FirstRunScreen 3-step onboarding (date, nickname, look)
- [x] TodayScreen full daily loop (3 check-ins, hop animation, day-boundary reset)
- [x] PausedScreen (Resume button, moon mark)
- [x] TopBar + AppNavBar
- [x] Lamp toggle (Everyday ↔ Halloween)
- [x] Content gate unit tests
- [x] GitHub Actions CI
- [x] dart-check + content-check hooks
- [x] 26 tests, 0 failures

---

## 🔲 Rung 2 — Wed 25 Nov — Everyday Core

### Content system (spec: content-packs-and-gate)
- [ ] `ContentRecord` Dart model
- [ ] `ContentGateException` + validator
- [ ] `assets/content/today_lines.json` (36 approved lines: 6 needs × 3 categories × 2 modes)
- [ ] `ContentLoader` service (rootBundle, offline)
- [ ] Register `assets/content/` in pubspec.yaml
- [ ] Wire TodayScreen to ContentLoader
- [ ] Upgrade content_gate_test to load real JSON
- [ ] Update content-check hook

### This Week tab (spec: this-week)
- [ ] `WeekCard` model
- [ ] `assets/content/week_cards.json` (weeks 4–42, all approved)
- [ ] ThisWeekScreen PageView with arrows
- [ ] Property test: every week 4–42 has an approved card

### Pause (spec: pause)
- [ ] `AppState.clearTodayCheckIns()`
- [ ] `AppState.eraseAll()` + `PrefsService.clearAll()`
- [ ] Start Fresh button + dialog
- [ ] Erase button + dialog
- [ ] Cold-boot persistence test

---

## 🔲 Rung 3 — Fri 27 Nov — Costume Proof (Minimum Complete Entry)

### Baby avatar PNG (spec: baby-paper-doll)
- [ ] Register `assets/images/` in pubspec.yaml
- [ ] `BabyAvatar` widget (PNG + emoji fallback + hop animation)
- [ ] Replace emoji placeholder in TodayScreen

### Costumes (spec: costumes-halloween)
- [ ] `MaternalNeed.assetPath(AppPalette)` helper
- [ ] Vampire, Mummy, Witch PNGs rendering
- [ ] AnimatedSwitcher on avatar for lamp-switch cross-fade
- [ ] Parity test still green

### Settings (spec: settings)
- [ ] `AppConstants.appVersion` + `AppConstants.privacyStatement`
- [ ] `SettingsScreen` widget
- [ ] Gear icon in TopBar
- [ ] Settings widget test

---

## 🔲 Rung 4 — Sun 29 Nov — Feature Freeze

### Costumes complete (spec: costumes-halloween)
- [ ] Ghost, Skeleton, Zombie PNGs rendering

### Closet Sheet (spec: closet-sheet)
- [ ] `AppState.costumeOverride` + `setCostumeOverride()`
- [ ] `ClosetSheet` widget (2×3 grid)
- [ ] Wardrobe icon in TopBar (Halloween only)
- [ ] Closet tests

### Guides tab (spec: guides)
- [ ] `GuideArticle` model
- [ ] `assets/content/guide_articles.json` (Karan approved, 6 articles)
- [ ] GuidesScreen with 6 expanded cards + questions + disclaimer
- [ ] Parity test

### Days Together counter
- [ ] `AppState.daysTogetherCount` (derived from due date, never stored separately)
- [ ] Display in TopBar or Today card

### Release
- [ ] Tag `v1.0-rc`

---

## 🔲 Rung 5 — Tue 1 Dec — Polish

- [ ] Reduce-motion audit: every animated widget checked
- [ ] Contrast audit: every text/bg pair ≥ 4.5:1 verified
- [ ] Web layout test: 440px constrained, no CDN assets
- [ ] Final asset polish (Harshy + Rachel sign-off)
- [ ] 2:45 submission video recorded (Rachel's POV)
- [ ] Devpost draft written

---

## 🔲 Rung 6 — Thu 3 Dec 9 PM IST — Submit

- [ ] Final `flutter test` clean pass
- [ ] Final `flutter analyze` clean pass
- [ ] APK / AAB built + attached to Devpost
- [ ] Web build deployed (if applicable)
- [ ] Rachel presses Submit on Devpost
