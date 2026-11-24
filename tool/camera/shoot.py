"""Photograph the real Little Bumpy web build in a headless browser.

Shell: any (Windows PowerShell or bash). Run as a normal user.

    python tool/camera/shoot.py --out <folder> [--app <checkout>] [--review]
        [--fast] [--week N] [--skip-build] [--only name [name ...]] [--list]

Builds the web app (release by default; with --review a profile build with
BUMPY_REVIEW=true so draft text shows), serves <app>/build/web on a free
127.0.0.1 port, seeds the app's saved state in localStorage before Flutter
starts, then plays each scenario with Playwright and photographs it. Every
request to any other host is blocked, so the pictures prove the renderer
works with no internet.

A scenario = seeded preferences + steps (tap by visible text or semantics
label, scroll, wait, shot). A step that cannot be found is recorded as
"not reached: <step>" in the manifest and the run moves on.
"""
import argparse
import asyncio
import functools
import http.server
import json
import re
import shutil
import socket
import subprocess
import sys
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from playwright.async_api import async_playwright

HERE_APP = Path(__file__).resolve().parents[2]
FLUTTER = Path(r"C:\Users\owner\projects\avatar-harness-bumpy-studio\tools\run\flutter-entry-sdk\bin\flutter.bat")
BUILD_MARK = "camera_build.json"  # written into build/web so --skip-build knows the kind

# The app's day: Monday 2026-11-23 is rotation day 0 (IRON, vampire).
# Check-ins that day are iron, water, vitamin. Default due date gives week 24.
FIXED_NOW = datetime(2026, 11, 23, 12, 0, 0)
TODAY = "2026-11-23"
DUE_DATE = "2027-03-15"
CONCURRENCY = 4

LOOKS = ["halloween", "everyday"]
SIZES = [  # (width, height, device scale)
    (320, 568, 2),
    (375, 812, 3),
    (412, 915, 2.625),
]
SHEET_SIZE = (375, 812, 3)

# Saved questions, encoded as lib/domain/models/visit_question.dart does:
# topic names first, then "question:<text>" or "question@<need>:<text>".
VISIT_WITH_QUESTIONS = ["iron", "question:Can I travel?",
                        "question@water:How much water is right for me?"]


def _q2(text, origin, need=None, week=None, day=None):
    """A question in the current stored form ("q2:" + JSON), as
    VisitQuestion.encode() writes it: origin, need, week, day added."""
    data = {"t": text, "o": origin}
    if need:
        data["n"] = need
    if week:
        data["w"] = week
    if day:
        data["d"] = day
    return "q2:" + json.dumps(data, ensure_ascii=False, separators=(",", ":"))


# Both kinds of question: picked ones saved first, the parent's own after,
# so the show page has to reorder them (own words first).
VISIT_MIXED = [
    "rest",
    _q2("When will I feel movement?", "week", week=20, day="2026-10-26"),
    _q2("Can I keep cycling to work?", "own", day="2026-11-02"),
    _q2("How much water is right for me?", "guide", need="water", day="2026-11-09"),
    _q2("Could we check my iron?", "today", need="iron", day="2026-11-16"),
    _q2("Is it normal to feel this tired in the afternoons, even after a full night?",
        "own", day="2026-11-20"),
]


def due_for_week(week):
    """A due date that puts FIXED_NOW in the middle of pregnancy week N
    (lib/domain/pregnancy.dart: week = (280 + today - due) ~/ 7)."""
    return (FIXED_NOW.date() + timedelta(days=280 - 7 * week - 3)).isoformat()


# ── steps ───────────────────────────────────────────────────────────────────
# Each step is a small tuple. describe() turns it into the words used in
# "not reached: <step>".

def tap(label, role=None, find=False, xy=None):
    """Tap the semantics node whose label or visible text matches `label`.
    find=True scrolls down to look for it. xy=(fx, fy) is a last-resort
    tap at that fraction of the screen, used only if the label is missing."""
    return ("tap", label, role, find, xy)


def tap_first(labels, find=False):
    """Tap the first of several labels that is on screen (a primary button
    whose words may change)."""
    return ("tap_first", tuple(labels), find)


def reveal(label, at=0.3):
    """Scroll until `label`'s top sits near `at` of the screen height (0 top,
    1 bottom), without tapping it. Pick `at` so the card around the label is
    in the photograph: a button at a card's foot wants a larger `at`. The
    label must be its own semantics node (a button, a header with its own
    node); plain text inside a card is not."""
    return ("reveal", label, at)


def expect(label):
    """Check `label` is on screen now (no scroll, no tap); otherwise the rest
    of the scenario is 'not reached'. Use it to prove a page opened."""
    return ("expect", label)


def scroll(px=None):
    """Drag the page up by px CSS pixels (default: 70% of the screen)."""
    return ("scroll", px)


def wait(ms):
    return ("wait", ms)


def shot(name):
    return ("shot", name)


