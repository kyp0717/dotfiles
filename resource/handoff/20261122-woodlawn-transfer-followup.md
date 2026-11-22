# 2026-11-22 — woodlawn: transfer steps done, provider verified, keys pending

## Done this session (on woodlawn)

- `git pull` (after discarding incidental `settings.json` churn;
  local `hideThinkingBlock: false` was reset to the repo's `true` —
  remote is source of truth).
- Transfer brief `20261120-linden-to-woodlawn-transfer.md` steps:
  - `stow pi` — links `~/.pi/agent/models.json` (alibaba provider).
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
- Alibaba provider verified registered on woodlawn:
  `pi auth check --provider alibaba --json` ->
  `credentials_not_configured` (expected without a key;
  `provider_not_found` would mean a config problem). Note:
  `pi --list-models` hides credential-less custom models by design.
- Lessons written: nushell conditional env load, stow real-file drift.

## Open (user actions)

- Create a DashScope API key (Alibaba Cloud Model Studio console) and
  `export DASHSCOPE_API_KEY=sk-...` in the shell profile on BOTH
  machines, then `pi auth check --provider alibaba --json` -> `ready`.
  See `resource/todos/20261122-dashscope-api-key.md`.
- Create `~/.alpaca.env` on woodlawn from `alpaca/.alpaca.env.example`
  (copy from linden is impossible while machines are never co-online;
  key from the Alpaca dashboard).

## For linden at next rotation

- Pull, then re-run `stow pi` and `stow zed` if targets drifted there
  the same way woodlawn's zed had.
- linden still owes `scripts/pi.install.sh` (managed pi 1.4.0 vs
  pinned 1.5.0 per the 20261120 brief).
