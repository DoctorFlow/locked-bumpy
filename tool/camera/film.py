"""Film one continuous take of the real Little Bumpy web build.

Shell: any (Windows PowerShell or Git Bash). Run as a normal user.

    python tool/camera/film.py --out <folder> [--app <checkout>] [--review]
        [--look everyday|halloween] [--week N] [--no-build [--web <build/web>]]
        [--keep-build] [--webp]

A parent 20 weeks along, on a phone (375x812 at device scale 3):
  1. Today: Bumpy in the nursery, then the fact card.
  2. This Week: the chapter and its picture, "One thing to know",
     "One thing to get ready".
  3. "Add to my visit list" on the chapter's question; the
     whole question piece is replaced by the "On your list:" card (it lists
     the saved question). Then "Something to look forward to".
  4. The curious question opens its guide; scroll to "When to call".
  5. Back, Today, the "For your visit" card, "Show at my visit"; hold on the
     parent's own question.

Build and serve come from shoot.py (imported, not copied). Frames are taken
as screenshots at full device pixels (1125x2436, about 19 a second), so text stays
sharp, and joined with ffmpeg at their real timing. Every tap shows a dot.
A step that cannot be found is logged as "not reached: <step>" and the film
goes on with the next part of the story.

Output in --out: little-bumpy-journey.mp4 (or .webm), little-bumpy-journey.webp
(only if no MP4 could be made, or with --webp), poster.png, film-log.txt.
"""
import argparse
import asyncio
import base64
import io
import json
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import shoot  # noqa: E402  (build, serve, seeding and finding live there)

from PIL import Image  # noqa: E402
from playwright.async_api import async_playwright  # noqa: E402

W, H = 375, 812
SCALE = 3  # device pixels per CSS pixel; --scale changes it
FPS = 30
DEFAULT_WEEK = 20
# The parent's own words, already on the visit list (seeded like shoot.py).
OWN_QUESTION = "Is it okay to keep swimming?"
MIN_FREE_GB = 3.0
NAME = "little-bumpy-journey"


# ── logging ─────────────────────────────────────────────────────────────────

class Log:
    def __init__(self, path):
        self.path = path
        self.start = time.time()
        self.lines = []
        self.steps = []  # (film seconds, story step, result)

    def __call__(self, msg):
        line = f"[{time.time() - self.start:6.1f}s] {msg}"
        print(line, flush=True)
        self.lines.append(line)

    def trace(self, msg):
        self.lines.append(f"[{time.time() - self.start:6.1f}s] {msg}")

    def save(self, summary=None):
        out = [f"Little Bumpy film log, {datetime.now().isoformat(timespec='seconds')}", ""]
        out.append("Steps (time in the film, step, result):")
        for t, name, result in self.steps:
            out.append(f"  {t:5.1f}s  {name:<52} {result}")
        if summary:
            out += ["", summary]
        out += ["", "Run output:"] + self.lines
        self.path.write_text("\n".join(out) + "\n", encoding="utf-8")


def free_gb(path):
    return shutil.disk_usage(str(path.anchor or path)).free / 1e9


# ── the recorder: CDP screencast at full device pixels ─────────────────────

class Recorder:
    """Takes frames as fast as the browser can give them, each a screenshot at
    full device pixels (1125x2436), about 17 to 19 a second. Tried first and
    dropped: Chrome's screencast (with Playwright's phone emulation it only
    sends CSS-size 375x812 frames, the soft picture the owner complained
    about) and a raw CDP capture with clip scale 3 (it re-lays out the Flutter
    page between frames and the app stops responding to drags)."""

    def __init__(self, page):
        self.page = page
        self.frames = []  # (wall-clock seconds, jpeg bytes)
        self.cdp = None
        self.t0 = None
        self.running = False
        self.last_arrival = None
        self.task = None

    async def start(self):
        self.t0 = time.time()
        self.running = True
        self.task = asyncio.ensure_future(self._loop())

    async def _loop(self):
        while self.running:
            t = time.time()
            try:
                data = await self.page.screenshot(type="jpeg", quality=92, animations="allow",
                                                  caret="initial")
            except Exception:
                await asyncio.sleep(0.05)
                continue
            now = time.time()
            self.frames.append(((t + now) / 2, data))
            self.last_arrival = now

    def now(self):
        return time.time() - self.t0 if self.t0 else 0.0

    def fps(self):
        if len(self.frames) < 2:
            return 0.0
        return (len(self.frames) - 1) / (self.frames[-1][0] - self.frames[0][0])

    async def stop(self):
        self.t_end = time.time()
        self.running = False
        await self.task


