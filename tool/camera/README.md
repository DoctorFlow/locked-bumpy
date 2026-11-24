# Camera: photograph the real web app

Any shell (Windows PowerShell or bash), normal user. Run from any folder:

    python tool/camera/shoot.py --out <folder> [--app <checkout>] [--review] [--fast]
                                [--week N] [--skip-build] [--only name [name ...]] [--list]

| Flag | What it does |
|---|---|
| `--out` | Folder for the PNGs, contact sheets and `manifest.json`. |
| `--app <path>` | Checkout or worktree to photograph. Default: the one this script lives in. The build lands in `<app>/build/web`; delete it afterwards. |
| `--review` | `flutter build web --profile --dart-define=BUMPY_REVIEW=true` instead of `--release`, so draft text shows. The manifest records `"build": "profile+review"` or `"release"`. |
| `--fast` | Only 375x812@3, both looks (default: 320x568@2, 375x812@3, 412x915@2.625). |
| `--week N` | Every scenario that has no week of its own opens in week N (4 to 42). Default due date 2027-03-15 = week 24. |
| `--skip-build` | Reuse `<app>/build/web`. The kind of that build is read from `build/web/camera_build.json`; you are warned if `--review` does not match. |
| `--only` | Scenario or shot names, space or comma separated: `--only week-20 guide-iron` or `--only week-20,visit-show`. |
| `--list` | Print every scenario and its shots, then stop. |

Fast review round of the lead's copy, and a full round of a lane:

    python tool/camera/shoot.py --app C:\Users\owner\projects\apps\little-bumpy-app --review --fast --out <folder>
    python tool/camera/shoot.py --app C:\Users\owner\projects\apps\little-bumpy-app-wt\<lane> --review --out <folder>

## What it does

- Builds with the pinned SDK and `--no-web-resources-cdn`, serves `build/web` on a free 127.0.0.1 port and blocks every request to any other host (listed under `blocked_requests`), so a good picture proves the renderer works offline.
- Drives headless Chromium through Playwright (falls back to installed Edge). Each scenario runs in a fresh browser context at the phone size and device scale, touch on, reduced motion.
- Clock fixed at 2026-11-23 12:00, rotation day 0: IRON, the vampire.
- State is seeded before Flutter starts. `shared_preferences` on web stores `localStorage["flutter.<key>"] = JSON(value)`; a string list is a JSON array, e.g. `flutter.visit_topics = ["iron","question:Can I travel?","question@water:How much water is right for me?"]` (encoding from `lib/domain/models/visit_question.dart`).
- Progress: `n of N` with elapsed seconds and a result per shot, then one closing line: shot / not reached / failed / not applicable, and the contact sheet paths. Exit code 1 only for real failures (app did not load, crash), not for "not reached".

Output: `<shot>__<look>__<WxH@scale>.png`, Bumpy and wardrobe crops, `sheet__halloween.png`, `sheet__everyday.png` (375 size, every shot), `sheet__journey.png` (chapter page, Today with the question, guide page side by side at 375x812, one row per look; first existing shot from `JOURNEY` in `shoot.py`), and `manifest.json`.

## Scenarios

A scenario is seeded preferences + steps + a shot name, in `SCENARIOS` in `shoot.py`:

```python
S("visit-show", {"visit_topics": VISIT_WITH_QUESTIONS}, [
    tap("Show at my visit", "button", find=True), wait(500), shot("visit-show"),
    scroll(), shot("visit-show-2"),
], shot=None, note="from lane-visit.md"),
```

- Seed keys are prefs without `flutter.`. Special: `week=N` (due date for week N), `setup=False` (only the look saved: welcome), `fresh_install=True` (nothing saved: first run).
- Steps: `tap(label, role=None, find=False, xy=None)` taps the semantics node whose label or visible text matches (exact, then starts-with, then whole word, then contains; smallest box wins). `find=True` scrolls down to look for it. `xy=(0.5, 0.9)` is a last-resort tap at a screen fraction, recorded in the shot's `notes`. `tap_first([...])` taps the first label found (for a button whose words may change). `reveal(label)` scrolls until it is visible without tapping. `scroll(px)` drags a finger up (default 70% of the screen). `wait(ms)`. `shot(name)` photographs mid-way.
- `shot=` names the final picture (default: the scenario name; `None` = no final one). `looks=["halloween"]` limits looks. `planned="lane-x.md"` marks steps that are a guess until that lane's notes exist.
- Soft failure: if a step is not found, that shot and the rest of the scenario are recorded as `"not reached: <step>"` and the run moves on. Shots already taken stay.
- Taps work because the camera clicks Flutter's hidden `flt-semantics-placeholder`, which turns on the accessibility tree: each labelled widget then has an `<flt-semantics>` element at its place on screen.

Planned scenarios (steps are a best guess): `guide-iron` (lane-guides.md). `first-run` and `first-run-everyday` follow `roles/lane-firstrun.md` (Start, Choose due date, OK, Next x3, Enter the nursery; a shot after each tap; fresh install, so one look). The visit scenarios (`today-question`, `visit-show`, `visit-edit`, `visit-invite`) follow `roles/lane-visit.md`; `chapter` (week 20, four scrolled shots, needs `--review`) and `week-12/20/32` follow `roles/lane-chapter.md`.