def describe(step):
    kind = step[0]
    if kind == "tap":
        return f"tap '{step[1]}'" + (f" ({step[2]})" if step[2] else "")
    if kind == "tap_first":
        return "tap one of " + " / ".join(f"'{s}'" for s in step[1])
    if kind == "reveal":
        return f"scroll to '{step[1]}'"
    if kind == "expect":
        return f"see '{step[1]}'"
    if kind == "scroll":
        return f"scroll {step[1] or 'one screen'}"
    if kind == "wait":
        return f"wait {step[1]} ms"
    return f"shot {step[1]}"


# ── scenarios ───────────────────────────────────────────────────────────────
# name:    used with --only (shot names work too)
# seed:    saved prefs without the "flutter." prefix. Special keys:
#          fresh_install=True -> nothing saved at all (first run)
#          setup=False -> only the look saved (the welcome screen in that look)
#          week=N      -> due date that puts the app in week N
# steps:   played in order; ("shot", name) photographs mid-way
# shot:    final shot name (default: the scenario name); None = no final shot
# planned: lane notes this scenario waits on; its steps are a best guess
# looks:   limit to some looks (default both)

def S(name, seed=None, steps=(), shot=..., planned=None, looks=None, note=None):
    return {"name": name, "seed": seed or {}, "steps": list(steps),
            "shot": name if shot is ... else shot, "planned": planned,
            "looks": looks, "note": note}


def chapter_scenario(n):
    """This Week at week n: the chapter page (roles/lane-chapter.md; drafts,
    so --review), top of page and three scrolled shots."""
    p = f"chapter-wk{n}"
    return S(p, {"week": n}, [
        tap("This Week", "tab"), wait(600), shot(p),
        scroll(), shot(f"{p}-2"), scroll(), shot(f"{p}-3"), scroll(), shot(f"{p}-4"),
    ], shot=None, note="from lane-chapter.md; drafts show only with --review")


def first_run_steps(prefix, look_label=None):
    """From roles/lane-firstrun.md: welcome (Start), date (Choose due date,
    a day in the picker, OK, Next), nickname (Next), look (Next), six needs
    (Meet Bumpy). look_label picks a look card on step 4."""
    p = prefix
    return [
        shot(f"{p}-1-welcome"),
        tap("Start", "button"), wait(500), shot(f"{p}-2-date"),
        tap_first(["Choose due date", "Pick your due date"]), wait(600), shot(f"{p}-2-picker"),
        # The picker opens with no day chosen, on this month. Step to March
        # 2027 and pick the 15th (the camera's DUE_DATE, week 24), then OK.
        *[st for _ in range(4) for st in (tap("Next month", "button"), wait(350))],
        tap_first(["15, Monday, March 15, 2027", "15,"]), wait(400), shot(f"{p}-2-day"),
        tap_first(["OK", "Ok"]), wait(600), shot(f"{p}-2-picked"),
        tap_first(["Next"], find=True), wait(500), shot(f"{p}-3-nickname"),
        tap_first(["Next"], find=True), wait(500),
        *([tap(look_label, find=True), wait(400)] if look_label else []),
        shot(f"{p}-4-look"),
        tap_first(["Next"], find=True), wait(500), shot(f"{p}-5-needs"),
        scroll(), shot(f"{p}-5-needs-more"),
        tap_first(["Meet Bumpy", "Enter the nursery"], find=True), wait(1500), shot(f"{p}-6-nursery"),
    ]


def first_run_until(name, step, look=None):
    """A fresh install played up to first-run step `step` (3 nickname,
    4 look, 5 needs) with no shots on the way; the one shot is `name`.
    look="everyday" starts from a welcome screen with only the Everyday look
    saved (as after "Try daylight"), so steps before the look step are seen
    in Everyday."""
    steps = first_run_steps("x")
    end = next(i for i, st in enumerate(steps) if st[0] == "shot" and st[1].startswith(f"x-{step}-"))
    played = [st for st in steps[:end] if st[0] != "shot"]
    if look == "everyday":
        return S(name, {"setup": False}, played, looks=["everyday"],
                 note="welcome with only the Everyday look saved; shot once")
    return S(name, {"fresh_install": True}, played,
             looks=["halloween"], note="a brand-new install has no saved look; shot once")


