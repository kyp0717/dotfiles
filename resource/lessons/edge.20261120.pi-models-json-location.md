# Lesson: pi's models.json must live in the agent directory (~/.pi/agent), not ~/.pi

Date: 2026-11-20. Machine: linden.

## What happened

Adding a custom provider (Alibaba Qwen4-Max) to pi. First attempt placed
`models.json` at `~/.pi/models.json` (stowed from `pi/.pi/models.json`).
`pi --list-models` silently omitted the provider and
`pi auth check --provider alibaba` returned
`{"status":"not_ready","reason":"provider_not_found"}` — no warning about
the unread file.

## Root cause

pi's agent directory defaults to `~/.pi/agent` (see
`docs/configuration.md`, "Agent directory", in any installed release).
`<agent-dir>/models.json` is the only models.json pi reads. The repo's
stow package mirrors this: `pi/.pi/agent/settings.json` stows to
`~/.pi/agent/settings.json`. A models.json one level up at `~/.pi/` looks
plausible (settings.json-adjacent in old layouts) and is silently
ignored.

## Rule

Custom providers/models go in `pi/.pi/agent/models.json` in the repo,
deployed with `stow pi` to `~/.pi/agent/models.json`. Verify with
`pi auth check --provider <id> --json` -> `ready`; if you get
`provider_not_found`, the file is in the wrong directory or has a JSON
error, and pi will not tell you which.

## Also noted

`pi --version` on linden reported 1.4.0 from the managed install
(`~/.pi/agent/bin/pi` wrapper -> `~/.pi/agent/install/releases/`), while
an npm-global pi (nvm path, 1.6.0) also exists. `which pi` order decides
which docs and behavior apply. The repo pins the managed-install flow via
`scripts/pi.install.sh`; check `~/.pi/agent/install/current-version`
against `scripts/pi.requirements.txt` when behavior seems off.
