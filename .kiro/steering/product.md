---
inclusion: always
---
# Product Steering

## Vision
Little Bumpy is a free, private pregnancy companion app for phones (US English).
The unborn baby narrates the entire experience in first person to its mother ("you").

## Two Modes & Parity Rule
- **Everyday** (lamp on): Warm cream storybook paper tones, onesie.
- **Halloween** (lamp off): Midnight violet/plum tones, pumpkin moon, themed costume.
- Both modes share identical feature sets, tabs, check-ins, and data.
- Mode changes only palette, art assets, motion, and baby costume words. Code reads the theme; it never branches on "isHalloween".

## Costumes and Health Needs
Six costumes correspond to maternal health needs:
- Vampire = IRON
- Zombie = BRAIN
- Skeleton = BONES
- Mummy = WATER
- Ghost = REST
- Witch = VITAMIN

## The Daily Loop (Under 30 Seconds)
- One Need of the Day selected by date rotation.
- Today tab shows the baby in today's costume, a short message (~20 words), and 3 check-ins (Water, Vitamin, and the Need of the Day; when today's need is Water or Vitamin, the third is Rest).
- Ticking today's need triggers a celebration hop and changes the baby's line to a warm thank-you.
- Missed days change nothing. No streaks, no guilt, no lost progress. The only count is "Days Together", which strictly increments.

## Voice Separation
- **Baby voice:** Today tab, This week tab. Warm, grateful, playful.
- **App voice:** Paused screen, Settings, disclaimers, medical guides. Calm, neutral, unadorned.

## Safety & Privacy
- One plain disclaimer line at first run and Settings > About: "This app is not medical advice. If you are worried about anything, call your doctor."
- Single-tap Pause silences everything immediately. Paused screen displays no baby, no costume, no streak, no animations.
- 100% on-device. Zero network calls, zero tracking, zero runtime AI, no accounts, no ads.
