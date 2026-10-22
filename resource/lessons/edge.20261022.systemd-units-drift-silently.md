# systemd user units are per-machine state and drift silently

**Date:** 2026-10-18 (linden) and 2026-10-22 (woodlawn) · **Source:**
two identical whisper-server regressions, one per machine.

## What happened

Twice in one week, `rust-whisper-server.service` crash-looped with
`status=203/EXEC` because `ExecStart` pointed at a stale path. On
linden the unit referenced the pre-`resource/` layout; on woodlawn the
same, and a stale copy of the moved directory (`microphone/` at repo
root, 1.1 G of model + build artifacts) masked the drift for days —
the unit kept working until the stale tree was half-deleted and the
machine rebooted.

## Why it happened

Unit files live in `~/.config/systemd/user/`, outside git. Repo moves
and renames never reach them. There is no compile step, no CI, no
signal: the drift is invisible until the service restarts, which on a
long-uptime desktop can be weeks later. The woodlawn parity check that
would have caught it existed in a handoff file but was never run.

## The fix

Both units repointed with
`sed -i 's|dotfiles/microphone/|dotfiles/resource/microphone/|g'`
plus `daemon-reload` + restart; the stale `microphone/` tree was
removed after moving its model and build into the canonical path. The
machine-rotation README parity check now greps the unit's `ExecStart`
for the canonical prefix.

## Rules that fall out

- After any repo move or rename, grep every per-machine unit file for
  the old path, on BOTH machines, same day.
- Delete a moved directory's old copy completely and immediately. A
  half-deleted stale tree is worse than a full one: it masks broken
  references until the next reboot.
- Anything in `~/` that is not a symlink into the repo is per-machine
  state — assume it has drifted.
