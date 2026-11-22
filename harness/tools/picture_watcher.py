"""Picture watcher: asks Antigravity's command-line tool (agy) for pictures, one at a time, from a queue.
It waits out each quota reset by itself, saves every picture with a record line, and rebuilds the gallery.

Shell: Windows PowerShell or bash, as a normal user (never as admin).
Run from the repository root:
  python harness/tools/picture_watcher.py --check        # checks the queue and agy, generates nothing
  python harness/tools/picture_watcher.py                # runs until you stop it
  python harness/tools/picture_watcher.py --commit       # also commits each picture on the current branch
  python harness/tools/picture_watcher.py --commit --push  # and pushes the current branch (never main)
Stop: create the file harness/tools/STOP (it stops before its next call), or close the window.

Each round:
 1. Reads harness/tools/queue.json (you can edit it while the watcher runs; it rereads it every time).
 2. Picks the next job still missing a picture (a job can ask for several takes).
 3. Asks agy for one picture, attaching up to 3 reference pictures.
 4. Saved: copies it to harness/pictures/, adds a line to harness/pictures/records.jsonl, rebuilds gallery.html.
 5. Quota used up: reads the exact reset time from agy's log, waits until then plus 3 minutes, carries on.
 6. Queue done: checks for new jobs every 10 minutes (or stops, with --exit-when-done).
Prints every step. Log: harness/tools/picture_watcher.log. Never uses --dangerously-skip-permissions.

Origin: written 2026-11-22 for Karan's private avatar harness; MIT licence (harness/LICENSE).
"""
import argparse, datetime, glob, hashlib, json, os, re, shutil, subprocess, sys, time

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # the harness folder
TOOLS = os.path.join(HERE, "tools")
QUEUE = os.path.join(TOOLS, "queue.json")
LOG = os.path.join(TOOLS, "picture_watcher.log")
LOCK = os.path.join(TOOLS, "picture_watcher.lock")
STOP = os.path.join(TOOLS, "STOP")
OUT = os.path.join(HERE, "pictures")
REC = os.path.join(OUT, "records.jsonl")
RUN = os.path.join(TOOLS, "run")                   # empty working folder for agy (git-ignored)
BRAINS = ["~/.gemini/antigravity-cli/brain", "~/.gemini/antigravity/brain"]   # where agy saves pictures
IMG = (".png", ".jpg", ".jpeg", ".webp")

def log(msg):
    line = f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S} {msg}"
    print(line, flush=True)
    with open(LOG, "a", encoding="utf-8") as f: f.write(line + "\n")

def load_queue():
    try:
        with open(QUEUE, encoding="utf-8") as f: return json.load(f)
    except FileNotFoundError:
        return None
    except Exception as e:
        log(f"WARNING: could not read queue.json: {e}"); return []

def save_queue(jobs):
    with open(QUEUE, "w", encoding="utf-8") as f: json.dump(jobs, f, indent=1, ensure_ascii=False)

def saved(stem):
    for ext in IMG:
        p = os.path.join(OUT, stem + ext)
        if os.path.exists(p): return p
    return None

def resolve_ref(r):
    """A reference is a saved picture's name (no extension) or a path from the repository root."""
    for p in (saved(r), os.path.join(OUT, r), os.path.join(os.getcwd(), r), os.path.join(HERE, r)):
        if p and os.path.exists(p): return os.path.abspath(p).replace("\\", "/")
    return None

def stems(job):
    return [job["name"] if t == 1 else f"{job['name']}__take{t}" for t in range(1, int(job.get("takes", 1)) + 1)]

def next_job(jobs):
    names = {j.get("name") for j in jobs}
    for j in jobs:
        if any(r in names and not resolve_ref(r) for r in j.get("refs", [])):
            continue   # waits for a reference picture that another job will make first
        for stem in stems(j):
            if not saved(stem) and j.get("failed", 0) < 2: return j, stem
    return None, None

def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True, encoding="utf-8", errors="replace")
    return r.returncode, (r.stdout + r.stderr).strip()

def commit(files, message, push):
    git("add", "--", *files)
    code, out = git("commit", "-q", "-m", message)
    if code != 0 and "nothing to commit" not in out:
        log(f"  git commit failed: {out[:200]}"); return
    log("  committed")
    if push:
        _, branch = git("rev-parse", "--abbrev-ref", "HEAD")
        if branch in ("main", "master"):
            log("  not pushing: you are on main. Work on a branch and open a pull request."); return
        code, out = git("push", "-q", "-u", "origin", branch)
        log(f"  pushed {branch}" if code == 0 else f"  push failed (tries again with the next picture): {out[:200]}")