# ── what a viewer sees: a dot for each tap, slow scrolls ───────────────────

DOT_JS = """([x, y, kind]) => {
  let d = document.getElementById('__film_dot');
  if (!d) {
    d = document.createElement('div');
    d.id = '__film_dot';
    d.style.cssText = 'position:fixed;z-index:2147483647;pointer-events:none;width:40px;height:40px;' +
      'margin:-20px 0 0 -20px;border-radius:50%;background:rgba(232,93,74,0.55);' +
      'border:3px solid rgba(255,255,255,0.95);box-shadow:0 0 0 2px rgba(90,40,60,0.35);' +
      'transition:transform 160ms ease-out, opacity 200ms ease-out;transform:scale(0.6);opacity:0';
    document.body.appendChild(d);
  }
  if (kind === 'hide') { d.style.opacity = '0'; d.style.transform = 'scale(0.6)'; return; }
  d.style.left = x + 'px'; d.style.top = y + 'px';
  d.style.opacity = '1';
  d.style.transform = kind === 'press' ? 'scale(0.8)' : 'scale(1)';
}"""


async def dot(page, x, y, kind="show"):
    await page.evaluate(DOT_JS, [x, y, kind])


async def tap_at(page, x, y):
    trace(f"    tap at ({x:.0f}, {y:.0f})")
    await dot(page, x, y, "show")
    await page.wait_for_timeout(450)
    await dot(page, x, y, "press")
    await page.touchscreen.tap(x, y)
    await page.wait_for_timeout(350)
    await dot(page, x, y, "hide")


async def slow_scroll(page, px, seconds=1.0):
    """Drag a finger up by px, slowly, with the dot under the finger, then hold
    still before lifting so the page stops instead of flinging."""
    x = W * 0.62
    y0 = H * 0.80
    y1 = max(y0 - px, H * 0.12)
    steps = max(12, int(seconds * 22))
    cdp = await page.context.new_cdp_session(page)
    try:
        await dot(page, x, y0)
        await page.wait_for_timeout(150)
        await cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x, "y": y0}]})
        for i in range(1, steps + 1):
            f = i / steps
            f = f * f * (3 - 2 * f)  # ease in and out
            y = y0 + (y1 - y0) * f
            await cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": x, "y": y}]})
            if i % 3 == 0:
                await dot(page, x, y)
            await asyncio.sleep(seconds / steps)
        await asyncio.sleep(0.25)
        await cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
    finally:
        await cdp.detach()
    await dot(page, x, y1, "hide")
    await page.wait_for_timeout(250)


TRACE = [None]  # set to the Log so finding and scrolling leave a trail in film-log.txt


def trace(msg):
    if TRACE[0]:
        TRACE[0].trace(msg)


async def locate(page, labels, role=None, max_h=0.45):
    """('visible'|'offscreen'|None, match) for the first label that matches.
    Boxes taller than max_h of the screen are skipped: a whole scrolling page
    carries every word on it, so it would always 'match' and never move."""
    best = (None, None)
    bottom = H if role == "tab" else await shoot.usable_bottom(page, H)
    for label in labels:
        found = await page.evaluate(shoot.FIND_JS, [label, role or ""])
        found = [m for m in found if m["h"] <= H * max_h and not m["disabled"]]
        for m in found:
            cx, cy = m["x"] + m["w"] / 2, m["y"] + m["h"] / 2
            if 0 <= cx <= W and 8 <= cy <= bottom - 8:
                return "visible", m
        if found and best[0] is None:
            best = ("offscreen", found[0])
    return best


