# Camera: photograph the real web app

Run from the repo root (any shell, normal user):

    python tool/camera/shoot.py --out <folder> [--skip-build] [--only today-fresh,guides]

- Builds `flutter build web --release --no-web-resources-cdn` with the pinned SDK, so CanvasKit and fonts come from `build/web`. `--skip-build` reuses the last build.
- Serves `build/web` on a free 127.0.0.1 port inside the script and blocks every request to any other host (listed in `manifest.json` under `blocked_requests`), so a good picture proves the renderer works offline.
- Drives headless Chromium through Playwright (falls back to installed Edge). Each shot is a fresh browser context at the phone size and device scale (320x568@2, 375x812@3, 412x915@2.625), with reduced motion.
- How state is seeded: `shared_preferences` on web stores `localStorage["flutter.<key>"] = JSON(value)`. An init script clears localStorage and writes the keys from `lib/core/constants/app_constants.dart` before Flutter starts: `is_halloween` (look), `due_date_iso` = 2027-03-15 (week 24; left out for the welcome screen), `skin_tone`, `baby_nickname`, `is_paused`, `daily_needs_v2` = `["2026-11-23", "iron", ...]` for ticked check-ins, `visit_topics` = `["iron"]`.
- The clock is fixed at 2026-11-23 12:00 (Playwright `clock.set_fixed_time`), rotation day 0: IRON, the vampire costume.
- Navigation: clicks Flutter's hidden `flt-semantics-placeholder` to turn on the accessibility tree, then taps semantic nodes by role and name (`This Week` tab, `Wardrobe`, `Settings`, `Iron`, `Edit visit list`).
- Output: `<screen>__<look>__<WxH@scale>.png`, Bumpy and wardrobe-thumbnail crops at native pixels plus `__x2` nearest-neighbour copies, `sheet__halloween.png` / `sheet__everyday.png` (375 size), and `manifest.json` (state, size, ok/error per shot).
- The wardrobe has no Everyday version; those three shots are marked "not applicable", not failed.
- Add a screen by appending to `SCREENS` in `shoot.py`: name, extra prefs, and a list of (role, accessible name) taps.
