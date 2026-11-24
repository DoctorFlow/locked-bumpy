"""Photograph the real Little Bumpy web build in a headless browser.

Shell: any (Windows PowerShell or bash). Run as a normal user.

    python tool/camera/shoot.py --out <folder> [--skip-build] [--only today-fresh,guides]

Builds the release web app (CanvasKit and fonts served locally), serves
build/web on a free 127.0.0.1 port, seeds the app's saved state in
localStorage before Flutter starts, then walks the shot list with Playwright.
Every request to any other host is blocked, so the pictures prove the
renderer works with no internet.
"""
import argparse
import asyncio
import functools
import http.server
import json
import re
import socket
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from playwright.async_api import async_playwright

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / "build" / "web"
FLUTTER = Path(r"C:\Users\owner\projects\avatar-harness-bumpy-studio\tools\run\flutter-entry-sdk\bin\flutter.bat")

# The app's day: Monday 2026-11-23 is rotation day 0 (IRON, vampire).
# Check-ins that day are iron, water, vitamin. Due date gives week 24.
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

# Each screen: seed (saved prefs, without the "flutter." prefix), and the
# clicks to make, by accessible name, after the accessibility tree is on.
SCREENS = [
    ("welcome", {"setup": False}, []),
    ("today-fresh", {}, []),
    ("today-one-done", {"daily_needs_v2": [TODAY, "iron"]}, []),
    ("today-all-done", {"daily_needs_v2": [TODAY, "iron", "water", "vitamin"]}, []),
    ("wardrobe", {}, [("button", "Wardrobe")]),
    ("this-week", {}, [("tab", "This Week")]),
    ("guides", {}, [("tab", "Guides")]),
    ("guide-open", {}, [("tab", "Guides"), ("button", "Iron")]),
    ("visit-list", {"visit_topics": ["iron"]}, [("tab", "Guides"), ("button", "Edit visit list")]),
    ("settings", {}, [("button", "Settings")]),
    ("paused", {"is_paused": True}, []),
]
# The wardrobe button only exists in the Halloween look.
NOT_IN_LOOK = {("wardrobe", "everyday"): "the wardrobe exists only in the Halloween look"}


def log(start, msg):
    print(f"[{time.time() - start:6.1f}s] {msg}", flush=True)


def seed_for(look, extra):
    extra = dict(extra)
    prefs = {"is_halloween": look == "halloween"}
    if extra.pop("setup", True):
        prefs.update({"due_date_iso": DUE_DATE, "skin_tone": "peach", "baby_nickname": "",
                      "is_paused": False})
    prefs.update(extra)
    return prefs


def init_script(prefs):
    # shared_preferences on web: localStorage["flutter.<key>"] = JSON of the value.
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

def build(start):
    log(start, f"Building web release with {FLUTTER} ...")
    cmd = [str(FLUTTER), "build", "web", "--release", "--no-web-resources-cdn"]
    result = subprocess.run(cmd, cwd=ROOT, shell=False)
    if result.returncode != 0:
        raise SystemExit("flutter build web failed (exit %d)" % result.returncode)
    log(start, "Build saved to build/web")


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".js": "text/javascript", ".mjs": "text/javascript",
                      ".wasm": "application/wasm", ".json": "application/json",
                      ".png": "image/png", ".webp": "image/webp", ".woff2": "font/woff2",
                      ".ttf": "font/ttf", ".otf": "font/otf", ".html": "text/html"}

    def log_message(self, *args):
        pass


