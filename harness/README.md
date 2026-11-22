# Picture harness: how Lakshya takes over

Written 2026-11-22 for Lakshya. Owner of this subject: this file. Karan merges every change.

## If you read only this
- **What it is:** a small Python watcher that asks Google Antigravity's command-line tool (`agy`) for pictures of Bumpy, one at a time, from a list you write. It waits through the free quota limit by itself, saves each picture with a record line, and rebuilds a gallery page where Rachel picks.
- **Who does what:** Rachel picks every picture that ships and writes any new descriptions. You run the tool and place the pictures in the app. Harshy checks the pictures against the checks below. Karan checks safety and can veto a picture.
- **Karan's studio pictures may ship** (his ruling 2026-11-22, "Team may ship them"). They are all in `art/` in this repository and more arrive every day (§7a). Use them.
- **Start:** install Antigravity, sign in with your own Google account, copy the example queue, write the jobs with Rachel, run `--check`, then run the watcher.

## 1. Why it exists
Karan ruled on 2026-11-22 that generated pictures may go into the entry ("Into the entry too", see `DECISIONS.md`). The hand-made baby from guide 03 still ships first, at rung 3 (Fri 27 Nov). A generated set replaces it only as a whole set and only if every picture passes the checks. The proposed dates, waiting on Karan's approval of the plan: the team's own test Mon 23 or Tue 24 Nov; the master picture Wed 25 Nov; art freeze Sun 29 Nov; latest switch back to hand-made Tue 1 Dec, before filming.

The contest rules (read 2026-11-22 at kiroween.devpost.com/rules) do not mention AI-made art. They do say the work must be the entrant's own and made after 30 Oct 2026, and the entry repository must be public and open source. So Rachel picks every picture that ships. Karan ruled later the same day that pictures from his studio may ship too ("Team may ship them").

## 2. Set up (once, about 15 minutes)
Shell: Windows PowerShell or a Mac/Linux terminal, as a normal user, never as admin.

1. Install Google Antigravity from its official site. Open it once and sign in with **your own** Google account.
2. Check the command-line tool works: `agy --version`. If it says "not found", restart the terminal; on Windows it lives in `%LOCALAPPDATA%\agy\bin`.
3. Python 3.10 or newer. Optional but useful: `python -m pip install --user pillow` (gives picture sizes and gallery thumbnails).
4. From the repository root: copy `harness/tools/queue.example.json` to `harness/tools/queue.json`.

## 3. Write the queue with Rachel
`harness/tools/queue.json` is a list of jobs. The watcher rereads it before every call, so you can add jobs while it runs.

| Field | Meaning |
|---|---|
| `name` | File name for the picture, letters, digits and underscores. Takes 2 and 3 are saved as `name__take2`, `name__take3` |
| `prompt` | Rachel's description, then the technical lines (see below). Passed to the picture tool word for word |
| `ratio` | `1:1` for the baby, `9:16` for a full-screen scene |
| `takes` | How many versions to make, so Rachel can choose |
| `refs` | Up to 3 reference pictures: the `name` of an earlier job, or a path from the repository root. Use the first good Bumpy as the reference for every costume, so the face stays the same |
| `description_by`, `run_by` | Who wrote the words, who ran it. They go into the record for `ASSETS.md` |

