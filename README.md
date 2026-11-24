# Little Bumpy

Little Bumpy is a free, private pregnancy companion app, built for the **Kiroween 2026 (Costume Contest)** hackathon. The unborn baby, Bumpy, speaks the daily lines; settings, guides and safety lines are in a plain app voice.

In the Halloween look, Bumpy wears a costume each day that stands for one everyday need: the vampire is iron, the zombie is brain, the skeleton is bones, the mummy is water, the ghost is rest, and the witch is the prenatal vitamin your doctor or midwife chose.

---

## Key Features
- **Bumpy talks to you:** Bumpy speaks in the first person, straight to the parent.
- **Two looks:** Halloween, with Bumpy in the day's costume, and Everyday, with Bumpy in a lavender onesie. Switch any time with the lamp.
- **No pressure:** No streaks and no reminders.
- **Private:** No account, no ads, no tracking and no runtime AI. The app has no code that sends what you enter anywhere; it is stored on the device.
- **One-tap Pause:** Pause covers the app with a quiet screen until you choose Resume.

---

## Open Source Disclosure
`harness/` is pre-existing open-source code (MIT) written for Karan's avatar harness and used with disclosure in accordance with Kiroween hackathon rules.

---

## Build & Test

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The native suite checks the art through the Flutter engine. The Linux CI job also
runs `python tool/test_web_portraits.py` in Chromium against the same 15 source
portraits at all five skin tones. The browser test stages its art temporarily
because Flutter's web test server omits app assets. On Windows, the same command
uses Python Playwright to serve the pinned local CanvasKit renderer to Chrome.
Install that test dependency once with `python -m pip install playwright`.

For an installable web release, run `python tool/prepare_offline_web.py --build`
and serve `build/web/` over HTTPS or localhost. The command uses the local
CanvasKit renderer and bundles the fonts, app shell, costumes and content for
offline use. Packaging verifies the bundled content and paper art against the
current checkout before writing the worker. For a site hosted below the root, run Flutter with the site's base
path first, then package that output:

```bash
flutter build web --release --no-web-resources-cdn --base-href /little-bumpy/
python tool/prepare_offline_web.py
```

To check a deployment, open it online once and wait for the service worker to
activate. Switch the browser offline, reload, and open a costume you haven't
viewed. Updates take effect after the existing app tabs close. A partial
download keeps the previous complete release available.
Serve the packaged bytes unchanged so the browser can verify their hashes.