SCENARIOS = [
    # The screens the camera always took.
    S("welcome", {"setup": False}),
    S("today-fresh"),
    S("today-one-done", {"daily_needs_v2": [TODAY, "iron"]}),
    S("today-all-done", {"daily_needs_v2": [TODAY, "iron", "water", "vitamin"]}),
    S("wardrobe", steps=[tap("Wardrobe", "button")], looks=["halloween"],
      note="the wardrobe exists only in the Halloween look"),
    S("this-week", steps=[tap("This Week", "tab")]),
    S("guides", steps=[tap("Guides", "tab")]),
    S("guide-open", steps=[tap("Guides", "tab"), tap("Iron", "button")]),
    S("visit-list", {"visit_topics": ["iron"]},
      [tap("Guides", "tab"), tap("Edit visit list", "button")]),
    S("settings", steps=[tap("Settings", "button")]),
    S("paused", {"is_paused": True}),

    # Chapters: weeks 12, 20, 24, 32, top and scrolled, both looks.
    chapter_scenario(12),
    chapter_scenario(20),
    chapter_scenario(24),
    chapter_scenario(32),

    # Visit list with questions already saved.
    S("visit-questions", {"visit_topics": VISIT_WITH_QUESTIONS},
      [tap("Guides", "tab"), tap_first(["Open my visit list", "Edit visit list", "Choose topics"], find=True)]),

    # Guides, from roles/lane-guides.md. A guide that passed the review gate
    # opens a full page from its Guides card; "Good to know" proves the page
    # opened. While assets/content/guides.json is empty every guide is
    # hidden: the card just expands, so guide-iron is "not reached" and
    # guide-iron-hidden shows what a parent sees instead.
    S("guide-iron", steps=[
        tap("Guides", "tab"), tap("Iron", "button", find=True), wait(600), expect("Good to know"),
        shot("guide-iron"), scroll(), shot("guide-iron-2"), scroll(), shot("guide-iron-3"),
    ], shot=None, note="from lane-guides.md; needs an approved or (with --review) draft Iron guide"),
    S("guide-iron-hidden", steps=[
        tap("Guides", "tab"), wait(500), shot("guide-iron-hidden"),
        scroll(), shot("guide-iron-hidden-2"),
    ], shot=None, note="guides tab while the Iron guide is hidden (empty guides.json)"),
    # Visit: steps from roles/lane-visit.md (Today card "For your visit" with
    # the parent's own question and a "Show at my visit" button; show page
    # with Close and Edit).
    S("today-question", {"visit_topics": VISIT_WITH_QUESTIONS}, [
        reveal("Show at my visit", at=0.62), wait(300),
    ], note="from lane-visit.md"),
    S("visit-show", {"visit_topics": VISIT_WITH_QUESTIONS}, [
        tap("Show at my visit", "button", find=True), wait(500), shot("visit-show"),
        scroll(), shot("visit-show-2"),
    ], shot=None, note="from lane-visit.md"),
    S("visit-edit", {"visit_topics": VISIT_WITH_QUESTIONS}, [
        tap("Show at my visit", "button", find=True), wait(500), tap("Edit", "button"), wait(500),
    ], note="from lane-visit.md"),
    S("visit-invite", {}, [reveal("A question for your doctor or midwife", at=0.45)],
      note="from lane-visit.md: empty list shows one quiet line"),
    # Visit memory (roles/visit-memory.md): own words and picked questions.
    S("visit-mixed-today", {"visit_topics": VISIT_MIXED}, [
        reveal("Show at my visit", at=0.62), wait(300),
    ], note="newest own words on Today's card"),
    S("visit-mixed-show", {"visit_topics": VISIT_MIXED}, [
        tap("Show at my visit", "button", find=True), wait(500), shot("visit-mixed-show"),
        scroll(), shot("visit-mixed-show-2"), scroll(), shot("visit-mixed-show-3"),
    ], shot=None, note="own words first, then picked with origin lines, then Copy my list"),
    S("visit-mixed-edit", {"visit_topics": VISIT_MIXED}, [
        tap("Show at my visit", "button", find=True), wait(500), tap("Edit", "button"), wait(500),
        shot("visit-mixed-edit"), scroll(), shot("visit-mixed-edit-2"),
    ], shot=None, note="editor: own words first, change-the-words pencil"),
    S("visit-mixed-change", {"visit_topics": VISIT_MIXED}, [
        tap("Show at my visit", "button", find=True), wait(500), tap("Edit", "button"), wait(500),
        tap("Change the words: How much water is right for me?", "button", find=True), wait(500),
    ], note="the change-the-words dialog on a picked question"),
    S("visit-mixed-copied", {"visit_topics": VISIT_MIXED}, [
        tap("Show at my visit", "button", find=True), wait(500),
        tap("Copy my list", "button", find=True), wait(400),
    ], note="Copy my list and its note"),
    # First run: brand-new install, from roles/lane-firstrun.md (five steps).
    # No look is saved yet, so it runs once; first-run-everyday picks the
    # Everyday card on the look step.
    S("first-run", {"fresh_install": True}, first_run_steps("first-run"), shot=None,
      looks=["halloween"], note="a brand-new install has no saved look; shot once"),
    S("first-run-everyday", {"fresh_install": True}, first_run_steps("first-run-ev", "Everyday"),
      shot=None, looks=["halloween"], note="a brand-new install has no saved look; shot once"),
    # One first-run step each, so --only can ask for just that screen.
    first_run_until("first-run-step3", 3),
    first_run_until("first-run-step3-everyday", 3, look="everyday"),
    first_run_until("first-run-step4", 4),
    first_run_until("first-run-step5", 5),
]

# Three key moments for sheet__journey.png: first existing shot name of each.
JOURNEY = [("chapter page", ["chapter-wk20", "this-week"]),
           ("Today with the question", ["today-question", "today-fresh"]),
           ("guide page", ["guide-iron", "guide-iron-hidden", "guide-open"])]


def log(start, msg):
    print(f"[{time.time() - start:6.1f}s] {msg}", flush=True)


def seed_for(look, extra, week):
    extra = dict(extra)
    prefs = {"is_halloween": look == "halloween"}
    if extra.pop("fresh_install", False):
        return {}  # a brand-new install: nothing saved, the app picks its own look
    if not extra.pop("setup", True):
        return prefs  # setup not finished: only the look is saved
    w = extra.pop("week", week)
    prefs.update({"due_date_iso": due_for_week(w) if w else DUE_DATE, "skin_tone": "peach",
                  "baby_nickname": "", "is_paused": False})
    prefs.update(extra)
    return prefs


