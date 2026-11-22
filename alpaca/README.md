# Alpaca package

Alpaca trading configuration for both machines (woodlawn and linden).

## Layout

- `.alpaca.env.example` — template for the Alpaca API credentials.
- `.gitignore` — keeps the real `.alpaca.env` out of git. Never commit
  credentials; AGENTS.md forbids secrets in this repo.

## Per-machine setup (both machines)

1. Copy the template to `$HOME`:
   `cp alpaca/.alpaca.env.example ~/.alpaca.env`
2. Fill in `APCA_API_KEY_ID` and `APCA_API_SECRET_KEY` from the Alpaca
   dashboard (paper or live keys, per your use).
3. Open a new nushell. `config.nu` loads `~/.alpaca.env` only when the
   file exists, so a missing file breaks nothing.

## Why not stowed like ibkr-tws

`ibkr-tws` tracks non-secret config (a vmoptions file) and stows it.
The only Alpaca config is credentials, which must stay out of git, so
this package is a template plus docs and the live file is per-machine
state. Recreate steps above.