async def bring_to(page, labels, anchor=0.22, role=None, max_scrolls=9, seconds=1.0,
                   fallback_px=None, step=0.6):
    """Scroll slowly until one of `labels` has its top near `anchor` (a fraction
    of the screen from the top). Returns the match or None. With fallback_px,
    words that have no box of their own are reached by scrolling that far.
    Flutter may drop a box from the accessibility tree once it is on screen,
    so the last place it was seen is kept and the page is scrolled by that."""
    last_y = None
    for n in range(max_scrolls + 1):
        where, m = await locate(page, labels, role)
        trace(f"    find {labels[0][:40]!r}: {where} "
              + (f"y={m['y']:.0f} h={m['h']:.0f}" if m else "")
              + (f" (last seen y={last_y:.0f})" if last_y is not None and not m else ""))
        if where is None and fallback_px and n == 0:
            trace(f"    no box for {labels[0][:40]!r}; scrolling {fallback_px:.0f} px by distance")
            await slow_scroll(page, fallback_px, seconds)
            return {"by_distance": True}
        if where is None and last_y is not None:
            if last_y > H * (anchor + 0.08):
                trace(f"    scroll {last_y - H * anchor:.0f} px to where it was last seen")
                await slow_scroll(page, last_y - H * anchor, seconds)
            return {"by_position": True}
        if where == "visible":
            if m["y"] <= H * (anchor + 0.08):
                return m
            dist = min(m["y"] - H * anchor, H * step)
        elif where == "offscreen" and m["y"] < 0:
            return m  # already passed it; this tool only scrolls down
        elif where == "offscreen":
            dist = min(m["y"] - H * anchor, H * step)
        else:
            dist = H * step
        before = await shoot.page_fingerprint(page)
        trace(f"    scroll {dist:.0f} px")
        await slow_scroll(page, dist, seconds)
        if m:
            last_y = m["y"] - dist
        if await shoot.page_fingerprint(page) == before:
            where, m = await locate(page, labels, role)
            trace(f"    page stopped moving; {labels[0][:40]!r} {where}")
            return m if where == "visible" else None
    where, m = await locate(page, labels, role)
    return m if where == "visible" else None


async def wait_for(page, labels, role=None, timeout=6.0):
    end = time.time() + timeout
    while time.time() < end:
        where, m = await locate(page, labels, role)
        if where == "visible":
            return m
        await asyncio.sleep(0.25)
    return None


async def tap_label(page, labels, role=None, timeout=6.0):
    m = await wait_for(page, labels, role, timeout)
    if not m:
        return None
    await tap_at(page, m["x"] + m["w"] / 2, m["y"] + m["h"] / 2)
    return m


async def to_get_help_card(page):
    """Step down through a guide's cards to "When to call". Card headings have
    no box of their own; the "Add to visit list: <question>" buttons of the
    card just before it do. Bring the last of them to the top of the screen,
    so the get-help card fills the screen under it."""
    m = await bring_to(page, ["When to call"], anchor=0.12, max_scrolls=0)
    if m and "x" in m:
        return m
    last_seen = None
    for _ in range(10):
        found = await page.evaluate(shoot.FIND_JS, ["Add to visit list", "button"])
        found = [f for f in found if f["h"] <= H * 0.2 and f["label"].lower().startswith("add to visit list")]
        if found:
            last = max(found, key=lambda f: f["y"])
            last_seen = last
            if last["y"] < H * 0.55:
                if last["y"] > H * 0.1:
                    trace(f"    last 'Add to visit list' at y={last['y']:.0f}; scroll to the card after it")
                    await slow_scroll(page, last["y"] - H * 0.04, 1.0)
                return {"by_position": True}
            dist = min(last["y"] - H * 0.04, H * 0.85)
        else:
            dist = H * 0.85
        before = await shoot.page_fingerprint(page)
        trace(f"    guide: scroll {dist:.0f} px")
        await slow_scroll(page, dist, 0.8)
        if await shoot.page_fingerprint(page) == before:
            break
    return {"by_position": True} if last_seen else None


# ── the story ───────────────────────────────────────────────────────────────

def chapter_words(app, week):
    """The chapter's own words for this week, from the checkout's content file,
    so the film finds each part of the page by what it says, however it is
    styled. Long texts are cut to their opening words (matched as 'starts with')."""
    def opening(text, n=6):
        return " ".join(text.split()[:n])
    words = {"title": "", "know": "", "ready": "", "question": "", "forward": "", "curious": "",
             "need": ""}
    try:
        rows = json.loads((app / "assets" / "content" / "chapters.json").read_text(encoding="utf-8"))
        for r in rows:
            if r["from_week"] <= week <= r["to_week"]:
                words.update(title=r.get("title", ""),
                             know=opening(r.get("know", {}).get("text", "")),
                             ready=opening(r.get("ready", {}).get("text", "")),
                             question=opening(r.get("ready", {}).get("suggested_question", "")),
                             forward=opening(r.get("look_forward", {}).get("text", "")),
                             curious=r.get("curious", {}).get("question", ""),
                             need=r.get("curious", {}).get("need", "").capitalize())
                break
    except Exception:
        pass
    return words