def init_script(prefs):
    # shared_preferences on web: localStorage["flutter.<key>"] = JSON of the
    # value. A string list is a JSON array: ["iron","question:Can I travel?"].
    data = json.dumps({"flutter." + k: json.dumps(v) for k, v in prefs.items()})
    return f"""(() => {{
  if (sessionStorage.getItem('__camera_seeded')) return;
  localStorage.clear();
  const seed = {data};
  for (const k in seed) localStorage.setItem(k, seed[k]);
  sessionStorage.setItem('__camera_seeded', '1');
}})();"""


def size_tag(w, h, s):
    return f"{w}x{h}@{s:g}"


# ── build and serve ─────────────────────────────────────────────────────────

def build(app, review, start):
    web = app / "build" / "web"
    if review:
        kind, cmd = "profile+review", ["--profile", "--dart-define=BUMPY_REVIEW=true"]
    else:
        kind, cmd = "release", ["--release"]
    cmd = [str(FLUTTER), "build", "web", *cmd, "--no-web-resources-cdn"]
    log(start, f"Building web {kind} in {app} ...")
    log(start, "  " + " ".join(cmd[1:]))
    result = subprocess.run(cmd, cwd=app, shell=False)
    if result.returncode != 0:
        raise SystemExit("flutter build web failed (exit %d)" % result.returncode)
    (web / BUILD_MARK).write_text(json.dumps({"kind": kind, "built": datetime.now().isoformat(
        timespec="seconds"), "command": " ".join(cmd[1:])}), encoding="utf-8")
    log(start, f"Build saved to {web} ({kind})")
    return kind


def existing_build_kind(web):
    try:
        return json.loads((web / BUILD_MARK).read_text(encoding="utf-8"))["kind"]
    except Exception:
        return "unknown (built outside the camera)"


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".js": "text/javascript", ".mjs": "text/javascript",
                      ".wasm": "application/wasm", ".json": "application/json",
                      ".png": "image/png", ".webp": "image/webp", ".woff2": "font/woff2",
                      ".ttf": "font/ttf", ".otf": "font/otf", ".html": "text/html"}

    def log_message(self, *args):
        pass


def serve(web):
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    sock.close()
    # The default listen backlog (5) refuses connections when several pages
    # fetch CanvasKit and assets at once; that showed as "Failed to fetch".
    server_class = type("Server", (http.server.ThreadingHTTPServer,), {"request_queue_size": 256})
    server = server_class(
        ("127.0.0.1", port), functools.partial(Handler, directory=str(web)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, f"http://127.0.0.1:{port}/"


# ── finding things on a canvas app ──────────────────────────────────────────
# Flutter web draws to a canvas. With the semantics tree on, each widget
# with a label gets an <flt-semantics> element at its place on screen. We
# read them all at once and pick the best match: exact name first, then
# starts-with, then whole word, then contains; the smallest box wins ties
# (a container's text includes its children's).

FIND_JS = """([needle, role]) => {
  const n = needle.toLowerCase();
  const norm = t => ' ' + t.replace(/[^a-z0-9]+/g, ' ').trim() + ' ';
  const nw = norm(n);
  const word = {test: s => norm(s).includes(nw)};
  const out = [];
  for (const el of document.querySelectorAll('flt-semantics, flt-semantics-container [role]')) {
    const r = el.getBoundingClientRect();
    if (r.width < 2 || r.height < 2) continue;
    const label = (el.getAttribute('aria-label') || '').trim();
    const text = (el.innerText || el.textContent || '').trim();
    let best = 9;
    for (const raw of [label, text]) {
      const s = raw.toLowerCase().replace(/\\s+/g, ' ');
      if (!s) continue;
      const score = s === n ? 0 : s.startsWith(n) ? 1 : word.test(s) ? 2 : s.includes(n) ? 3 : 9;
      best = Math.min(best, score);
    }
    if (best === 9) continue;
    const elRole = el.getAttribute('role') || '';
    const roleHit = role && (elRole === role || (role === 'button' && el.tagName === 'BUTTON')) ? 0 : 1;
    const disabled = el.getAttribute('aria-disabled') === 'true';
    out.push({score: best, roleHit, disabled, x: r.x, y: r.y, w: r.width, h: r.height,
              area: r.width * r.height, label: label || text.slice(0, 60)});
  }
  out.sort((a, b) => a.disabled - b.disabled || a.score - b.score || a.roleHit - b.roleHit || a.area - b.area);
  return out;
}"""


BOTTOM_JS = """(vh) => {
  // The tab bar sits on top of the page: a button scrolled under it is not
  // tappable (a tap there lands on a tab). Return where the usable screen ends.
  let bottom = vh;
  for (const el of document.querySelectorAll('flt-semantics[role="tablist"]')) {
    const r = el.getBoundingClientRect();
    if (r.height > 2 && r.top > vh * 0.5) bottom = Math.min(bottom, r.top);
  }
  return bottom;
}"""


async def usable_bottom(page, vh):
    """Bottom of the tappable screen: the top of the tab bar, if there is one."""
    try:
        return await page.evaluate(BOTTOM_JS, vh)
    except Exception:
        return vh


async def find(page, label, role, vw, vh):
    """Best on-screen match, or ('offscreen', match) / (None, None).
    A match hidden under the tab bar counts as off screen. A box taller than
    45% of the screen is a whole page or panel carrying every word in it, not
    the thing asked for: tapping its middle used to land on Today's nursery
    while the real button was still below the fold."""
    found = await page.evaluate(FIND_JS, [label, role or ""])
    found = [m for m in found if m["h"] <= vh * 0.45]
    bottom = await usable_bottom(page, vh)
    for m in found:
        cx, cy = m["x"] + m["w"] / 2, m["y"] + m["h"] / 2
        is_tab = role == "tab"  # the tabs themselves stay tappable
        limit = vh if is_tab else bottom
        if 0 <= cx <= vw and 8 <= cy <= limit - 8 and not m["disabled"]:
            return "visible", m
    return ("offscreen", found[0]) if found else (None, None)


async def finger_tap(page, x, y):
    # Tap like a finger (Flutter listens to pointer events on its own pane).
    # A touch, not a mouse, so no hover tooltip is left on the next screen.
    await page.touchscreen.tap(x, y)


async def drag_scroll(page, vw, vh, px):
    """Scroll by dragging a finger up the middle of the screen (Flutter
    reads raw pointer events), then fall back to a mouse wheel."""
    x = vw / 2
    if px >= 0:
        y0 = vh * 0.78
        y1 = max(vh * 0.78 - px, vh * 0.08)
    else:  # a negative px drags down: the page scrolls back up
        y0 = vh * 0.20
        y1 = min(vh * 0.20 - px, vh * 0.90)
    cdp = await page.context.new_cdp_session(page)
    try:
        steps = 12
        await cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x, "y": y0}]})
        for i in range(1, steps + 1):
            await cdp.send("Input.dispatchTouchEvent", {
                "type": "touchMove", "touchPoints": [{"x": x, "y": y0 + (y1 - y0) * i / steps}]})
            await asyncio.sleep(0.016)
        await asyncio.sleep(0.12)  # hold still, so it stops rather than flings
        await cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
    finally:
        await cdp.detach()
    await page.wait_for_timeout(500)


