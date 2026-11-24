# Asset Inventory

Graphical assets and fonts used in Little Bumpy.

| Asset | Source / Creator | License / Status | Date |
|---|---|---|---|
| `harness/` | Pre-existing open-source code | MIT | 2026-11-22 |
| Fraunces | Google Fonts | Open Font License | 2026-11-22 |
| Atkinson Hyperlegible | Braille Institute | Open Font License | 2026-11-22 |
| `assets/images/everyday.png`, `everyday-happy.png`, `everyday-sleepy.png` | Bumpy Studio, Everyday lavender paper-cut pose | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-vampire.png`, `body-vampire-happy.png` | Bumpy Studio, Violet Vampire (Iron) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-mummy.png`, `body-mummy-happy.png` | Bumpy Studio, Mummy (Water) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-witch.png`, `body-witch-happy.png` | Bumpy Studio, Witch (Vitamin) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-ghost.png`, `body-ghost-happy.png` | Bumpy Studio, Ghost (Rest) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-skeleton.png`, `body-skeleton-happy.png` | Bumpy Studio, Skeleton (Bones) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/body-zombie.png`, `body-zombie-happy.png` | Bumpy Studio, Zombie (Brain) | Team Kit Studio Release | 2026-11-23 |
| `assets/images/need-{iron,water,vitamin,rest,bones,brain}.png` | Bumpy Studio, registered icons in `pieces/need/` | Team Kit Studio Release | 2026-11-23 |
| `assets/images/nursery-lamp.png` | Bumpy Studio, `originals/nursery-lamp.png` | Team Kit Studio Release | 2026-11-23 |
| `assets/images/nursery-everyday.webp` | Bumpy Studio, `originals/everyday-nursery.png` | Team Kit Studio Release | 2026-11-23 |
| `assets/images/nursery-halloween.webp` | Bumpy Studio, `originals/night-nursery-violet.png` | Team Kit Studio Release | 2026-11-23 |

The full-character PNGs use the Demo Starter poses and the Peach tone from the studio rig with its `reference-paper-v4` expression recipe. The base expression is Calm. Happy uses Wide smile, with First tooth for Vampire. The sprites keep the studio's common canvas and face placement at 768 × 768 pixels.

## One size per picture

Each picture ships at one size, large enough for the biggest place it is drawn on a 3× phone, so it is only ever shrunk (or, for the widest nursery card, enlarged at most 1.4×). There are no `2.0x/` or `3.0x/` folders, because the skin-tone tint reads the literal path and needs the mask and sprite at the same size.

| Picture | Pixels | Format | Bytes |
|---|---|---|---|
| `body-ghost.png` | 768 × 768 | PNG RGBA | 463,257 |
| `body-ghost-happy.png` | 768 × 768 | PNG RGBA | 464,127 |
| `body-mummy.png` | 768 × 768 | PNG RGBA | 448,687 |
| `body-mummy-happy.png` | 768 × 768 | PNG RGBA | 449,372 |
| `body-skeleton.png` | 768 × 768 | PNG RGBA | 385,296 |
| `body-skeleton-happy.png` | 768 × 768 | PNG RGBA | 386,122 |
| `body-vampire.png` | 768 × 768 | PNG RGBA | 386,490 |
| `body-vampire-happy.png` | 768 × 768 | PNG RGBA | 384,803 |
| `body-witch.png` | 768 × 768 | PNG RGBA | 355,266 |
| `body-witch-happy.png` | 768 × 768 | PNG RGBA | 356,038 |
| `body-zombie.png` | 768 × 768 | PNG RGBA | 375,534 |
| `body-zombie-happy.png` | 768 × 768 | PNG RGBA | 376,324 |
| `everyday.png` | 768 × 768 | PNG RGBA | 323,669 |
| `everyday-happy.png` | 768 × 768 | PNG RGBA | 324,343 |
| `everyday-sleepy.png` | 768 × 768 | PNG RGBA | 321,986 |
| `tint-*.webp` (15, one per sprite above) | 768 × 768 | lossless WebP RGB | 22,908–27,932 each, 394,154 total |
| `nursery-halloween.webp` | 1190 × 1190 (32 px see-through margin cropped) | WebP q92 RGB | 23,672 |
| `nursery-everyday.webp` | 941 × 1672 | WebP q92 RGB | 57,646 |
| `need-bones.png` | 256 × 256 | PNG RGBA | 31,167 |
| `need-brain.png` | 256 × 256 | PNG RGBA | 30,152 |
| `need-iron.png` | 256 × 256 | PNG RGBA | 31,351 |
| `need-rest.png` | 256 × 256 | PNG RGBA | 29,994 |
| `need-vitamin.png` | 256 × 256 | PNG RGBA | 27,588 |
| `need-water.png` | 256 × 256 | PNG RGBA | 29,929 |
| `nursery-lamp.png` | 256 × 256 | PNG RGBA | 26,388 |
| **All 39 files** | | | **6,483,355** (budget 8,000,000) |

To re-export, run `python tool/export_art.py /path/to/avatar-harness-bumpy-studio` (any shell, normal user). It only reads the studio, prints each picture's pixel size and bytes, and skips files that are already identical, so a second run writes nothing. Then regenerate the masks as below.

## Five studio skin tones

The app keeps the 24 original pictures and adds 15 lossless WebP masks (394,154 bytes). The masks carry skin and blush weights for the seven looks and their expressions. Flutter applies the studio colours to the original 768 px paper art on the device. The complete image folder is 6,483,355 bytes. The original Peach PNG renders directly.

To regenerate the masks, use Python with Pillow (NumPy is not needed) and run `python tool/make_paper_tones.py /path/to/avatar-harness-bumpy-studio`. Add `--check` to compare the export with the committed masks. The exporter compares all 60 alternate renders with the studio rig at 190 px and checks their full-resolution alpha channels. The Pillow-only fit reproduces the earlier NumPy masks byte for byte at 512 px.
