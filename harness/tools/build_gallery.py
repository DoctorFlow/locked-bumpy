"""Builds harness/gallery.html: one self-contained page (pictures embedded) showing every generated picture,
newest first, with its record and a box per picture for the pick.
Shell: any, normal user. Run from the repository root:  python harness/tools/build_gallery.py
The watcher runs this after every saved picture. Needs Pillow for thumbnails (python -m pip install --user pillow).
Origin: written 2026-11-22 for Karan's private avatar harness; MIT licence (harness/LICENSE)."""
import base64, datetime, html, io, json, os

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "gallery.html")
PICS = os.path.join(HERE, "pictures")
IMG = (".png", ".jpg", ".jpeg", ".webp")

def thumb(path, width=420):
    try:
        from PIL import Image
        with Image.open(path) as im:
            im = im.convert("RGBA")
            if im.width > width: im = im.resize((width, round(im.height * width / im.width)))
            bg = Image.new("RGBA", im.size, (240, 236, 245, 255)); bg.alpha_composite(im)
            buf = io.BytesIO(); bg.convert("RGB").save(buf, "JPEG", quality=82)
            return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()
    except Exception as e:
        print(f"  could not make a thumbnail of {os.path.basename(path)}: {e}"); return None

def main():
    print(f"Building {OUT}")
    recs = {}
    rp = os.path.join(PICS, "records.jsonl")
    if os.path.exists(rp):
        for line in open(rp, encoding="utf-8"):
            try: r = json.loads(line); recs[r["file"]] = r
            except Exception: pass
    files = sorted([f for f in os.listdir(PICS) if f.lower().endswith(IMG)] if os.path.isdir(PICS) else [],
                   key=lambda f: os.path.getmtime(os.path.join(PICS, f)), reverse=True)
    cards, skipped = [], 0
    for f in files:
        src = thumb(os.path.join(PICS, f))
        if not src: skipped += 1; continue
        r = recs.get(f, {})
        meta = [r.get("time", ""), f"{r.get('size', '')} {r.get('format', '')}".strip(),
                "refs: " + ", ".join(r["references"]) if r.get("references") else "",
                f"description: {r['description_by']}" if r.get("description_by") else ""]
        m = "".join(f"<div class=m>{html.escape(x)}</div>" for x in meta if x)
        p = f"<details><summary>prompt</summary>{html.escape(r.get('prompt', ''))}</details>" if r.get("prompt") else ""
        cards.append(f"<figure><img src='{src}' alt='{html.escape(f)}' loading=lazy><figcaption><b>{html.escape(f)}</b>{m}{p}"
                     f"<label class=pick><input type=checkbox> passes every check</label></figcaption></figure>")
    log = os.path.join(HERE, "tools", "picture_watcher.log")
    last = open(log, encoding="utf-8").read().strip().splitlines()[-1][20:] if os.path.exists(log) else "watcher not started"
    body = "".join(cards) or "<p class=empty>No pictures yet. See harness/tools/picture_watcher.log.</p>"
    page = f"""<!doctype html><html><head><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
<title>Picture Gallery</title><style>
:root{{--bg:#F6F2EA;--fg:#2E2040;--mut:#6E5585;--card:#fff}}
@media (prefers-color-scheme:dark){{:root{{--bg:#1A1424;--fg:#F3EEF8;--mut:#B9A8D8;--card:#2A2038;color-scheme:dark}}}}
body{{margin:0;background:var(--bg);color:var(--fg);font:15px/1.45 system-ui,sans-serif;padding:16px max(16px,env(safe-area-inset-left))}}
.status,.m,.empty{{color:var(--mut)}} .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(170px,1fr));gap:12px}}
figure{{margin:0;background:var(--card);border-radius:10px;overflow:hidden}} img{{width:100%;display:block}}
figcaption{{padding:6px 8px;font-size:12px;word-break:break-word}} details{{margin-top:4px}} .pick{{display:block;margin-top:6px}}</style></head><body>
<h1>Picture gallery</h1><p class=status>Built {datetime.datetime.now():%a %d %b %Y, %H:%M} · {len(cards)} pictures · watcher: {html.escape(last)}</p>
<p class=status>Checks for every picture: eyes open; skin warm and healthy, never pale or grey; no white sheet, no halo; no words or letters; one baby, whole, on the plain green backdrop.</p>
<div class=grid>{body}</div></body></html>"""
    with open(OUT, "w", encoding="utf-8") as f: f.write(page)
    print(f"RESULT: gallery.html written with {len(cards)} pictures ({os.path.getsize(OUT) // 1024} KB)"
          + (f"; {skipped} could not be shown" if skipped else "") + ".")

if __name__ == "__main__":
    main()
