# Mic errors split into capture and transcription layers; check the server first

**Date:** 2026-10-22 · **Source:** woodlawn "microphone error in the
terminal" incident, whisper server restart counter at 1121.

## What happened

Voice input failed in pi. The visible symptom (an error when invoking
voice input) pointed at the microphone, and the known Yeti post-suspend
wedge made that diagnosis tempting. The mic was fine: the Yeti was
enumerated, pipewire's default source was the Yeti, and both
`ffmpeg -f pulse -i default` and direct ALSA captures returned real
signal (peak amplitude ~2000–4000 for room tone). The actual fault was
the whisper server crash-looping with `status=203/EXEC` — pi-voice-stt
had nothing to POST to.

## Why it happened

The voice pipeline has two independent layers that fail with identical
user-facing symptoms:

1. **Transcription layer** — the whisper server
   (`systemctl --user is-active rust-whisper-server`,
   `curl -s localhost:10301/health` → `OK`).
2. **Capture layer** — USB mic → pipewire/pulse
   (`wpctl status` default source, 2 s ffmpeg capture, check peak
   amplitude is nonzero).

pi-voice-stt's terminal errors name the layer: "Recording is silent" /
"too small" = capture layer; HTTP/connection errors = transcription
layer. It records via `ffmpeg -f pulse -i default` on Linux (no
`capture` override in `~/.pi/agent/stt.json`).

## The fix

Repointed the systemd unit and restored the build artifacts (see
`resource/handoff/20261022-whisper-server-down-woodlawn.md`). No code
change — this lesson is the durable part.

## Rules that fall out

- Run `curl -s localhost:10301/health` before touching the mic. Five
  seconds, splits the problem space in half.
- A live mic never records digital zero; peak amplitude of room tone is
  nonzero. Silence = wrong source or wedged device.
- Read the error text: pi-voice-stt tells you which layer failed.
