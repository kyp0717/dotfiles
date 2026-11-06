# 20261106 pi-session-move + /move-session alias

## Done on woodlawn (this machine)

- `scripts/pi.requirements.txt`: added `npm:pi-session-move@0.1.14`;
  harness bumped `pi-coding-agent` 1.4.0 -> 1.5.0.
- New repo-local extension `pi/.pi/agent/extensions/move-session-alias.ts`:
  rewrites `/move-session` -> `/move` (input-event transform) so the
  pi-session-move command is reachable under both names. Deploys via
  `stow pi` to `~/.pi/agent/extensions/`.
- `scripts/pi.install.sh` now checks that the alias extension exists
  whenever pi-session-move is in the requirements; `--check` reports
  `MISSING move-session-alias.ts (run: stow pi from the repo root)`.

## Next machine (linden)

1. `git pull` in `~/dotfiles`.
2. `scripts/pi.install.sh` (installs pi-session-move, harness 1.5.0).
3. `stow pi` from the repo root (links the alias extension).
4. `scripts/pi.install.sh --check` must pass with no MISSING lines.

The custom change lives in the repo, so steps 1 + 3 are the whole
transfer; pi.install.sh --check catches a missed stow.

## Verify

In a pi session: `/move-session <target-dir>` should behave exactly
like `/move <target-dir>` (session copied to the target cwd bucket,
live process switched). `/move` still works unchanged.
