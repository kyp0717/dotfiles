---
name: lesson-learned
description: Capture a lesson the moment it surfaces and route it to the right layer (handoff unit, runbook, or structural fix). Use for incidents, human corrections, edge cases, and project domain knowledge that cost time to discover.
---

# Lesson Learned

Capture every lesson the moment it surfaces, route it to the layer that
will actually prevent recurrence, and close the loop. A lesson that is
only "kept in mind" does not exist.

**Why:** This repo serves two machines that swap roles. A lesson that
stays in one session, one transcript, or one machine's live config is
lost at the next rotation. The only lesson that survives is one that is
committed to git — and the only lesson that never needs re-reading is one
encoded in a script or check.

## When to capture

- The human corrects you or states a project fact you got wrong.
- An incident: something broke and cost time to diagnose.
- An edge case or piece of domain knowledge that took real digging to
  find (paths, device quirks, provider behavior, machine differences).
- You catch yourself giving the same instruction a second time.

Not lessons: one-off typos, trivia with no future decision attached.

## Where lessons live (this repo)

| Layer | Location | Use for |
|---|---|---|
| Structural fix | `scripts/`, runbooks, lint/check modes (`--check`) | Anything recurring. Strongest layer: enforces itself |
| Runbook | `resource/machine-rotation/`, `resource/microphone/SETUP.md` | Durable operational procedures |
| Handoff unit | `resource/handoff/YYYYMMDD-<topic>.md` | Session-readable context, incidents, open follow-ups |
| Todo | `resource/todos/YYYYMMDD-<topic>.md` | Captured but not yet done |

Sessions read `resource/handoff/` in full at start (AGENTS.md orders
this), so that is where the read-side of a lesson goes until it is
retired.

## Routing — no third state

Every captured lesson ends in exactly one of two states:

1. **Encoded in structure** — a script, check, runbook step, or skill
   edit that makes the failure impossible or self-announcing. Then the
   handoff unit retires and just points at the mechanism.
2. **An open dated unit** in `resource/handoff/` or `resource/todos/`
   with a named next action and, when relevant, a "For <other machine>"
   section.

Never "documented somewhere" with no enforcement and no owner.

## Handoff unit format

```
# YYYY-MM-DD — <topic>

## Symptom        — what the user saw
## Root cause     — why, verified not guessed
## Fix applied    — exact commands, which machine
## Prevention     — the structural fix, or why none is possible
## For <other machine> — check or fix the twin needs after pull
```

Many small units, not one growing file. Retire a unit when its items
are done; fold durable facts into a runbook first.

## Capture checklist

Run this after any incident or correction, and before ending a session
that produced a lesson:

1. Write or update the dated unit (format above).
2. Ask: can this be a script, `--check`, or skill edit? If yes, do it
   now or open a dated todo with the concrete plan.
3. Name what the other machine needs. Parity gaps are the top
   recurrence source in this repo.
4. **Commit and push. A lesson that is not pushed does not exist on the
   other machine.** Live edits under `~/` bypass git and die at rotation.
