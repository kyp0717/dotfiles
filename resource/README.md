# Dotfiles

Two-machine (woodlawn ↔ linden) development environment configuration,
managed with GNU Stow. Agent-facing instructions live in `../AGENTS.md`.

## Layout

| Path | Purpose |
|---|---|
| `../AGENTS.md` | Agent instructions. Read first in an agent session. |
| `../dsh/` | DeepSeek harness + Kimi integration: scripts (npm, run from repo root), docs, skills, vendor tarballs |
| `handoff/` | Continuation briefs, one small dated file per topic (`YYYYMMDD-<topic>.md`) |
| `todos/` | Open reminders and task lists, same datestamp convention |
| `machine-rotation/` | Woodlawn ↔ linden swap runbook (`README.md`) and per-machine facts (`MACHINES.md`) |
| `microphone/` | Whisper STT server (Rust) + pi voice client setup docs |
| `usage.md` | Usage notes |
| `../scripts/` | Install/setup scripts (`bootstrap.sh` composes them) |
| `../pi/` | pi stow package: `pi/.pi/` → `~/.pi` (providers, agent extensions), `pi/.agents/skills/` → `~/.agents/skills/` (skill set). `stow pi` from the repo root. No secrets |
| `../nushell/`, `../nvim/`, `../shell/`, `../starship/`, `../wezterm/` | Per-tool stow packages |
| `../ibkr-tws/` | TWS vmoptions override |

## Quick start (fresh machine)

```bash
git clone git@github.com:kyp0717/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/path.config.sh
./scripts/bootstrap.sh          # or run scripts individually

# Deploy tool configs
stow -d ~/dotfiles pi nushell shell starship wezterm
stow -d ~/dotfiles nvim         # vanilla kickstart.nvim (git submodule)
```

Harness setup (dsh + pi) and the weekly machine swap:
`../dsh/README.md` and `machine-rotation/README.md`.

## Stow commands

```bash
stow -d ~/dotfiles <pkg>     # deploy
stow -D <pkg>                # remove
stow -R <pkg>                # restow
stow -n -v <pkg>             # dry run
```

pi providers, skills, and extensions deploy together:
`stow -d ~/dotfiles pi`.