async def page_fingerprint(page):
    return await page.evaluate(
        "() => [...document.querySelectorAll('flt-semantics')].slice(0, 400)"
        ".map(e => Math.round(e.getBoundingClientRect().y)).join(',')")


async def do_tap(page, labels, role, find_scroll, xy, vw, vh, notes, timeout=6.0, press=True):
    deadline = time.time() + timeout
    scrolls = 0
    while True:
        for label in labels:
            where, m = await find(page, label, role, vw, vh)
            if where == "visible":
                if press:
                    await finger_tap(page, m["x"] + m["w"] / 2, m["y"] + m["h"] / 2)
                return True
        if time.time() < deadline:
            await asyncio.sleep(0.25)
            continue
        if find_scroll and scrolls < 6:
            before = await page_fingerprint(page)
            await drag_scroll(page, vw, vh, vh * 0.55)
            scrolls += 1
            if await page_fingerprint(page) == before:
                find_scroll = False  # the page did not move: at the bottom
            deadline = time.time() + 1.0
            continue
        break
    if xy:
        await finger_tap(page, vw * xy[0], vh * xy[1])
        notes.append(f"tapped '{labels[0]}' by screen position {xy}")
        return True
    return False


async def reveal_into_view(page, label, at, vw, vh, notes, tries=8):
    """Scroll until `label`'s top sits within 12% of the screen around `at`
    (or the page ends), so the card around it is in the picture too. The
    old reveal stopped as soon as a sliver of the label peeked above the tab
    bar, which left the card itself out of the photograph."""
    await page.wait_for_timeout(500)
    for _ in range(tries):
        bottom = await usable_bottom(page, vh)
        found = [m for m in await page.evaluate(FIND_JS, [label, ""]) if m["h"] <= vh * 0.45]
        m = found[0] if found else None
        lo, hi = max(vh * (at - 0.12), vh * 0.06), vh * (at + 0.12)
        if m and lo <= m["y"] <= hi and m["y"] + m["h"] <= bottom - 8:
            return True
        if m is None:
            px = vh * 0.55
        elif m["y"] > hi or m["y"] + m["h"] > bottom - 8:
            px = min(m["y"] - vh * at, vh * 0.65)
        else:  # too high: drag the other way
            px = max(m["y"] - vh * at, -vh * 0.65)
        before = await page_fingerprint(page)
        await drag_scroll(page, vw, vh, px)
        if await page_fingerprint(page) == before:
            # The page cannot move further: good enough if it shows at all.
            if m and 8 <= m["y"] <= bottom - 16:
                notes.append(f"'{label}' shown as high as the page scrolls")
                return True
            return False
    return bool(m and 8 <= m["y"] <= bottom - 16)


# ── one scenario at one size and look ───────────────────────────────────────

