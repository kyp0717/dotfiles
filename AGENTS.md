# Agent Instructions: dotfiles

This repo is the two-machine (woodlawn ↔ linden) configuration for the
agent harnesses and the desktop environment.

## Core requirement: two-machine rotation

woodlawn and linden swap roles every 2 weeks. **Every tracked file must
work on both machines unmodified.** Accommodate differences by probing
at runtime (hostname switch, `command -v`, filesystem checks) or by
per-machine facts in `resource/machine-rotation/MACHINES.md`; never by
hardcoding one machine's paths, binary locations, or hardware in a
tracked file. If a config cannot be made portable, it is per-machine
state: keep it out of git and document the recreate steps. A change
that works only on the machine you are on is broken by definition; the
other machine inherits it at the next rotation.

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
  - `lessons/` — durable knowledge earned from incidents (`domain.*` /
    `edge.*` files, written per the `lesson-learned` skill).
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

- **Capture lessons with the `lesson-learned` skill.** Any incident,
  human correction, edge case, or project domain knowledge that cost
  time to discover gets captured and routed per that skill: structural
  fix first, `resource/lessons/` file (`domain.`/`edge.`) for durable
  knowledge, dated handoff/todo unit for continuation state. Then
  commit and push. When working in a subsystem, scan `resource/lessons/`
  for related entries first.
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
- **Change pi config in the repo, then stow. Never edit `~/.pi` directly.**
  Every pi setting (provider configs in `pi/.pi/providers/`, agent
  extensions, skills, keybindings) is edited inside `~/dotfiles` first
  and deployed with `stow pi` from the repo root. A file created
  directly under `~/.pi` or `~/.agents` bypasses git, diverges across
  machines, and dies on the next clone or rotation. If a live path is
  not a symlink into the repo, it is per-machine state, not a config
  source. Exception: `~/.pi/agent/settings.json`, deployed by copy from
  `resource/pi-agent-settings.json` because pi rewrites it constantly.
- Never hardcode machine-specific paths in tracked files; woodlawn and
  linden differ (see `resource/machine-rotation/MACHINES.md`).
- **Real files live in `~/dotfiles`; symlinks live outside it.** Stow
turns the repo into the source of truth: anything in `~` that comes from
this repo is a symlink pointing into `~/dotfiles`, never a copy and never
the reverse (no symlinks inside the repo, no real config files scattered
in `~`). A file under `~` that is not a symlink into the repo is either
per-machine state (credentials, caches) or not yet adopted.
