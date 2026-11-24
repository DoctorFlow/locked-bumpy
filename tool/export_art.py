"""Export the app's pictures from the Bumpy studio at one size each (Python 3.12, Pillow).

    python tool/export_art.py C:/Users/owner/projects/avatar-harness-bumpy-studio
    python tool/export_art.py STUDIO --only nursery-halloween.webp

Shell: any (Windows PowerShell or bash), normal user. The studio folder is only
read. Pictures are written to assets/images in this repository; a file whose
bytes already match is skipped, so a second run writes nothing.

Sizes (see ASSETS.md): 15 character sprites at 768 x 768 PNG, the Halloween
and Everyday nurseries at 941 x 1672 WebP (full size, same layout),
six need icons and the lamp at 256 x 256 PNG. After this, regenerate the tint
masks with tool/make_paper_tones.py so they match the 768 sprites.
"""
import argparse
import io
from pathlib import Path
import sys
import time

from PIL import Image

IMAGES = Path(__file__).resolve().parents[1] / "assets" / "images"
BUDGET = 8_000_000
SPRITE = 768
ICON = 256
WEBP_QUALITY = 92
POSES = {
    "everyday": "everyday-papercut", "body-vampire": "vampire-violet",
    **{"body-" + name: name for name in ("mummy", "witch", "ghost", "skeleton", "zombie")},
}
NEEDS = ("bones", "brain", "iron", "rest", "vitamin", "water")


def sprites():
    """The 15 pose and face pairs, as in tool/make_paper_tones.py."""
    for stem, pose in POSES.items():
        faces = {"": "calm", "-happy": "tooth" if stem == "body-vampire" else "wide-smile"}
        if stem == "everyday":
            faces["-sleepy"] = "sleepy"
        for suffix, face in faces.items():
            yield stem + suffix, pose, face


def png(image):
    stream = io.BytesIO()
    image.save(stream, "PNG", optimize=True)
    return stream.getvalue()


def webp(image):
    stream = io.BytesIO()
    image.save(stream, "WEBP", quality=WEBP_QUALITY, method=6)
    return stream.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("studio", type=Path, help="Folder of the Bumpy studio (read only)")
    parser.add_argument("--only", default="", help="Comma-separated target names to export; others are left alone")
    args = parser.parse_args()
    only = {name.strip() for name in args.only.split(",") if name.strip()}
    studio = args.studio.resolve()
    chatgpt = studio / "studio" / "chatgpt"
    rig = chatgpt / "rig" / "manifest.json"
    started = time.monotonic()
    print(f"Reading the studio at {studio} (read only); writing to {IMAGES}")
    if not rig.is_file():
        print(f"FAILED: no rig manifest at {rig}. Nothing written. Check the studio path and run again.")
        return 1
    sys.path.insert(0, str(studio / "tools"))
    from bumpy_rig import compose

    jobs = []
    for name, pose, face in sprites():
        jobs.append((f"{name}.png", f"rig pose {pose}, face {face}",
                     lambda pose=pose, face=face: png(
                         compose(rig, pose, "peach", face).resize((SPRITE, SPRITE), Image.Resampling.LANCZOS))))

    def halloween():
        # The clean night original: no frame, no violet sliver on the moon.
        return webp(Image.open(chatgpt / "originals" / "night-nursery.png").convert("RGB"))

    def everyday():
        return webp(Image.open(chatgpt / "originals" / "everyday-nursery.png").convert("RGB"))

    def icon(source):
        return lambda: png(Image.open(source).convert("RGBA").resize((ICON, ICON), Image.Resampling.LANCZOS))

    jobs.append(("nursery-halloween.webp", "originals/night-nursery.png, full size", halloween))
    jobs.append(("nursery-everyday.webp", "originals/everyday-nursery.png, full size", everyday))
    for need in NEEDS:
        jobs.append((f"need-{need}.png", f"pieces/need/{need}.png", icon(chatgpt / "pieces" / "need" / f"{need}.png")))
    jobs.append(("nursery-lamp.png", "originals/nursery-lamp.png", icon(chatgpt / "originals" / "nursery-lamp.png")))

    if only:
        unknown = only - {target for target, _, _ in jobs}
        if unknown:
            print(f"FAILED: unknown target(s) {', '.join(sorted(unknown))}. Nothing written.")
            return 1
        jobs = [job for job in jobs if job[0] in only]
    counts = {"written": 0, "skipped": 0, "failed": 0}
    for number, (target, source, make) in enumerate(jobs, 1):
        print(f"[{number}/{len(jobs)}] {target} from {source} ...", flush=True)
        try:
            data = make()
            with Image.open(io.BytesIO(data)) as check:
                size = f"{check.width}x{check.height}"
            path = IMAGES / target
            if path.is_file() and path.read_bytes() == data:
                state = "skipped (already identical)"
                counts["skipped"] += 1
            else:
                path.write_bytes(data)
                state = "written"
                counts["written"] += 1
            print(f"    {state}: {size} px, {len(data):,} bytes")
        except Exception as error:  # report and carry on with the other pictures
            counts["failed"] += 1
            print(f"    FAILED: {error}")

    total = sum(p.stat().st_size for p in IMAGES.iterdir() if p.is_file())
    verdict = "under" if total < BUDGET else "OVER"
    elapsed = time.monotonic() - started
    print(f"Done in {elapsed:.0f} s: {counts['written']} written, {counts['skipped']} skipped, "
          f"{counts['failed']} failed. assets/images is {total:,} bytes, {verdict} the {BUDGET:,} budget. "
          "Next: run tool/make_paper_tones.py to regenerate the tint masks.")
    return 1 if counts["failed"] or total >= BUDGET else 0


if __name__ == "__main__":
    sys.exit(main())
