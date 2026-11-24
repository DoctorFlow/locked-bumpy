"""Export small tint masks from the Bumpy studio rig. Requires Pillow only (no NumPy).

    python tool/make_paper_tones.py C:/Users/owner/projects/avatar-harness-bumpy-studio [--check]

Shell: any (Windows PowerShell or bash), normal user. The studio is only read.
Run tool/export_art.py first: each mask is fitted at the size of its sprite.
"""
import argparse
import io
import json
from pathlib import Path
import struct
import sys
import time

from PIL import Image, ImageChops, ImageColor

IMAGES = Path(__file__).resolve().parents[1] / "assets" / "images"
BUDGET = 8_000_000
POSES = {
    "everyday": "everyday-papercut", "body-vampire": "vampire-violet",
    **{"body-" + name: name for name in ("mummy", "witch", "ghost", "skeleton", "zombie")},
}
BASE = (250, 176, 115)
BLUSH = (54, 26, 28)
PAPER_SCALE = 0.9


def f32(value):
    """Round to the nearest 32-bit float, as the NumPy version of this tool did."""
    return struct.unpack("f", struct.pack("f", value))[0]


def pairwise(values):
    """Sum 12 numbers in NumPy's pairwise order, so ties round the same way."""
    a = values
    total = ((a[0] + a[1]) + (a[2] + a[3])) + ((a[4] + a[5]) + (a[6] + a[7]))
    for value in a[8:]:
        total += value
    return total