async def open_app(browser, url, w, h, s, prefs, blocked):
    context = await browser.new_context(viewport={"width": w, "height": h},
                                        device_scale_factor=s, is_mobile=True, has_touch=True,
                                        reduced_motion="reduce", service_workers="block")
    await context.clock.set_fixed_time(FIXED_NOW)
    await context.add_init_script(init_script(prefs))

    async def gate(route):
        if route.request.url.startswith(url):
            await route.continue_()
        else:
            blocked.add(route.request.url)
            await route.abort()
    await context.route("**/*", gate)
    page = await context.new_page()
    # flutter_bootstrap.js removes #opening on the first frame. One reload is
    # allowed if the first load stalls.
    for attempt in (1, 2):
        await page.goto(url)
        try:
            await page.wait_for_selector("#opening", state="detached", timeout=30000)
            break
        except Exception:
            if attempt == 2:
                raise RuntimeError("app never drew its first frame (still on the opening screen)")
    await page.wait_for_function(
        "() => !!document.querySelector('flt-semantics-placeholder, flt-glass-pane, flutter-view')",
        timeout=10000)
    # Turn on Flutter's accessibility tree so widgets can be found by name.
    await page.locator("flt-semantics-placeholder").dispatch_event("click")
    await page.wait_for_selector("flt-semantics", state="attached", timeout=10000)
    await page.wait_for_timeout(900)  # images decode, fonts settle
    return context, page


async def play(browser, url, out, run, start, counter, total, blocked):
    """Play one scenario at one size and look; fill in its shot jobs."""
    sc, look, (w, h, s) = run["scenario"], run["look"], run["size"]
    shots = {j["shot"]: j for j in run["jobs"]}
    t0 = time.time()
    context = None
    notes = []

    def finish(job, ok, error=None, reached=True):
        job.update(ok=ok, error=error, not_reached=not reached, seconds=round(time.time() - t0, 1))
        if notes:
            job["notes"] = list(notes)
        counter[0] += 1
        status = "ok" if ok else (error if not reached else "FAILED: " + error)
        log(start, f"{counter[0]} of {total}  {job['file']}  {status}")

    try:
        context, page = await open_app(browser, url, w, h, s, run["prefs"], blocked)
        steps = sc["steps"] + ([shot(sc["shot"])] if sc["shot"] else [])
        for step in steps:
            kind = step[0]
            if kind == "shot":
                job = shots.get(step[1])
                if not job:
                    continue  # filtered out by --only
                await page.wait_for_timeout(500)
                path = out / job["file"]
                await page.screenshot(path=str(path))
                if (w, h, s) == SHEET_SIZE and step[1] in ("today-fresh", "wardrobe"):
                    try:
                        await crops(page, path, step[1], look, s, out)
                    except Exception as exc:
                        notes.append(f"crop skipped: {exc}")
                finish(job, True)
                continue
            if kind == "wait":
                await page.wait_for_timeout(step[1])
                continue
            if kind == "scroll":
                await drag_scroll(page, w, h, step[1] or h * 0.7)
                continue
            if kind == "reveal":
                ok = await reveal_into_view(page, step[1], step[2], w, h, notes)
            elif kind == "expect":
                ok = await do_tap(page, [step[1]], None, False, None, w, h, notes, timeout=3.0, press=False)
            elif kind == "tap":
                ok = await do_tap(page, [step[1]], step[2], step[3], step[4], w, h, notes)
            else:  # tap_first
                ok = await do_tap(page, list(step[1]), "button", step[2], None, w, h, notes)
            if not ok:
                reason = "not reached: " + describe(step)
                for job in run["jobs"]:
                    if job["ok"] is None:
                        finish(job, False, reason, reached=False)
                return
            await page.wait_for_timeout(700)
    except Exception as exc:  # keep going; the manifest records the failure
        err = str(exc).splitlines()[0][:300]
        for job in run["jobs"]:
            if job["ok"] is None:
                finish(job, False, err)
    finally:
        if context:
            await context.close()
    for job in run["jobs"]:  # a shot named in --only but not in the steps
        if job["ok"] is None:
            finish(job, False, "not reached: no such shot in the steps", reached=False)


async def crops(page, path, name, look, scale, out):
    if name == "today-fresh":
        loc = page.get_by_role("img", name=re.compile("^Bumpy in"))
        stem, trim = f"crop-bumpy__{look}", None
    else:
        loc = page.get_by_role("button", name=re.compile(r"^Try Vampire"))
        stem, trim = f"crop-wardrobe-thumb__{look}", 65  # thumbnail strip height
    box = await loc.first.bounding_box(timeout=3000)
    if not box:
        raise RuntimeError(f"no box for {stem}")
    height = trim if trim else box["height"]
    img = Image.open(path)
    rect = tuple(round(v * scale) for v in (box["x"], box["y"], box["x"] + box["width"], box["y"] + height))
    crop = img.crop(rect)
    crop.save(out / f"{stem}.png")
    crop.resize((crop.width * 2, crop.height * 2), Image.NEAREST).save(out / f"{stem}__x2.png")


# ── contact sheets ──────────────────────────────────────────────────────────