def present(*labels):
    return [w for w in labels if w]


class Story:
    def __init__(self, page, rec, log, out, words):
        self.page, self.rec, self.log, self.out, self.words = page, rec, log, out, words
        self.reached, self.missed = 0, 0
        self.poster_done = False

    def mark(self, name, ok, why=""):
        t = self.rec.now()
        result = "reached" if ok else f"not reached: {why or name}"
        self.log.steps.append((t, name, result))
        if ok:
            self.reached += 1
        else:
            self.missed += 1
        self.log(f"  film {t:5.1f}s  {name}: {result}")
        return ok

    def about(self, name):
        self.log(f"Next: {name} (film {self.rec.now():.1f}s)")

    async def hold(self, seconds):
        await self.page.wait_for_timeout(int(seconds * 1000))

    async def poster(self):
        if self.poster_done:
            return
        await self.page.screenshot(path=str(self.out / "poster.png"))
        self.poster_done = True
        self.log("  poster.png saved (full device pixels)")

    async def run(self):
        p, w = self.page, self.words
        # 1. Today
        self.about("1 Today: Bumpy in the nursery")
        ok = await wait_for(p, ["Bumpy in"], timeout=4)
        self.mark("1a Today: Bumpy in the nursery in costume", bool(ok), "see 'Bumpy in'")
        await self.hold(2.0)
        self.about("1 Today: the fact card")
        # The fact card's heading has no box of its own; its source line does.
        m = await bring_to(p, ["Good to know", "Source:"], anchor=0.45, fallback_px=180)
        self.mark("1b Today: the fact card", bool(m), "scroll to the fact card")
        await self.hold(2.4)

        # 2. This Week
        self.about("2 This Week: the chapter")
        m = await tap_label(p, ["This Week"], "tab")
        if not m:
            self.mark("2a This Week tab", False, "tap 'This Week' (tab)")
        else:
            await self.hold(0.8)
            ok = await wait_for(p, present(w["title"], "Weeks ", "Bumpy says"))
            self.mark("2a This Week: chapter picture and title", bool(ok),
                      f"see '{w['title'] or 'the chapter'}'")
            await self.hold(1.4)
            await self.poster()
            await self.hold(0.3)
            # Headings have no box of their own; the text under each one does.
            m = await bring_to(p, present(w["know"], "One thing to know"), anchor=0.28, fallback_px=480)
            self.mark("2b chapter: 'One thing to know'", bool(m), "scroll to 'One thing to know'")
            await self.hold(2.8)
            m = await bring_to(p, present(w["ready"], "One thing to get ready"), anchor=0.22, fallback_px=380)
            self.mark("2c chapter: 'One thing to get ready'", bool(m), "scroll to 'One thing to get ready'")
            await self.hold(2.3)

            # 3. Add the chapter's question to the visit list
            self.about("3 Add the chapter's question to the visit list")
            m = await bring_to(p, ["Add to my visit list"], anchor=0.45, role="button")
            if m and "x" in m:
                await self.hold(0.3)
                await tap_at(p, m["x"] + m["w"] / 2, m["y"] + m["h"] / 2)
                done = await wait_for(p, ["On your list:"], timeout=4)
                self.mark("3 tap 'Add to my visit list', see 'On your list:'", bool(done),
                          "see 'On your list:'")
                await self.hold(2.1)
            else:
                self.mark("3 tap 'Add to my visit list'", False, "tap 'Add to my visit list'")

            m = await bring_to(p, present(w["forward"], "Something to look forward to"), anchor=0.32,
                               fallback_px=300)
            self.mark("2d chapter: 'Something to look forward to'", bool(m),
                      "scroll to 'Something to look forward to'")
            await self.hold(2.2)

            # 4. The curious question opens its guide
            self.about("4 Follow the curious question into the guide")
            m = await bring_to(p, [w["curious"]], anchor=0.55) if w["curious"] else None
            if m and "x" in m:
                await self.hold(0.3)
                await tap_at(p, m["x"] + m["w"] / 2, m["y"] + m["h"] / 2)
                # The guide's title bar ("Rest guide") and its Back button are
                # the small boxes that prove the page opened.
                ok = await wait_for(p, present(f"{w['need']} guide" if w["need"] else "", "Back"),
                                    timeout=9)
                self.mark("4a guide opens from the curious question", bool(ok), "see the guide page")
                if ok:
                    await self.hold(1.3)
                    m = await to_get_help_card(p)
                    self.mark("4b guide: 'When to call' card", bool(m), "scroll to 'When to call'")
                    await self.hold(3.2)
            else:
                self.mark("4a tap the curious question", False,
                          f"tap '{w['curious'] or 'curious question (no chapter this week)'}'")

        # 5. Back to Today, the visit card, Show at my visit
        self.about("5 Back to Today and show the visit list")
        where, _ = await locate(p, ["Today"], "tab")
        if where != "visible":
            await tap_label(p, ["Back"], "button", timeout=3)
            await self.hold(0.3)
        m = await tap_label(p, ["Today"], "tab", timeout=4)
        if not m:
            self.mark("5a back to Today", False, "tap 'Today' (tab)")
            return
        await self.hold(0.4)
        m = await bring_to(p, [OWN_QUESTION, "For your visit"], anchor=0.40)
        self.mark("5a Today: 'For your visit' card", bool(m), "scroll to 'For your visit'")
        await self.hold(1.6)
        m = await bring_to(p, ["Show at my visit"], anchor=0.6, role="button")
        if not (m and "x" in m):
            self.mark("5b tap 'Show at my visit'", False, "tap 'Show at my visit'")
            return
        await tap_at(p, m["x"] + m["w"] / 2, m["y"] + m["h"] / 2)
        ok = await wait_for(p, [OWN_QUESTION], timeout=5)
        self.mark("5b 'Show at my visit': the parent's own question", bool(ok), f"see '{OWN_QUESTION}'")
        await self.hold(4.1)