**Technical lines to keep at the end of every prompt** (these are instructions to the tool, not the look):
- one baby, whole body, centred, eyes open
- plain flat pure green background (#00FF00) filling the picture, nothing else, so code can cut the baby out
- no text, no letters, no white sheet, no halo

**Order:** make the plain Bumpy first (3 takes). Rachel picks one. Put its name in `refs` of every costume job, then add the costumes.

## 4. Run it
From the repository root:

```
python harness/tools/picture_watcher.py --check
python harness/tools/picture_watcher.py
```

- `--check` generates nothing. It lists problems with the queue, checks `agy`, and ends with one result line. Fix every problem it lists first.
- The second line runs until every job has its pictures, then checks for new jobs every 10 minutes. Leave the window open.
- **Stop:** create an empty file `harness/tools/STOP` (it stops before its next call), or press Ctrl+C.
- **Restart:** run the same line again. It skips pictures already saved.
- `--exit-when-done` stops when the queue is done. `--commit` commits each picture on your current branch; `--commit --push` also pushes that branch. It refuses to push `main`.
- Log: `harness/tools/picture_watcher.log`. Every step is one line.

## 5. The quota (observed 2026-11-22 on Karan's machine)
- About 4 to 6 pictures per account, then a quota error for about 5 hours. The watcher reads the exact reset time from agy's log and waits until then plus 3 minutes, by itself.
- One Google account per Windows user: agy has no switch for a second account.
- **Do not rotate accounts to get around the limit.** A Google forum warns this can get an account flagged. To make more pictures, each teammate can run the watcher on their own machine, with their own account, on their own share of the queue.
- If the free quota is too slow: Kiro can reach a picture model through an MCP server (for example `zhongweili/nanobanana-mcp-server`, MIT licence) in `.kiro/settings/mcp.json`, with a Gemini API key that has a spending cap. The key goes in an environment variable, never in git. Karan decides about a paid key.

## 6. What you get
- `harness/pictures/` holds every picture as made, never edited.
- `harness/pictures/records.jsonl` has one line per picture: time, file, job, who wrote the description, who ran it, size, reference pictures, the exact prompt, the agy conversation id, a SHA-256 fingerprint, tool, model as shown, seconds. Copy these into `ASSETS.md` (guide 03) with the takes Rachel rejected and any edits.
- `harness/gallery.html` is rebuilt after every picture. Open it in a browser. Each picture has its record, its prompt and a box to tick when it passes every check.

## 7. The checks (every picture, before Rachel picks)
- Eyes open. Bumpy is never asleep in a costume and never looks unwell.
- Skin warm and healthy. Never pale, grey or blue.
- No white sheet and no halo: those read as death.
- No words or letters made by the model. The app adds its own words in code.
- One baby, whole, on the plain green backdrop, nothing cut off.
- Same face as the reference across the set. If any picture of a shipped look fails, all of that set stay hand-made.

## 7a. More pictures are coming (updated 2026-11-22)
Karan's private studio keeps generating. ChatGPT (Codex) is making a full paper-cut Bumpy set: everyday, thank-you, the six costumes (vampire, mummy, witch, ghost, skeleton, zombie), a separate head and body, a witch hat, a lamp and two nursery backdrops. Antigravity adds more after each quota reset. Expect this to grow every day until the art freeze.
- **Where:** here, in `art/`. Open `art/studio/index.html` in a browser for the gallery and phone preview. The files for the app are the see-through PNGs in `art/studio/originals/`. New batches arrive by themselves: run `git pull`.
- **What it is for you:** the art for the app, ready to use. ChatGPT's image tool returns a truly see-through PNG (no green backdrop or cut-out step), so it may be the easier tool for the team: each of you on your own ChatGPT account, with Rachel's own words as the prompt.
- **You may ship them** (Karan's ruling 2026-11-22). Rachel picks which. Each picture's record (prompt, references, fingerprint) is already in `art/studio/manifest.json`; nothing more to write.
- **Theme:** match Kiroween's own look, `guides/03-design-system.md` §11.

## 8. Moving it into the app repository
This kit is guidance and is never copied into the public entry. The `harness/` folder is the one exception you may copy, as code:
1. Copy the `harness/` folder into the team's app repository, with `LICENSE`.
2. In `harness/.gitignore` there, delete the last three lines, so pictures, records and the gallery are kept as evidence.
3. Say it in the app's README and on Devpost: "`harness/` is pre-existing open-source code (MIT) written for Karan's avatar harness and used with disclosure." Pre-existing code is allowed when disclosed.
4. Run it on a branch with `--commit --push`, and merge by pull request.
5. Better for the Kiro score: write a small Kiro spec for the picture set, a steering file with the checks above in your own words, and a hook plus CI check on new pictures. Ask Kiro to write the green-backdrop cut-out script; that is your own work.

## 9. If you hand this to your coding agent
Tell it: "Read `harness/README.md`. Run `python harness/tools/picture_watcher.py --check` and fix what it reports. Never edit `harness/pictures/`. Never write prompts yourself: they are Rachel's words. Use only pictures from the team or from Karan's studio, and record where each came from. Stop by creating `harness/tools/STOP`."

## 10. Unknowns
- Which picture model agy uses underneath: unknown, agy does not report it.
- Whether the quota is the same on every account: unknown; observed only on Karan's.
- Whether Devpost will accept generated pictures without question: unknown. Rachel can ask Devpost in writing before submitting.
