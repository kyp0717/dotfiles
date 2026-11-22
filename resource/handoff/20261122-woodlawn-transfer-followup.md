# 2026-11-22 — woodlawn: transfer steps done; alibaba provider removed

## Done this session (on woodlawn)

- `git pull` (after discarding incidental `settings.json` churn;
  local `hideThinkingBlock: false` was reset to the repo's `true` —
  remote is source of truth).
- Transfer brief `20261120-linden-to-woodlawn-transfer.md` steps:
  - `stow pi` — deployed pi config.
  - REMOVED same day: the Alibaba/Qwen4-Max provider
    (`pi/.pi/agent/models.json`) and the DASHSCOPE todo. User decided
    they won't need it; config deleted from the repo and unstowed,
    `pi --list-models` no longer lists alibaba. The 20261120 handoffs
    and the models.json-location lesson keep their references as
    history.
  - Zed: live file was a drifted real file, not a symlink. Backed up,
    merged woodlawn's `agent_servers` into the repo settings, restowed.
    Repo zed settings are the source of truth (user ruling).
  - Alpaca trap fixed with a runtime guard in `config.nu` instead of a
    bare `source ~/.alpaca.env` (see lesson
    `domain.20261122.nushell-conditional-env-load.md`).
- New `alpaca/` package (README, `.alpaca.env.example`, .gitignore for
  the real env file). Emulates `ibkr-tws/` but stays a template package
  because the config is credentials and AGENTS.md forbids secrets in
  git. AGENTS.md layout section updated.
- Lessons written: nushell conditional env load, stow real-file drift.

## Open (user actions)

- Create `~/.alpaca.env` on woodlawn from `alpaca/.alpaca.env.example`
  (copy from linden is impossible while machines are never co-online;
  key from the Alpaca dashboard). No DashScope key needed; provider
  removed.

## For linden at next rotation

- Pull, then `stow -D pi && stow pi` to drop the now-dangling
  `~/.pi/agent/models.json` symlink (alibaba provider removed).
- Re-run `stow zed` if the target drifted there the same way
  woodlawn's zed had.
- linden still owes `scripts/pi.install.sh` (managed pi 1.4.0 vs
  pinned 1.5.0 per the 20261120 brief).
