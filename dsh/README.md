# dsh

Deployment configuration for dsh (DeepSeek Harness) with the Kimi Code
integration, kept in parity across two computers (woodlawn and linden)
that swap weekly: Kimi CLI as a subagent via ACP, Kimi K3 (1M context) on
your subscription as the main model, NVIDIA free-tier profile.

pi lives in the repo-root `pi/` stow package; whisper voice docs are under
`resource/microphone/`.

## Layout

| Path | Purpose |
|---|---|
| `dsh/scripts/` | Idempotent dsh setup: `setup-kimi.mjs` (bridge install, profile patch, preset, settings), `kimi-login.mjs` (subscription login), `bridge-kimi-token.mjs` (token import, fallback), `install-skills.mjs`, `import-skills.mjs`. Run via `npm run` from the repo root. |
| `dsh/vendor/` | Pinned tarballs for offline install, SHA-256s in git history. |
| `dsh/docs/` | dsh-specific docs: `SETUP.md` (one machine), `KIMI-INTEGRATION.md` (deep dive), `MODIFYING-DSH.md`, `ORCHESTRATION.md` (subagents, workflows, ralph). |
| `dsh/skills/` | dsh's own skill set, an independent copy that may diverge. `npm run skills:install` copies them to `~/.dsh/skills/`. |
| `../pi/` | pi's stow package: `pi/.pi/` → `~/.pi`, `pi/.agents/skills/` → `~/.agents/skills/`. `stow pi` from the repo root. |
| `../resource/docs/` | Harness-agnostic docs: `POTETO-SKILLS-WORKFLOW.md` (using the pstack skills). |
| `../resource/microphone/` | Rust whisper server source + setup doc, plus the pi-voice-stt client extension setup doc. Model and build artifacts stay local. |
| `../resource/machine-rotation/` | Keeping woodlawn and linden identical: the swap runbook (`README.md`) and per-machine facts (`MACHINES.md`). |
| `../resource/handoff/` | Session continuation briefs, one dated file per topic. Read first in a new context window. |

## Quick start (one machine)

```bash
git clone git@github.com:kyp0717/dotfiles.git ~/dotfiles && cd ~/dotfiles

# dsh
npm run dsh:setup        # idempotent; safe to re-run
npm run dsh:kimi-login   # per-machine subscription credential
npm run skills:install   # repo skills → ~/.dsh/skills

# pi: providers + skills + extensions via stow
stow pi

# pi voice: whisper server plus client extension
# see resource/microphone/rust-whisper-server/SETUP.md and
# resource/microphone/pi-voice-stt-setup.md
```

Full procedures: [`dsh/docs/SETUP.md`](dsh/docs/SETUP.md) for dsh,
[`../resource/microphone/rust-whisper-server/SETUP.md`](../resource/microphone/rust-whisper-server/SETUP.md)
for the whisper server, and [`../resource/machine-rotation/README.md`](../resource/machine-rotation/README.md) for the
fresh-machine runbook and weekly swap.