def find_image(conv, stem, since):
    found = []
    for b in BRAINS:
        b = os.path.expanduser(b)
        if conv:
            for p in glob.glob(os.path.join(b, conv, "**", "*"), recursive=True):
                if p.lower().endswith(IMG) and os.path.getmtime(p) >= since - 5: found.append(p)
        for p in glob.glob(os.path.join(b, "*", stem + "*")):
            if p.lower().endswith(IMG) and os.path.getmtime(p) >= since - 5: found.append(p)
    return max(found, key=os.path.getmtime) if found else None

def call_agy(stem, job, refs, model):
    ask = (f"Call the image generation tool exactly once with these fields. Pass the prompt word for word; do not rewrite or extend it. "
           f"ImageName: {stem}. AspectRatio: {job.get('ratio', '1:1')}. ImagePaths: {', '.join(refs) if refs else 'none'}. "
           f"Prompt: {job['prompt']} Then answer with only the full path of the saved file. Do not run any other tool.")
    agylog = os.path.join(RUN, "agy-last.log")
    t0 = time.time()
    try:
        r = subprocess.run(["agy", "-p", ask, "--model", model, "--output-format", "json", "--print-timeout", "420s", "--log-file", agylog],
                           cwd=RUN, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=480)
        lines = [l for l in r.stdout.strip().splitlines() if l.strip().startswith("{")]
        data = json.loads(lines[-1]) if lines else {}
    except Exception as e:
        return "error", str(e)[:200], None, t0
    resp, conv = data.get("response", ""), data.get("conversation_id", "")
    img = find_image(conv, stem, t0)
    if img: return "saved", img, conv, t0
    text = ""
    try: text = open(agylog, encoding="utf-8", errors="replace").read()
    except Exception: pass
    if re.search(r"429|RESOURCE_EXHAUSTED|quota", resp + text[-20000:], re.I):
        stamps = re.findall(r'quotaResetTimeStamp"?\s*[:=]\s*"?(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ)', text)
        if stamps:   # the exact reset time Google reports, in UTC
            reset = datetime.datetime.strptime(stamps[-1], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc).timestamp()
            return "quota", max(60, int(reset - time.time())), conv, t0
        h = re.search(r"(\d+)\s*h", resp); m = re.search(r"(\d+)\s*m(?:in)?\b", resp)
        wait = (int(h.group(1)) * 3600 if h else 0) + (int(m.group(1)) * 60 if m else 0)
        return "quota", wait or 1200, conv, t0
    return "no-image", (resp or r.stderr or "")[:300].replace("\n", " "), conv, t0

def check(jobs):
    """Checks everything without generating. Returns the number of problems."""
    problems = 0
    print(f"Checking the queue {QUEUE}")
    if jobs is None:
        print("  PROBLEM: no queue.json. Copy queue.example.json to queue.json and write your own jobs."); return 1
    names = set()
    for j in jobs:
        for field in ("name", "prompt"):
            if not j.get(field): print(f"  PROBLEM: a job has no '{field}': {json.dumps(j)[:80]}"); problems += 1
        if j.get("name") in names: print(f"  PROBLEM: two jobs are called {j['name']}"); problems += 1
        names.add(j.get("name"))
        if len(j.get("refs", [])) > 3: print(f"  PROBLEM: {j.get('name')} has more than 3 references"); problems += 1
        for r in j.get("refs", []):
            if not resolve_ref(r) and r not in names:
                print(f"  PROBLEM: {j.get('name')}: reference '{r}' not found (a saved picture's name, or a path from the repository root)"); problems += 1
            elif not resolve_ref(r):
                print(f"  note: {j.get('name')} waits for '{r}' to be generated first")
    todo = sum(1 for j in jobs if j.get("name") for s in stems(j) if not saved(s))
    print(f"  {len(jobs)} jobs, {todo} pictures still to make")
    agy = shutil.which("agy")
    print(f"  agy: {'found at ' + agy if agy else 'PROBLEM: not found. Install Antigravity, open it once, sign in with your own Google account.'}")
    if not agy: problems += 1
    else:
        code = subprocess.run(["agy", "--version"], capture_output=True, text=True).returncode
        print(f"  agy --version: {'works' if code == 0 else 'PROBLEM: failed'}"); problems += code != 0
    try:
        import PIL  # noqa: F401
        print("  Pillow: installed (sizes and gallery thumbnails work)")
    except ImportError:
        print("  note: Pillow is not installed; pictures still save. For sizes and thumbnails: python -m pip install --user pillow")
    return problems

