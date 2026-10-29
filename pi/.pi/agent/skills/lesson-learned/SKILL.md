---
name: lesson-learned
description: Use after any session in this repo that surfaced a surprise, a breakage, a machine or harness behavior that cost time to learn, or an edge case. Captures the knowledge as a lesson file under resource/lessons/ so the next session and the other machine inherit it. A red diagnosis without a lesson is not finished work.
---

# Lesson learned

This repo's durability comes from `resource/lessons/`: every wall the
setup hit, written down so the next session — and the other machine —
does not climb it again. The rule lives in AGENTS.md. This skill is how
a lesson gets written.

## When to write one

Any of these, before the related work is committed:

- Something broke and cost diagnosis time, even if a retry later fixed it.
- A check or manual test surfaced surprising behavior, even if nothing
  failed in the end.
- A machine, harness, or platform behavior had to be discovered by
  experiment (systemd unit semantics, pi's clipboard path, pipewire
  defaults, USB autosuspend).
- An edge case was found: a rotation gap, a stale path, a masked drift,
  a per-machine difference.

Do not wait for a failure to be "confirmed". Write the lesson when the
knowledge lands, while the evidence is in front of you.

## Classify it

- `domain.`: knowledge about the world this repo lives in. Someone new
  would hit the same wall. Examples: pi fullscreen captures the mouse so
  its clipboard needs `wl-copy` on Wayland; pi discovers project skills
  from the cwd, so a skill in another repo is invisible here; pi-voice-stt
  records via `ffmpeg -f pulse -i default` on Linux.
- `edge.`: a case the happy path missed, usually found by a failure or
  near-failure. Examples: a stale copy of a moved directory masks a
  broken systemd unit until reboot; systemd units are per-machine state
  and drift silently; a script not wired into setup-all.sh never runs.

When unsure, ask: would a careful newcomer predict this? No, and it is
about the outside world, then domain. It is a path inside our own setup
that broke or nearly broke, then edge.

## Where and what to name it

- Directory: `resource/lessons/`. Create it if missing.
- Name: `domain.<YYYYMMDD>.<kebab-case-title>.md` or
  `edge.<YYYYMMDD>.<kebab-case-title>.md`. Datestamp is the local date
  the lesson was learned, not written.

## Anatomy, in this order

A reader must be able to act on the file without the transcript.

1. **Title**: one sentence, the observation itself. "Systemd user units
   are per-machine state and drift silently", not "Lesson about units".
2. **Date and source**: one line. When, and what surfaced it: the
   incident, the command, the error text.
3. **What happened**: the story with concrete evidence. Exact error
   text, paths, exit codes, timestamps. Not "it was broken" but
   "restart counter at 1121, status=203/EXEC, ExecStart pointed at the
   pre-resource/ path".
4. **Why it happened**: the mechanism, traced to root cause. Verified,
   not guessed.
5. **The fix**: what changed, with file names. If nothing structural
   changed (knowledge only), say so and say what now relies on it.
6. **Rules that fall out**: durable, checkable rules a future session
   can apply without reading the story. Write them as imperatives. If a
   rule can be encoded as a script, a `--check` mode, or a skill edit
   instead of text, encode it there and say so.

## Classes worth scanning for in this repo

When a session ends, ask whether anything new was learned in each:

- **Two-machine parity**: rotation gaps, per-machine state that drifted,
  checks the twin needs after a pull.
- **Stow and symlinks**: real files where symlinks belong, orphaned
  scripts, config edited live instead of in the repo.
- **systemd units**: paths after repo moves, restart loops, units as
  per-machine state.
- **Audio stack**: Yeti wedge, pipewire/pulse defaults, whisper server
  layers (capture vs transcription).
- **Dual harness**: pi vs dsh skill sets, deploy mechanisms (stow vs
  npm scripts), places they can diverge.
- **Secrets boundaries**: what must never be committed or synced.

## Boundary

A lesson is knowledge earned from an event. Session continuation state
(open follow-ups, live state per machine) goes to `resource/handoff/`,
not lessons. Standing design policy goes to AGENTS.md. When a lesson's
rule becomes permanent policy, promote it and leave the lesson as the
record of how it was learned.

Commit the lesson in the same commit as the fix or the discovery. A
lesson that lives on only one machine does not exist for the other one.
