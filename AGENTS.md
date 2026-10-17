# Agent Instructions: dotfiles

This repo is the two-machine (woodlawn ↔ linden) configuration for the
agent harnesses and the desktop environment.

**First action in every session here: read the handoff files in
`resource/handoff/` in full.** They are the continuation brief: current
live state per machine, pending follow-ups, repo layout. Work in this
repo without them breaks things the briefs already explain. If one names
a "next machine" section for the machine you are on, do those steps
before anything else.

## Layout

- `pi/` — stow package for pi itself, same pattern as `nushell/`,
  `wezterm/`, `starship/`: `stow pi` from the repo root links its
  contents into `~` — `pi/.pi/` → `~/.pi` (providers, agent extensions)
  and `pi/.agents/skills/` → `~/.agents/skills/` (the skill set pi
  discovers, pstack plus `swarm`, `recall`, `bro`, etc.). No secrets:
  nothing with credentials, sessions, or auth may be tracked.
  `~/.pi/agent/settings.json` is NOT stowed (pi rewrites it constantly);
  the tracked reference copy is `resource/pi-agent-settings.json`,
  deployed by copy, never symlink.
- `dsh/` — the DeepSeek harness + Kimi integration: `dsh/scripts/`
  (npm scripts, run from the repo root), `dsh/docs/`, `dsh/skills/`,
  `dsh/vendor/`.
- `resource/` — all docs and operational state:
  - `handoff/` — continuation briefs (see convention below).
  - `todos/` — open reminders and task lists (same convention).
  - `machine-rotation/` — the woodlawn ↔ linden swap runbook and
    per-machine facts (`MACHINES.md`).
  - `microphone/` — the whisper STT server (Rust). Kept out of the stow
    package; its `target/`, model, and logs are gitignored.
  - `docs/` — harness-agnostic docs (`POTETO-SKILLS-WORKFLOW.md`).
  - `README.md`, `usage.md` — repo overview and usage notes.
- `scripts/` — install/setup scripts (`setup-all.sh` composes them).
- Tool stow packages: `pi/`, `nushell/`, `nvim/`, `shell/`, `starship/`,
  `wezterm/`; `ibkr-tws/` holds the TWS vmoptions override.

## Rules

- **Commit everything portable to git.** Per-machine state stays out of
  git and must have documented recreate steps.
- **Handoff and todo files: many small units, not one growing file.**
  Write them as `YYYYMMDD-<topic>.md` inside `resource/handoff/` and
  `resource/todos/`. A new session reads the newest datestamp first;
  retire a unit when its items are done rather than appending forever.
- **Two skill sets, two owners, both independent.** pi's set is
  `pi/.agents/skills/` (stowed to `~/.agents/skills/` by `stow pi`),
  dsh's is `dsh/skills/` (installed to `~/.dsh/skills/` by
  `npm run skills:install`). Never point one harness at the other's
  directory.
- pi config, skills, and extensions deploy with one command:
  `stow pi` from the repo root. dsh scripts run with npm from the repo
  root (`npm run dsh:setup`, `npm run skills:install`, …).
- Never hardcode machine-specific paths in tracked files; woodlawn and
  linden differ (see `resource/machine-rotation/MACHINES.md`).
