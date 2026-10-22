# 2026-10-22 — "Microphone error" on woodlawn was the whisper server, not the mic

## Symptom

pi-voice-stt errors in the terminal after the 08:00 boot. Looked like the
known post-suspend Blue Yeti wedge; it was not.

## Diagnosis (the useful part: two layers, check the cheap one first)

A "microphone error" in pi splits into two independent layers:

1. **Transcription layer** — the whisper server.
   `systemctl --user is-active rust-whisper-server` +
   `curl -s localhost:10301/health` (expect `OK`). Five seconds.
2. **Capture layer** — the USB mic + pipewire.
   `wpctl status` (default source must be `* Blue Microphones`), then a
   2 s capture: `ffmpeg -f pulse -i default -t 2 t.wav` and check peak
   amplitude is nonzero (a live mic never reads digital zero; room tone
   here peaked ~2000–4000).

On woodlawn the capture layer was fine all along. The transcription layer
was dead: service `activating (auto-restart)`, restart counter at 1121,
`status=203/EXEC`.

## Root cause

Same regression class as `20261018-whisper-unit-path-regression.md`
(linden), this time on woodlawn:

- The unit's `ExecStart` still pointed at the pre-`resource/` path
  `dotfiles/microphone/rust-whisper-server/run.sh`. The "For woodlawn"
  check in that handoff was never run here.
- A stale `microphone/` tree at the repo root (1.1 G: model, `target/`,
  logs) **masked** the broken unit: the Oct 19 boot still found `run.sh`
  there, so the server ran fine for days.
- The stale tree then got partially cleaned (run.sh/src removed, model +
  build left behind). Nothing noticed while the machine stayed up; the
  next boot (Oct 22 08:00) hit the missing `run.sh` and crash-looped.

## Fix applied (woodlawn, 2026-10-22)

```bash
# model sha256 verified against run.sh's expected value first
mv microphone/rust-whisper-server/ggml-base.bin resource/microphone/rust-whisper-server/
mkdir -p resource/microphone/rust-whisper-server/target
mv microphone/rust-whisper-server/target/cpu resource/microphone/rust-whisper-server/target/
rm -rf microphone          # stale tree gone, nothing left to mask drift
sed -i 's|dotfiles/microphone/|dotfiles/resource/microphone/|g' \
  ~/.config/systemd/user/rust-whisper-server.service
systemctl --user daemon-reload && systemctl --user restart rust-whisper-server
```

Verified: `active`, `/health` OK, transcription round trip through
`/v1/audio/transcriptions` returns JSON. Also ran the long-overdue
`stow pi` (handoff §0 step 1): `~/.agents` and `~/.pi/providers` are now
symlinks into the repo, 51 skills live, two dangling extension links
repointed.

## Lessons

- **Check `/health` before touching the mic.** Server down and mic wedged
  produce identical user-facing errors; the health curl is 5 seconds and
  splits the problem space in half.
- **A stale copy of a moved directory masks broken references until
  reboot.** When a path moves, delete the old tree completely and
  immediately — a half-deleted tree is worse than a full one, because
  everything looks fine until the next restart.
- **Parity checks run on BOTH machines, every repo move.** The 2026-10-18
  handoff named this exact check for woodlawn (`grep microphone
  ~/.config/systemd/user/rust-whisper-server.service`); it was skipped
  and cost a morning. Unit files are per-machine state and drift
  silently.
- **pi-voice-stt records via `ffmpeg -f pulse -i default`** on Linux (no
  `capture` override in `~/.pi/agent/stt.json`). Its terminal errors are
  "Recording is silent"/"too small" for capture-layer faults and HTTP
  errors for transcription-layer faults — the message text tells you the
  layer.
- **An install script nobody runs is the same as no script.**
  `scripts/util.sh` already installed `wl-clipboard`, but `setup-all.sh`
  never called it, so woodlawn lacked it and pi copy/paste broke. Required
  packages and udev rules now live in `scripts/setup-packages.sh` and
  `scripts/setup-udev.sh`, both wired into `setup-all.sh` and the
  machine-rotation fresh-machine recipe, both with a sudo-free `--check`
  mode for parity verification.

## Still open

Run once on woodlawn (needs sudo), then verify on linden with `--check`:

```bash
scripts/setup-packages.sh   # installs wl-clipboard + xclip (pi copy/paste)
scripts/setup-udev.sh       # installs the Yeti autosuspend defense
```

- HANDOFF.md §0 (next-machine: woodlawn) is now effectively done —
  `stow pi` + unit fix landed today; prune it next session.