def serve():
    sock = socket.socket()
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
    sock.close()
    # The default listen backlog (5) refuses connections when several pages
    # fetch CanvasKit and assets at once; that showed as "Failed to fetch".
    server_class = type("Server", (http.server.ThreadingHTTPServer,), {"request_queue_size": 256})
    server = server_class(
        ("127.0.0.1", port), functools.partial(Handler, directory=str(WEB)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server, f"http://127.0.0.1:{port}/"


# ── one shot ────────────────────────────────────────────────────────────────

async def click_named(page, role, name, timeout=10.0):
    """Click a semantic node by role and accessible name; fall back to text."""
    pattern = re.compile(re.escape(name), re.I)
    candidates = [
        page.get_by_role(role, name=pattern),
        page.get_by_role("button", name=pattern),
        page.get_by_role("tab", name=pattern),
        page.locator(f'flt-semantics[aria-label*="{name}" i]'),
        page.locator("flt-semantics").filter(has_text=pattern),
    ]
    deadline = time.time() + timeout
    while time.time() < deadline:
        for loc in candidates:
            if await loc.count():
                target = loc.first
                box = await target.bounding_box()
                if box and box["width"] > 0:
                    # Tap the node's centre like a finger (Flutter listens to
                    # pointer events on its own pane). A touch, not a mouse,
                    # so no hover tooltip is left on the next screen.
                    await page.touchscreen.tap(box["x"] + box["width"] / 2, box["y"] + box["height"] / 2)
                    return
        await asyncio.sleep(0.25)
    raise RuntimeError(f"no {role} named {name!r} on screen")


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
            await page.wait_for_selector("#opening", state="detached", timeout=20000)
            break
        except Exception:
            if attempt == 2:
                raise RuntimeError("app never drew its first frame (still on the opening screen)")
    await page.wait_for_function(
        "() => !!document.querySelector('flt-semantics-placeholder, flt-glass-pane, flutter-view')",
        timeout=10000)
    await page.locator("flt-semantics-placeholder").dispatch_event("click")
    await page.wait_for_selector("flt-semantics", state="attached", timeout=10000)
    await page.wait_for_timeout(900)  # images decode, fonts settle
    return context, page


async def shoot_one(browser, url, out, job, start, counter, total, blocked):
    name, look, (w, h, s), prefs, clicks = job["screen"], job["look"], job["size"], job["prefs"], job["_clicks"]
    t0 = time.time()
    context = None
    try:
        context, page = await open_app(browser, url, w, h, s, prefs, blocked)
        for role, label in clicks:
            await click_named(page, role, label)
            await page.wait_for_timeout(700)
        await page.wait_for_timeout(500)
        path = out / job["file"]
        await page.screenshot(path=str(path))
        if (w, h, s) == SHEET_SIZE and name in ("today-fresh", "wardrobe"):
            await crops(page, path, name, look, s, out)
        job.update(ok=True, error=None)
    except Exception as exc:  # keep going; the manifest records the failure
        job.update(ok=False, error=str(exc).splitlines()[0][:300])
    finally:
        if context:
            await context.close()
    job["seconds"] = round(time.time() - t0, 1)
    counter[0] += 1
    status = "ok" if job["ok"] else "FAILED: " + job["error"]
    log(start, f"{counter[0]} of {total}  {job['file']}  {status}")


async def crops(page, path, name, look, scale, out):
    if name == "today-fresh":
        loc = page.get_by_role("img", name=re.compile("^Bumpy in"))
        stem, trim = f"crop-bumpy__{look}", None
    else:
        loc = page.get_by_role("button", name=re.compile(r"^Try Vampire"))
        stem, trim = f"crop-wardrobe-thumb__{look}", 65  # thumbnail strip height
    box = await loc.first.bounding_box()
    if not box:
        raise RuntimeError(f"no box for {stem}")
    height = trim if trim else box["height"]
    img = Image.open(path)
    rect = tuple(round(v * scale) for v in (box["x"], box["y"], box["x"] + box["width"], box["y"] + height))
    crop = img.crop(rect)
    crop.save(out / f"{stem}.png")
    crop.resize((crop.width * 2, crop.height * 2), Image.NEAREST).save(out / f"{stem}__x2.png")


# ── contact sheets ──────────────────────────────────────────────────────────

def contact_sheet(out, look, jobs, start):
    w, h, s = SHEET_SIZE
    items = [j for j in jobs if j["look"] == look and j["size"] == SHEET_SIZE and j["ok"]]
    if not items:
        log(start, f"sheet__{look}.png skipped: no shots")
        return
    cols = 6
    gap, label_h, max_w = 16, 34, 2400
    tw = (max_w - gap * (cols + 1)) // cols
    th = round(tw * h / w)
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (max_w, gap + rows * (th + label_h + gap)), (245, 242, 236))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 20)
    except OSError:
        font = ImageFont.load_default()
    for i, job in enumerate(items):
        x = gap + (i % cols) * (tw + gap)
        y = gap + (i // cols) * (th + label_h + gap)
        thumb = Image.open(out / job["file"]).convert("RGB").resize((tw, th), Image.LANCZOS)
        draw.text((x, y + 4), job["screen"], fill=(30, 20, 40), font=font)
        sheet.paste(thumb, (x, y + label_h))
        draw.rectangle([x - 1, y + label_h - 1, x + tw, y + label_h + th], outline=(180, 170, 160))
    name = f"sheet__{look}.png"
    sheet.save(out / name)
    log(start, f"{name} saved ({len(items)} screens, {sheet.width}x{sheet.height})")


# ── main ────────────────────────────────────────────────────────────────────

async def run(url, out, jobs, start, blocked):
    async with async_playwright() as p:
        try:
            browser = await p.chromium.launch(headless=True)
            log(start, "Browser: Playwright Chromium (headless)")
        except Exception:
            browser = await p.chromium.launch(headless=True, channel="msedge")
            log(start, "Browser: Microsoft Edge (headless)")
        gate = asyncio.Semaphore(CONCURRENCY)
        counter = [0]
        todo = [j for j in jobs if j["ok"] is None]

        async def guarded(job):
            async with gate:
                await shoot_one(browser, url, out, job, start, counter, len(todo), blocked)
        await asyncio.gather(*(guarded(j) for j in todo))
        await browser.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--only", help="comma-separated screen names")
    args = parser.parse_args()
    start = time.time()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    print(f"Little Bumpy camera -> {out}", flush=True)

    if args.skip_build:
        log(start, "Build skipped (--skip-build)")
    else:
        build(start)
    if not (WEB / "main.dart.js").is_file() or not (WEB / "canvaskit" / "canvaskit.wasm").is_file():
        raise SystemExit("build/web is missing main.dart.js or local CanvasKit; run without --skip-build")

    only = set(args.only.split(",")) if args.only else None
    jobs = []
    for name, extra, clicks in SCREENS:
        if only and name not in only:
            continue
        for look in LOOKS:
            for size in SIZES:
                prefs = seed_for(look, extra)
                job = {"file": f"{name}__{look}__{size_tag(*size)}.png", "screen": name, "look": look,
                       "size": size, "viewport": f"{size[0]}x{size[1]}", "device_scale": size[2],
                       "state": prefs, "clicks": [c[1] for c in clicks], "clock": FIXED_NOW.isoformat(),
                       "ok": None, "error": None}
                if (name, look) in NOT_IN_LOOK:
                    job.update(ok=False, skipped=True, error="not applicable: " + NOT_IN_LOOK[(name, look)])
                jobs.append(job)
                job["prefs"] = prefs
                job["_clicks"] = clicks

    server, url = serve()
    log(start, f"Serving build/web at {url} (other hosts blocked)")
    shoot_start = time.time()
    blocked = set()
    try:
        asyncio.run(run(url, out, jobs, start, blocked))
    finally:
        server.shutdown()
    log(start, f"Shots took {time.time() - shoot_start:.0f}s")

    for look in LOOKS:
        contact_sheet(out, look, jobs, start)

    for j in jobs:
        j.pop("prefs", None)
        j.pop("_clicks", None)
        j["size"] = size_tag(*j["size"])
    shot = [j for j in jobs if not j.get("skipped")]
    ok = sum(1 for j in shot if j["ok"])
    failed = len(shot) - ok
    skipped = len(jobs) - len(shot)
    manifest = {"made": datetime.now().isoformat(timespec="seconds"), "app_clock": FIXED_NOW.isoformat(),
                "url": url, "blocked_requests": sorted(blocked), "ok": ok, "failed": failed,
                "not_applicable": skipped, "shots": jobs}
    (out / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    if blocked:
        print(f"Note: blocked {len(blocked)} request(s) to other hosts; see manifest.json", flush=True)
    print(f"shots: {ok} ok, {failed} failed ({skipped} not applicable) -> {out}", flush=True)
    print("Next: open the sheet__*.png files, then manifest.json for any failure." if not failed
          else "Next: read the failed entries in manifest.json and rerun with --skip-build --only <screen>.",
          flush=True)
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