def main():
    ap = argparse.ArgumentParser(description="Generate the pictures listed in harness/tools/queue.json through agy.")
    ap.add_argument("--check", action="store_true", help="check the queue and agy, generate nothing")
    ap.add_argument("--commit", action="store_true", help="commit each saved picture on the current branch")
    ap.add_argument("--push", action="store_true", help="push the current branch after each commit (refuses on main)")
    ap.add_argument("--exit-when-done", action="store_true", help="stop when every job has its pictures")
    ap.add_argument("--model", default="gemini-3.8-flash-medium", help="the agy model that calls the picture tool")
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True); os.makedirs(RUN, exist_ok=True)
    jobs = load_queue()
    if a.check:
        n = check(jobs)
        print(f"RESULT: {'all good; start the watcher without --check' if n == 0 else f'{n} problem(s) to fix first'}."); sys.exit(1 if n else 0)
    if jobs is None:
        print("No harness/tools/queue.json yet. Copy queue.example.json to queue.json, write your own jobs, then run --check."); sys.exit(1)
    if os.path.exists(LOCK) and time.time() - os.path.getmtime(LOCK) < 900:
        print("Another watcher seems to be running (its lock file is fresh). Stop it first, or delete harness/tools/picture_watcher.lock."); sys.exit(1)
    if os.path.exists(STOP): os.remove(STOP)
    start, made, blocked_until = time.time(), 0, 0.0
    log(f"START picture watcher. Queue {QUEUE}. Pictures {OUT}. Log {LOG}. Stop by creating {STOP}.")
    try:
        while True:
            with open(LOCK, "w") as f: f.write(str(os.getpid()))
            if os.path.exists(STOP): log("STOP file found; stopping."); break
            if time.time() < blocked_until:
                time.sleep(60); continue
            jobs = load_queue() or []
            job, stem = next_job(jobs)
            if not job:
                if a.exit_when_done: log("Queue done."); break
                log(f"Queue done ({made} new this run). Checking for new jobs again in 10 minutes."); time.sleep(600); continue
            refs = [resolve_ref(r) for r in job.get("refs", [])]
            if None in refs:
                log(f"{stem}: a reference picture is missing ({job.get('refs')}); marking the job failed.")
                job["failed"] = 2; save_queue(jobs); continue
            left = sum(1 for j in jobs for s in stems(j) if not saved(s))
            log(f"{stem}: asking agy ({left} pictures left, running {int((time.time() - start) / 60)} min)")
            status, info, conv, t0 = call_agy(stem, job, refs, a.model)
            if status == "saved":
                dst = os.path.join(OUT, stem + os.path.splitext(info)[1].lower())
                shutil.copyfile(info, dst)
                try:
                    from PIL import Image
                    with Image.open(dst) as im: size, fmt = f"{im.width}x{im.height}", im.format
                except Exception: size, fmt = "?", "?"
                rec = {"time": datetime.datetime.now().isoformat(timespec="seconds"), "file": os.path.basename(dst), "job": job["name"],
                       "description_by": job.get("description_by", ""), "run_by": job.get("run_by", ""),
                       "size": size, "format": fmt, "aspect": job.get("ratio", "1:1"), "references": [os.path.basename(r) for r in refs],
                       "prompt": job["prompt"], "agy_conversation": conv, "sha256": hashlib.sha256(open(dst, "rb").read()).hexdigest(),
                       "tool": "Antigravity agy one-shot, image-generator subagent", "agent_model": a.model,
                       "image_model": "not reported by agy", "seconds": round(time.time() - t0)}
                with open(REC, "a", encoding="utf-8") as f: f.write(json.dumps(rec, ensure_ascii=False) + "\n")
                made += 1
                log(f"{stem}: SAVED {os.path.basename(dst)} {size} {fmt} ({made} this run)")
                g = subprocess.run([sys.executable, os.path.join(TOOLS, "build_gallery.py")], capture_output=True, text=True)
                log("  gallery rebuilt" if g.returncode == 0 else f"  gallery failed: {g.stderr[-200:]}")
                if a.commit:
                    commit([dst, REC, os.path.join(HERE, "gallery.html")], f"Picture: {os.path.basename(dst)}", a.push)
            elif status == "quota":
                blocked_until = time.time() + info + 180
                log(f"{stem}: QUOTA used up; waiting until about {datetime.datetime.fromtimestamp(blocked_until):%a %H:%M}")
            else:
                job["failed"] = job.get("failed", 0) + 1; save_queue(jobs)
                log(f"{stem}: FAILED ({status}), try {job['failed']} of 2: {info}")
                time.sleep(60)
    except KeyboardInterrupt:
        log("Stopped with Ctrl+C.")
    finally:
        if os.path.exists(LOCK): os.remove(LOCK)
        log(f"RESULT: {made} new pictures this run, in {OUT}. Gallery: {os.path.join(HERE, 'gallery.html')}. "
            f"Restart with: python harness/tools/picture_watcher.py")

if __name__ == "__main__":
    main()