def fit_masks(studio_frames, colors, master):
    """Fit a skin and a cheek weight per pixel to all four studio references."""
    if len(studio_frames) != 4:
        raise ValueError("Expected four alternate studio tones.")
    alpha = master.getchannel("A")
    for frame in studio_frames:
        if frame.getchannel("A").tobytes() != alpha.tobytes():
            raise ValueError("Studio tint changed the silhouette.")
    scale = f32(PAPER_SCALE)
    # skin[t][c][v]: the studio's paper shift for tone t, channel c, master value v.
    skin = [[[min(max(color[c] + f32(scale * (v - BASE[c])), 0), 255) - v for v in range(256)]
             for c in range(3)] for color in colors]
    cheek = []
    for color in colors:
        depth = min(max((200 - color[0]) / 68, 0), 1)
        cheek.extend(-BLUSH[c] * depth for c in range(3))
    cc = pairwise([value * value for value in cheek])
    tone_count = len(colors)

    base_bytes = master.convert("RGB").tobytes()
    alpha_bytes = alpha.tobytes()
    frame_bytes = [frame.convert("RGB").tobytes() for frame in studio_frames]
    mask = bytearray(len(base_bytes))
    step = 255 / 63
    for pixel, a in enumerate(alpha_bytes):
        if a == 0:
            continue
        i = 3 * pixel
        base = base_bytes[i:i + 3]
        s, r = [], []
        for t in range(tone_count):
            ref = frame_bytes[t]
            table = skin[t]
            for c in range(3):
                s.append(table[c][base[c]])
                r.append(ref[i + c] - base[c])
        # The two-column least-squares system counts the contribution of each
        # painted layer even at an antialiased boundary between skin and fabric.
        ss = pairwise([x * x for x in s])
        sc = pairwise([x * y for x, y in zip(s, cheek)])
        sr = pairwise([x * y for x, y in zip(s, r)])
        cr = pairwise([x * y for x, y in zip(cheek, r)])
        determinant = max(ss * cc - sc * sc, 1)
        for k, weight in enumerate(((sr * cc - cr * sc) / determinant, (cr * ss - sr * sc) / determinant)):
            # Six bits per weight keeps the paper bundle small.
            mask[i + k] = round(round(min(max(weight, 0), 1) * 63) * step)
    mask_image = Image.frombytes("RGB", master.size, bytes(mask))

    def phone(image):
        return image.resize((190, 190), Image.Resampling.LANCZOS).convert("RGBa")

    for t, original in enumerate(studio_frames):
        rebuilt = bytearray(base_bytes)
        table = skin[t]
        for pixel in range(len(alpha_bytes)):
            i = 3 * pixel
            m0, m1 = mask[i], mask[i + 1]
            if m0 == 0 and m1 == 0:
                continue
            for c in range(3):
                v = base_bytes[i + c]
                delta = table[c][v] * m0 / 255 + cheek[3 * t + c] * m1 / 255
                rebuilt[i + c] = min(max(round(v + delta), 0), 255)
        image = Image.frombytes("RGB", master.size, bytes(rebuilt))
        image.putalpha(alpha)
        bands = ImageChops.difference(phone(original), phone(image)).getextrema()
        error = max(high for _, high in bands)
        if error > 8:
            raise ValueError(f"Phone rendering drifted by {error} channel levels.")
    return mask_image


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("harness", type=Path, help="Bumpy studio folder (read only), with tools/bumpy_rig.py")
    parser.add_argument("--check", action="store_true", help="Compare with the committed masks; write nothing")
    args = parser.parse_args()
    started = time.monotonic()
    print(f"Reading the studio rig at {args.harness}; {'checking' if args.check else 'writing'} masks in {IMAGES}")
    sys.path.insert(0, str(args.harness.resolve() / "tools"))
    from bumpy_rig import compose
    rig = args.harness / "studio/chatgpt/rig/manifest.json"
    registry = json.loads(rig.read_text(encoding="utf-8"))
    tones = [tone for tone in registry["tones"] if tone["id"] != "peach"]
    colors = [ImageColor.getrgb(tone["color"]) for tone in tones]
    jobs = []
    for stem, pose in POSES.items():
        faces = {"": "calm", "-happy": "tooth" if stem == "body-vampire" else "wide-smile"}
        if stem == "everyday":
            faces["-sleepy"] = "sleepy"
        jobs.extend((stem + suffix, pose, face) for suffix, face in faces.items())
    masks = {}
    for number, (name, pose, face) in enumerate(jobs, 1):
        print(f"[{number}/{len(jobs)}] fitting tint-{name}.webp ({time.monotonic() - started:.0f} s elapsed) ...",
              flush=True)
        master = Image.open(IMAGES / (name + ".png")).convert("RGBA")

        def render(tone):
            return compose(rig, pose, tone, face).resize(master.size, Image.Resampling.LANCZOS)
        if render("peach").tobytes() != master.tobytes():
            raise ValueError(f"{name} no longer matches the studio master. Run tool/export_art.py first.")
        references = [render(tone["id"]) for tone in tones]
        mask = fit_masks(references, colors, master)
        encoded = io.BytesIO()
        mask.save(encoded, "WEBP", lossless=True, exact=True, method=6)
        masks[IMAGES / ("tint-" + name + ".webp")] = encoded.getvalue()
        print(f"    fitted: {mask.width}x{mask.height} px, {len(encoded.getvalue()):,} bytes")

    existing = sum(p.stat().st_size for p in IMAGES.iterdir() if p.is_file() and p not in masks)
    total = existing + sum(len(data) for data in masks.values())
    if total >= BUDGET:
        raise ValueError(f"Paper art exceeds the {BUDGET:,} byte budget: {total:,} bytes. Nothing written.")
    written = skipped = 0
    for path, data in masks.items():
        if args.check:
            if not path.exists() or path.read_bytes() != data:
                raise ValueError(f"Mask changed: {path.name}")
        elif path.exists() and path.read_bytes() == data:
            skipped += 1
        else:
            path.write_bytes(data)
            written += 1
    action = "all match the committed files" if args.check else f"{written} written, {skipped} skipped (identical)"
    print(f"Done in {time.monotonic() - started:.0f} s: {len(masks)} masks, {action}; "
          f"{len(masks) * len(tones)} studio comparisons passed; {total:,} bytes of app art "
          f"(budget {BUDGET:,}).")


if __name__ == "__main__":
    main()