# ── assembling the film ─────────────────────────────────────────────────────

def ffmpeg_path():
    return shutil.which("ffmpeg")


def ffmpeg_has(ff, encoder):
    try:
        out = subprocess.run([ff, "-hide_banner", "-encoders"], capture_output=True, text=True, timeout=30).stdout
        return f" {encoder} " in out
    except Exception:
        return False


def frame_times(rec):
    """Start time of the film and its end, on the browser's frame clock."""
    t_first = rec.frames[0][0]
    return t_first, rec.frames[-1][0] + max(rec.t_end - rec.last_arrival, 0.04)


def timeline(rec, fps):
    """One frame index per tick at a constant rate: the newest frame the camera
    had at that moment (frames come as fast as the browser renders them)."""
    frames = rec.frames
    t_first, t_end = frame_times(rec)
    out, i, n = [], 0, int((t_end - t_first) * fps)
    for k in range(n):
        t = t_first + k / fps
        while i + 1 < len(frames) and frames[i + 1][0] <= t:
            i += 1
        out.append(i)
    return out


def encode(ff, rec, out_file, codec, log):
    """Pipe the frames into ffmpeg at a constant FPS (real timing kept)."""
    vf = "pad=ceil(iw/2)*2:ceil(ih/2)*2:color=white,format=yuv420p"
    if codec == "libx264":
        args = ["-c:v", "libx264", "-preset", "slow", "-crf", "16", "-tune", "animation",
                "-movflags", "+faststart"]
    else:
        args = ["-c:v", codec, "-b:v", "0", "-crf", "24", "-deadline", "good", "-row-mt", "1"]
    cmd = [ff, "-y", "-hide_banner", "-loglevel", "error", "-f", "image2pipe", "-framerate", str(FPS),
           "-c:v", "mjpeg", "-i", "-", "-vf", vf, "-r", str(FPS), *args, str(out_file)]
    ticks = timeline(rec, FPS)
    log(f"  ffmpeg {codec} -> {out_file.name} ({len(ticks)} frames at {FPS} fps)")
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
    try:
        for k, i in enumerate(ticks):
            proc.stdin.write(rec.frames[i][1])
            if k % (FPS * 15) == 0 and k:
                log(f"    {k} of {len(ticks)} frames")
        proc.stdin.close()
    except (BrokenPipeError, OSError):
        pass
    err = proc.stderr.read().decode("utf-8", "replace")
    if proc.wait() != 0:
        log(f"  ffmpeg failed: {err.strip()[:300]}")
        return False
    return True


