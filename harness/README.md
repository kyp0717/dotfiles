# ai-harness

Deployment configuration for the two agent harnesses you run, kept in parity
across two computers (woodlawn and linden) that swap weekly:

- **dsh** (DeepSeek Harness) with the Kimi Code integration: Kimi CLI as a
  subagent via ACP, Kimi K3 (1M context) on your subscription as the main
  model, NVIDIA free-tier profile.
- **pi**, with voice input via the official `pi-voice-stt` npm extension and
  a local whisper speech-to-text server (OpenAI-compatible endpoint on port
  10301) as its transcription backend.

## Layout

| Path | Purpose |
|---|---|
| `dsh/scripts/` | Idempotent dsh setup: `setup-kimi.mjs` (bridge install, profile patch, preset, settings), `kimi-login.mjs` (subscription login), `bridge-kimi-token.mjs` (token import, fallback), `install-skills.mjs`, `import-skills.mjs`. |
| `dsh/vendor/` | Pinned tarballs for offline install, SHA-256s in git history. |
| `dsh/docs/` | dsh-specific docs: `SETUP.md` (one machine), `KIMI-INTEGRATION.md` (deep dive), `MODIFYING-DSH.md`, `ORCHESTRATION.md` (subagents, workflows, ralph). |
| `pi/speech-to-text/` | Rust whisper server source + setup doc, plus the pi-voice-stt client extension setup doc. Model and build artifacts stay local. |
| `.agents/skills/` | 30 vendored skills (pstack-strict). pi auto-discovers them in this repo; `npm run skills:install` copies them to `~/.dsh/skills/`. |
| `docs/` | Harness-agnostic docs: `POTETO-SKILLS-WORKFLOW.md` (using the pstack skills). |
| `sync/` | Keeping woodlawn and linden identical: the swap runbook (`README.md`) and per-machine facts (`MACHINES.md`). |
| `HANDOFF.md` | Session continuation brief. Read first in a new context window. |

## Quick start (one machine)

```bash
git clone git@github.com:kyp0717/dotfiles.git ~/.dotfiles && cd ~/.dotfiles/harness

# dsh
npm run dsh:setup        # idempotent; safe to re-run
npm run dsh:kimi-login   # per-machine subscription credential
npm run skills:install   # repo skills → ~/.dsh/skills

# pi voice: whisper server plus client extension
# see pi/speech-to-text/rust-whisper-server/SETUP.md and
# pi/speech-to-text/pi-voice-stt-setup.md
```

Full procedures: [`dsh/docs/SETUP.md`](dsh/docs/SETUP.md) for dsh,
[`pi/speech-to-text/rust-whisper-server/SETUP.md`](pi/speech-to-text/rust-whisper-server/SETUP.md)
for the whisper server, and [`sync/README.md`](sync/README.md) for the
fresh-machine runbook and weekly swap.
