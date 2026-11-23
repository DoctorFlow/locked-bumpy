---
inclusion: always
---
# Master Hackathon Context & Kit Instructions

## 1. Hackathon Details
- **Contest:** Kiroween 2026 — Category: **Costume Contest** (Devpost).
- **Hard Deadline:** Friday, December 4, 2026, at 2:00 PM Pacific (Saturday Dec 5, 3:30 AM IST).
- **Target Submission Date:** Thursday, December 3, 2026 (24 hours early).
- **Core Hackathon Requirement:** The costume is the function. In Halloween mode, the spooky design is the reminder ("vampire = iron", "mummy = water").

## 2. Team Structure & Roles
- **Rachel (Team Lead & Star):** Mother and aesthetician (non-developer). The entire Devpost text, video, and public story is told from her perspective. Shapes the baby's voice in Kiro and officially presses Submit.
- **Lakshya (Lead Developer):** Builds the Flutter application using Kiro, maintains test suites, hooks, and clean architecture.
- **Harshy (QA & Content):** Runs testing harness, logs Kiro sessions, coordinates medical reviews, and produces the 2:45 submission video.
- **Karan (MD Physician & Owner):** Medical adviser and director. Approves all health facts in nightly batches. Has final veto on medical accuracy. (Not an entrant to protect eligibility).

## 3. Product Vision & Rules (From Kit 01 & 02)
- **Little Bumpy:** A free, private pregnancy companion app for phones (US English).
- **First Person Narration:** Unborn baby speaks directly to mom as "you" in 1–2 kind sentences (~20 words).
- **Two Modes (100% Parity):**
  - Everyday (lamp on): Warm cream storybook paper tones, onesie.
  - Halloween (lamp off): Midnight plum palette, pumpkin moon, themed costume.
- **Costume $\leftrightarrow$ Need Map:**
  - 🧛 Vampire = IRON
  - 🧟 Zombie = BRAIN
  - 💀 Skeleton = BONES
  - 🩹 Mummy = WATER
  - 👻 Ghost = REST
  - 🧙 Witch = VITAMIN
- **Daily Loop (<30 Seconds):**
  - Need of the Day rotates daily.
  - 3 check-ins: Water, Vitamin, and the Need of the Day (or Rest when need is Water/Vitamin).
  - Ticking today's need triggers a celebratory hop and changes baby speech to an approved thank-you line.
  - All done shows gentle goodbye ("That's us for today"). Tomorrow starts blank with zero mention of yesterday.
- **Non-Negotiables:**
  - Zero guilt, zero streaks, zero harm predictions, zero talk of maternal body/weight.
  - NEVER mention kicks, movement, or sensory experiences (prevents fetal movement anxiety).
  - Zero runtime network calls, zero tracking, zero AI at runtime. 100% on-device.
  - Instant Pause silences all speech, counters, and baby avatars. Displays compassionate neutral text.

## 4. Asset Inventory (`assets/images/`)
All images are transparent, registered PNGs from the studio release:
- `assets/images/everyday.png` (Everyday Onesie)
- `assets/images/body-vampire.png` (Vampire)
- `assets/images/body-mummy.png` (Mummy)
- `assets/images/body-witch.png` (Witch)
- `assets/images/body-ghost.png` (Ghost)
- `assets/images/body-skeleton.png` (Skeleton)
- `assets/images/body-zombie.png` (Zombie)
- `assets/images/nursery-lamp.png` (Lamp)

## 5. Build Ladder & Cut Order
- Rung 1 (Mon 23 Nov): Hello, baby (Date setup, gestational week, pause, CI).
- Rung 2 (Wed 25 Nov): Everyday core (3 check-ins, weeks 4-42, content gate).
- Rung 3 (Fri 27 Nov): Costume proof (Minimum complete entry: vampire, mummy, witch).
- Rung 4 (Sun 29 Nov): Feature freeze (ghost, skeleton, zombie, closet sheet).
- Rung 5 (Tue 1 Dec): Polished (Asset polish, a11y, final video public).
- Rung 6 (Thu 3 Dec): Submitted.

## 6. Kiro Autonomous Execution Rules
When executing any task:
1. Reference the corresponding spec in `.kiro/specs/<spec>/`.
2. Keep code minimal, clean, and strictly local.
3. Verify that `dart-check` and `content-check` hooks pass.
4. Mark completed task `[x]` in `tasks.md`.
5. Log progress in `docs/kiro-log.md`.