def make_webp(rec, out_file, log, limit_mb=15):
    """Animated WebP with Pillow: 10 frames a second at phone CSS size x2 width
    750 first, smaller if it is over the size limit."""
    frames = rec.frames
    t_first, t_end = frame_times(rec)
    for width, quality in ((750, 80), (600, 72), (450, 65), (375, 60)):
        step = 0.1
        imgs, t, i = [], t_first, 0
        while t < t_end:
            while i + 1 < len(frames) and frames[i + 1][0] <= t:
                i += 1
            img = Image.open(io.BytesIO(frames[i][1])).convert("RGB")
            imgs.append(img.resize((width, round(img.height * width / img.width)), Image.LANCZOS))
            t += step
        imgs[0].save(out_file, save_all=True, append_images=imgs[1:], duration=int(step * 1000),
                     loop=0, quality=quality, method=4)
        mb = out_file.stat().st_size / 1e6
        log(f"  WebP {width}px q{quality}: {mb:.1f} MB")
        if mb <= limit_mb:
            return True
    log("  WebP stayed over the size limit at the smallest setting")
    return False


# ── main ────────────────────────────────────────────────────────────────────

async def record(url, prefs, out, log, words):
    async with async_playwright() as pw:
        try:
            browser = await pw.chromium.launch(headless=True)
            log("Browser: Playwright Chromium (headless)")
        except Exception:
            browser = await pw.chromium.launch(headless=True, channel="msedge")
            log("Browser: Microsoft Edge (headless)")
        context = await browser.new_context(
            viewport={"width": W, "height": H}, device_scale_factor=SCALE, is_mobile=True,
            has_touch=True, reduced_motion="no-preference", service_workers="block")
        await context.clock.set_fixed_time(shoot.FIXED_NOW)
        await context.add_init_script(shoot.init_script(prefs))
        blocked = set()

        async def gate(route):
            if route.request.url.startswith(url):
                await route.continue_()
            else:
                blocked.add(route.request.url)
                await route.abort()
        await context.route("**/*", gate)
        page = await context.new_page()
        log("Opening the app and waiting for its first frame ...")
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
        await page.locator("flt-semantics-placeholder").dispatch_event("click")
        await page.wait_for_selector("flt-semantics", state="attached", timeout=10000)
        # CanvasKit, fonts and the nursery picture settle before the camera rolls,
        # so the film never opens on a blank or half-drawn screen.
        await page.wait_for_timeout(3000)
        log("App is drawn. Recording starts.")
        rec = Recorder(page)
        await rec.start()
        TRACE[0] = log
        story = Story(page, rec, log, out, words)
        try:
            await story.run()
        except Exception as exc:
            story.mark("story stopped", False, f"error: {str(exc).splitlines()[0][:200]}")
        await rec.stop()
        if not story.poster_done:
            await page.screenshot(path=str(out / "poster.png"))
        await context.close()
        await browser.close()
        if blocked:
            log(f"Note: blocked {len(blocked)} request(s) to other hosts")
        return rec, story


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=Path, required=True, help="folder for the film, poster and log")
    ap.add_argument("--app", type=Path, default=shoot.HERE_APP, help="checkout to film (default: this one)")
    ap.add_argument("--review", action="store_true", help="profile build with BUMPY_REVIEW=true (drafts show)")
    ap.add_argument("--look", choices=["everyday", "halloween"], default="everyday")
    ap.add_argument("--week", type=int, default=DEFAULT_WEEK, help="pregnancy week (default 20)")
    ap.add_argument("--no-build", action="store_true", help="do not build; film an existing web build")
    ap.add_argument("--web", type=Path, help="with --no-build: the built web folder (default <app>/build/web)")
    ap.add_argument("--keep-build", action="store_true", help="keep <app>/build afterwards (to film again)")
    ap.add_argument("--scale", type=float, default=3, choices=[2, 2.5, 3],
                    help="device scale of the phone (default 3 = 1125x2436 frames)")
    ap.add_argument("--webp", action="store_true", help="also make the animated WebP when an MP4 was made")
    args = ap.parse_args()

    global SCALE
    SCALE = args.scale
    app = args.app.resolve()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    log = Log(out / "film-log.txt")
    print(f"Little Bumpy film: {app} -> {out}", flush=True)
    print(f"Log file: {log.path}", flush=True)
    if not (app / "pubspec.yaml").is_file():
        raise SystemExit(f"--app {app} has no pubspec.yaml; is it a Little Bumpy checkout?")
    if free_gb(out) < MIN_FREE_GB:
        raise SystemExit(f"Stopped: only {free_gb(out):.1f} GB free on the disk (need {MIN_FREE_GB} GB).")

    web = (args.web.resolve() if args.web else app / "build" / "web")
    built_here = False
    if args.no_build:
        kind = shoot.existing_build_kind(web)
        log(f"Build skipped (--no-build); {web} is {kind}")
        if args.review and not kind.startswith("profile+review"):
            log("Warning: --review asked for, but this is not a review build; draft chapters will not show.")
    else:
        log("Step: build the web app (a few minutes) ...")
        kind = shoot.build(app, args.review, log.start)
        built_here = True
    if not (web / "main.dart.js").is_file():
        raise SystemExit(f"{web} has no main.dart.js; build it first (drop --no-build)")

    words = chapter_words(app, args.week)
    prefs = shoot.seed_for(args.look, {"week": args.week, "visit_topics": [f"question:{OWN_QUESTION}"]}, None)
    log(f"Seeded state: look {args.look}, week {args.week}, visit list ['{OWN_QUESTION}'], "
        f"clock {shoot.FIXED_NOW.isoformat()}")
    server, url = shoot.serve(web)
    log(f"Serving {web} at {url} (other hosts blocked)")
    try:
        rec, story = asyncio.run(record(url, prefs, out, log, words))
    finally:
        server.shutdown()

    length = (lambda a, b: b - a)(*frame_times(rec)) if rec.frames else 0.0
    log(f"Recorded {len(rec.frames)} frames at {W * SCALE:g}x{H * SCALE:g}, {length:.1f} s of film "
        f"(about {rec.fps():.0f} frames a second, played at {FPS})")
    if not rec.frames:
        log.save("FAILED: no frames were recorded.")
        raise SystemExit("No frames recorded.")

    # Encode: ffmpeg H.264 MP4, else ffmpeg VP9 WebM, else animated WebP only.
    log("Step: encode the film ...")
    film, path_taken = None, None
    ff = ffmpeg_path()
    if ff:
        if ffmpeg_has(ff, "libx264") and encode(ff, rec, out / f"{NAME}.mp4", "libx264", log):
            film, path_taken = out / f"{NAME}.mp4", f"ffmpeg on PATH ({ff}), H.264 MP4"
        elif ffmpeg_has(ff, "libvpx-vp9") and encode(ff, rec, out / f"{NAME}.webm", "libvpx-vp9", log):
            film, path_taken = out / f"{NAME}.webm", f"ffmpeg on PATH ({ff}), VP9 WebM"
    else:
        log("  no ffmpeg on PATH")
    webp = None
    if film is None or film.suffix != ".mp4" or args.webp:
        log("Step: animated WebP (plays anywhere) ...")
        if make_webp(rec, out / f"{NAME}.webp", log):
            webp = out / f"{NAME}.webp"
            if film is None:
                path_taken = "Pillow animated WebP only (no ffmpeg encoder found)"
    log(f"Encoder path: {path_taken or 'none'}")

    if built_here and not args.keep_build:
        shutil.rmtree(app / "build", ignore_errors=True)
        log(f"Deleted {app / 'build'}")
    elif built_here:
        log(f"Kept {app / 'build'} (--keep-build); delete it when done")

    made = [f for f in (film, webp, out / "poster.png") if f and f.exists()]
    sizes = ", ".join(f"{f.name} {f.stat().st_size / 1e6:.1f} MB" for f in made)
    summary = (f"Done: {length:.0f} s film ({kind} build, {args.look} look, week {args.week}); "
               f"{story.reached} steps reached, {story.missed} not reached; {sizes or 'no files'}. "
               f"Encoder: {path_taken or 'none'}.")
    if length < 40 or length > 60:
        summary += f" Note: length {length:.0f} s is outside 40 to 60 s."
    nxt = ("Next: watch the film, then read film-log.txt for any 'not reached' line."
           if story.missed == 0 and film else
           "Next: read the 'not reached' lines in film-log.txt; a renamed button means updating its words in film.py.")
    log.save(summary + "\n" + nxt)
    print(summary, flush=True)
    print(nxt, flush=True)
    return 0 if film or webp else 1


if __name__ == "__main__":
    sys.exit(main())
