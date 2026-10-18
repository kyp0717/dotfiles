# 2026-10-18 — Whisper unit path regression on linden (fixed)

## Symptom

Voice input dead in pi. `systemctl --user status rust-whisper-server`
showed crash-loop, exit `status 209/STDOUT`, `ExecStart=/home/phage/dotfiles/
microphone/rust-whisper-server/run.sh`. That path has not existed since the
microphone tree moved under `resource/` (2026-09-11 layout).

## Root cause

`resource/machine-rotation/README.md` still showed the pre-`resource/`
path (`microphone/rust-whisper-server/...`) in the fresh-machine recipe,
the swap routine, and the synced-vs-per-machine table. The unit had been
recreated from those stale paths, so every restart failed before exec.

Secondary staleness fixed in the same file:

- Swap routine said `cd ~/dotfiles && git pull && cd harness` — `harness/`
  was restructured away 2026-09-03; npm scripts now run from the repo root.
- `dsh/docs/SETUP.md` link was `../dsh/...`, which resolves to the
  nonexistent `resource/dsh/`; now `../../dsh/...`.
- pi stow table said `pi/skills/`, `pi/extensions/`; actual layout is
  `pi/.agents/skills/`, `pi/.pi/`.
- Microphone doc links normalized to `../../resource/microphone/...`.

## Fix applied (linden, 2026-10-18)

```bash
sed -i 's|dotfiles/microphone/|dotfiles/resource/microphone/|g' \
  ~/.config/systemd/user/rust-whisper-server.service
systemctl --user daemon-reload && systemctl --user restart rust-whisper-server
```

Verified: service active, `curl localhost:10301/health` → OK, ffmpeg
capture (pulse, default = Blue Yeti, unmuted 57%) → transcription round
trip works. Yeti udev rule `50-yeti-no-autosuspend.rules` still installed.

## Prevention

- README parity check now greps `ExecStart` in the unit for the
  `~/dotfiles/resource/microphone/...` prefix. Run it after any repo move.
- Troubleshooting row updated: canonical unit paths are
  `~/dotfiles/resource/microphone/rust-whisper-server/`.

## For woodlawn

After `git pull`, check the unit there too:

```bash
grep microphone ~/.config/systemd/user/rust-whisper-server.service
# must say resource/microphone; if not, apply the sed above
```
