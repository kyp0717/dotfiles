# Agent Instructions: dotfiles

This repo is the two-machine (woodlawn ↔ linden) configuration for the
agent harnesses and the desktop environment.

**First action in every session here: read `HANDOFF.md` in full.** It is
the continuation brief — current live state per machine, pending
follow-ups, repo layout. Work in this repo without it breaks things the
brief already explains. If it names a "next machine" section for the
machine you are on, do those steps before anything else.

## Layout

- `harness/` — the agent harness configs: `pi/` (stow package for
  `~/.pi/agent/`: skills + extensions), `dsh/` (DeepSeek harness + Kimi
  integration), `docs/`.
- `machine-rotation/` — the woodlawn ↔ linden swap runbook and
  per-machine facts (`MACHINES.md`).
- `microphone/` — the whisper STT server (Rust). Kept out of the stow
  package; its `target/`, model, and logs are gitignored.

## Rules

- **Commit everything portable to git.** Per-machine state stays out of
  git and must have documented recreate steps.
- **pi and dsh skill sets are independent.** pi's set is
  `harness/pi/skills/`, dsh's is `harness/dsh/skills/`. Never point one
  harness at the other's directory.
- pi consistency across machines is stow:
  `stow -d ~/dotfiles/harness -t ~/.pi/agent pi`.
- Never hardcode machine-specific paths in tracked files; woodlawn and
  linden differ (see `machine-rotation/MACHINES.md`).
