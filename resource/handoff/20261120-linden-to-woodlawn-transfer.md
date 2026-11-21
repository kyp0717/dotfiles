# 2026-11-20 — linden -> woodlawn transfer brief

## Done this session (on linden, all committed and pushed)

- **Alibaba Qwen4-Max in pi**: new `pi/.pi/agent/models.json` (provider
  `alibaba`, model `qwen4-max`, 1M context, vision, reasoning; key via
  `$DASHSCOPE_API_KEY`, direct DashScope intl endpoint).
  Details + verify steps: `resource/handoff/20261120-qwen4-max-alibaba-provider.md`.
- **AGENTS.md "Why two machines" section**: linden = CT, woodlawn =
  Boston, alternating weeks, never co-online, never shared LAN. Drives
  all shared-state design (no P2P sync without an always-on third
  point; git push is the carry channel).
- **Shared pi sessions design parked** in
  `resource/todos/20261120-shared-pi-sessions-design.md`
  (recommendation: rclone + crypt on Google Drive; undecided).
- **Lesson**: `resource/lessons/edge.20261120.pi-models-json-location.md`
  — models.json must live in the agent dir (`~/.pi/agent/`, repo:
  `pi/.pi/agent/`), not `~/.pi/`; wrong location fails silently with
  `provider_not_found`.
- **Machine facts**: linden PSU corrected to Corsair AX1200i (AX1200
  and AX1200i cables not interchangeable); case row added
  (Thermaltake, model TBD). Zed ui_font_size 22. nvim plugin lockfile
  now tracked.

## Woodlawn next-machine steps (in order)

1. `git pull` in `~/dotfiles`.
2. `stow pi` from the repo root (links the new `models.json`;
   everything else already linked).
3. **nushell trap**: `config.nu` now ends with
   `source ~/.alpaca.env` (Alpaca trading credentials). If woodlawn
   does not have `~/.alpaca.env`, nushell startup errors on that line.
   Either copy the file from linden (rsync, never git) or comment the
   line out on woodlawn.
4. Export `DASHSCOPE_API_KEY=sk-...` in the shell profile (key from
   the Alibaba Cloud Model Studio console; check the console for
   new-account free quotas). Open a new shell, then verify:
   `pi auth check --provider alibaba --json` -> `ready`, and
   `pi --list-models | grep alibaba` shows `qwen4-max`.
   Base URL caveat: the config uses the international endpoint
   (`dashscope-intl.aliyuncs.com`). A Beijing-region key needs
   `https://dashscope.aliyuncs.com/compatible-mode/v1` instead.
5. `stow` the rest if anything is unlinked:
   `stow -n pi nushell zed nvim` to preview first.

## Still open (carried, not blocking)

- linden's managed pi is 1.4.0 vs pinned 1.5.0 — run
  `scripts/pi.install.sh` on linden next week.
- `pi/.pi/agent/models.json` `cost.cacheRead/cacheWrite` are
  placeholders (set to input price); correct with real cache pricing.
- Qwen4-Max not yet tested with a real key (user creates the key).
- Shared-sessions decision pending (todo file above).
- `resource/todos/TODO.md` items for linden (kimi CLI upgrade etc.)
  carry over.
