## Project Resource

This project's memory lives in `resource/`. Every agent session reads
this section first and files what it learns before the work is
committed. One file per topic, dated, retired when done — many small
files, never one growing log.

Building and maintaining this structure is a critical part of project
memory and continuity: a red diagnosis without a file in `resource/` is
not finished work.

### The split

- `resource/lessons/` — what the outside world taught us: platform
  behavior, environment surprises, harness quirks, domain facts.
  Naming: `domain.<YYYYMMDD>.<title>.md` for durable knowledge,
  `edge.<YYYYMMDD>.<title>.md` for something the happy path missed.
- `resource/bugs/` — what this codebase did wrong, separated from
  lessons. Naming: `edge.<YYYYMMDD>.<title>.md`, or
  `regression.<YYYYMMDD>.<title>.md` when a fixed bug came back.
  Follow `resource/bugs/README.md` for the split rule.
- `resource/handoff/` — continuation briefs: what the next session or
  the other machine needs to know to pick up safely. One file per
  topic, `YYYY-MM-DD-<topic>.md`. Read the newest datestamp first;
  retire a unit when its items are done.
- `resource/plans/` — design candidates, decisions, and migration
  paths that outlive a chat session. One file per plan.
- `resource/todos/` — open reminders and task lists, same naming
  convention as handoff. Small units, retired when done.

### Session rules

- File a lesson or bug before committing the work that taught it.
- Read the newest handoff file at the start of every session.
- Commit everything in `resource/` with the code it explains.
- Never hardcode machine-specific paths or facts in tracked files;
  record them in the AGENTS.md machine-facts section or in handoff
  files with recreate steps.