def _font(size):
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def contact_sheet(out, look, jobs, start):
    w, h, s = SHEET_SIZE
    items = [j for j in jobs if j["look"] == look and j["size"] == SHEET_SIZE and j["ok"]]
    if not items:
        log(start, f"sheet__{look}.png skipped: no shots")
        return None
    cols = 6
    gap, label_h, max_w = 16, 34, 2400
    tw = (max_w - gap * (cols + 1)) // cols
    th = round(tw * h / w)
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (max_w, gap + rows * (th + label_h + gap)), (245, 242, 236))
    draw = ImageDraw.Draw(sheet)
    font = _font(20)
    for i, job in enumerate(items):
        x = gap + (i % cols) * (tw + gap)
        y = gap + (i // cols) * (th + label_h + gap)
        thumb = Image.open(out / job["file"]).convert("RGB").resize((tw, th), Image.LANCZOS)
        draw.text((x, y + 4), job["shot"], fill=(30, 20, 40), font=font)
        sheet.paste(thumb, (x, y + label_h))
        draw.rectangle([x - 1, y + label_h - 1, x + tw, y + label_h + th], outline=(180, 170, 160))
    name = f"sheet__{look}.png"
    sheet.save(out / name)
    log(start, f"{name} saved ({len(items)} shots, {sheet.width}x{sheet.height})")
    return name


def journey_sheet(out, jobs, start):
    """The three key moments side by side at 375x812, one row per look."""
    w, h, s = SHEET_SIZE
    ok = {(j["shot"], j["look"]): j for j in jobs if j["ok"] and j["size"] == SHEET_SIZE}
    rows = []
    for look in LOOKS:
        row = []
        for title, names in JOURNEY:
            pick = next((ok[(n, look)] for n in names if (n, look) in ok), None)
            row.append((title, pick))
        if any(p for _, p in row):
            rows.append((look, row))
    if not rows:
        log(start, "sheet__journey.png skipped: none of the key moments were shot")
        return None
    gap, label_h, tw = 24, 56, 750
    th = round(tw * h / w)
    sheet = Image.new("RGB", (gap + 3 * (tw + gap), gap + len(rows) * (th + label_h + gap)), (245, 242, 236))
    draw = ImageDraw.Draw(sheet)
    font, small = _font(26), _font(18)
    for r, (look, row) in enumerate(rows):
        y = gap + r * (th + label_h + gap)
        for c, (title, job) in enumerate(row):
            x = gap + c * (tw + gap)
            draw.text((x, y + 2), f"{title} ({look})", fill=(30, 20, 40), font=font)
            if job:
                draw.text((x, y + 32), job["file"], fill=(110, 100, 110), font=small)
                img = Image.open(out / job["file"]).convert("RGB").resize((tw, th), Image.LANCZOS)
                sheet.paste(img, (x, y + label_h))
            else:
                draw.text((x + 20, y + label_h + 20), "not shot", fill=(150, 60, 60), font=font)
            draw.rectangle([x - 1, y + label_h - 1, x + tw, y + label_h + th], outline=(180, 170, 160))
    sheet.save(out / "sheet__journey.png")
    log(start, f"sheet__journey.png saved ({sheet.width}x{sheet.height})")
    return "sheet__journey.png"


# ── main ────────────────────────────────────────────────────────────────────

async def run_all(url, out, runs, start, blocked):
    async with async_playwright() as p:
        try:
            browser = await p.chromium.launch(headless=True)
            log(start, "Browser: Playwright Chromium (headless)")
        except Exception:
            browser = await p.chromium.launch(headless=True, channel="msedge")
            log(start, "Browser: Microsoft Edge (headless)")
        gate = asyncio.Semaphore(CONCURRENCY)
        counter = [0]
        total = sum(len(r["jobs"]) for r in runs)

        async def guarded(run):
            async with gate:
                await play(browser, url, out, run, start, counter, total, blocked)
        await asyncio.gather(*(guarded(r) for r in runs))
        await browser.close()


def shot_names(sc):
    names = [st[1] for st in sc["steps"] if st[0] == "shot"]
    return names + ([sc["shot"]] if sc["shot"] else [])


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, help="folder for the pictures and manifest.json")
    parser.add_argument("--app", type=Path, default=HERE_APP,
                        help="checkout or worktree to photograph (default: the one this script is in)")
    parser.add_argument("--review", action="store_true",
                        help="profile build with --dart-define=BUMPY_REVIEW=true (draft text shows)")
    parser.add_argument("--fast", action="store_true", help="only 375x812@3, both looks")
    parser.add_argument("--week", type=int, help="put every scenario without its own week in week N")
    parser.add_argument("--skip-build", action="store_true", help="reuse <app>/build/web")
    parser.add_argument("--only", nargs="+", action="extend",
                        help="scenario or shot names (space or comma separated)")
    parser.add_argument("--list", action="store_true", help="print the scenarios and shots, then stop")
    args = parser.parse_args()

    if args.list:
        for sc in SCENARIOS:
            extra = f"   [planned: {sc['planned']}]" if sc["planned"] else ""
            print(f"{sc['name']:<16} shots: {', '.join(shot_names(sc))}{extra}")
        return 0
    if not args.out:
        parser.error("--out is required")
    if args.week is not None and not 4 <= args.week <= 42:
        parser.error("--week must be 4 to 42")

    start = time.time()
    app = args.app.resolve()
    web = app / "build" / "web"
    if not (app / "pubspec.yaml").is_file():
        raise SystemExit(f"--app {app} has no pubspec.yaml; is it a Little Bumpy checkout?")
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    sizes = [SHEET_SIZE] if args.fast else SIZES
    print(f"Little Bumpy camera: {app} -> {out}", flush=True)

    if args.skip_build:
        kind = existing_build_kind(web)
        log(start, f"Build skipped (--skip-build); build/web is {kind}")
        if args.review and not kind.startswith("profile+review"):
            print("Warning: --review asked for, but build/web is not a review build; draft text will not show.",
                  flush=True)
    else:
        kind = build(app, args.review, start)
    if not (web / "main.dart.js").is_file() or not (web / "canvaskit" / "canvaskit.wasm").is_file():
        raise SystemExit(f"{web} is missing main.dart.js or local CanvasKit; run without --skip-build")

    wanted = None
    if args.only:
        wanted = {n.strip() for part in args.only for n in part.split(",") if n.strip()}
        known = {sc["name"] for sc in SCENARIOS} | {n for sc in SCENARIOS for n in shot_names(sc)}
        unknown = wanted - known
        if unknown:
            print(f"Warning: unknown names skipped: {', '.join(sorted(unknown))} (see --list)", flush=True)

    runs, jobs = [], []
    for sc in SCENARIOS:
        names = shot_names(sc)
        if wanted and sc["name"] not in wanted:
            names = [n for n in names if n in wanted]
        if not names:
            continue
        for look in LOOKS:
            for size in sizes:
                prefs = seed_for(look, sc["seed"], args.week)
                run_jobs = []
                for n in names:
                    job = {"file": f"{n}__{look}__{size_tag(*size)}.png", "shot": n, "scenario": sc["name"],
                           "look": look, "size": size, "viewport": f"{size[0]}x{size[1]}",
                           "device_scale": size[2], "state": prefs,
                           "steps": [describe(st) for st in sc["steps"]], "planned": sc["planned"],
                           "ok": None, "error": None}
                    if sc["looks"] and look not in sc["looks"]:
                        job.update(ok=False, skipped=True, error="not applicable: " + (sc["note"] or look))
                    else:
                        run_jobs.append(job)
                    jobs.append(job)
                if run_jobs:
                    runs.append({"scenario": sc, "look": look, "size": size, "prefs": prefs, "jobs": run_jobs})

    todo = sum(len(r["jobs"]) for r in runs)
    log(start, f"{len(runs)} scenario runs, {todo} shots planned "
               f"({len(sizes)} size(s) x {len(LOOKS)} looks)")
    server, url = serve(web)
    log(start, f"Serving {web} at {url} (other hosts blocked)")
    shoot_start = time.time()
    blocked = set()
    try:
        asyncio.run(run_all(url, out, runs, start, blocked))
    finally:
        server.shutdown()
    log(start, f"Shots took {time.time() - shoot_start:.0f}s")

    sheets = [n for n in (contact_sheet(out, look, jobs, start) for look in LOOKS) if n]
    j = journey_sheet(out, jobs, start)
    if j:
        sheets.append(j)

    for job in jobs:
        job["size"] = size_tag(*job["size"])
    taken = [j for j in jobs if not j.get("skipped")]
    ok = sum(1 for j in taken if j["ok"])
    not_reached = [j for j in taken if j.get("not_reached")]
    failed = [j for j in taken if not j["ok"] and not j.get("not_reached")]
    skipped = len(jobs) - len(taken)
    waiting = sorted({sc["planned"] for sc in SCENARIOS if sc["planned"]})
    manifest = {"made": datetime.now().isoformat(timespec="seconds"), "app": str(app),
                "build": kind, "review": kind.startswith("profile+review"),
                "app_clock": FIXED_NOW.isoformat(), "week_override": args.week,
                "sizes": [size_tag(*z) for z in sizes], "url": url,
                "blocked_requests": sorted(blocked), "ok": ok, "not_reached": len(not_reached),
                "failed": len(failed), "not_applicable": skipped, "sheets": sheets,
                "planned_waiting_on": waiting, "shots": jobs}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    if blocked:
        print(f"Note: blocked {len(blocked)} request(s) to other hosts; see manifest.json", flush=True)
    for j in failed:
        print(f"  FAILED       {j['file']}: {j['error']}", flush=True)
    for j in not_reached:
        print(f"  not reached  {j['file']}: {j['error'][len('not reached: '):]}", flush=True)
    print(f"Done in {time.time() - start:.0f}s ({kind} build): {ok} shot, {len(not_reached)} not reached, "
          f"{len(failed)} failed, {skipped} not applicable. Contact sheets: "
          f"{', '.join(str(out / n) for n in sheets) or 'none'}", flush=True)
    print("Next: open the sheets, then manifest.json for anything not shot."
          if not failed else "Next: read the FAILED lines, then rerun with --skip-build --only <name>.",
          flush=True)
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
