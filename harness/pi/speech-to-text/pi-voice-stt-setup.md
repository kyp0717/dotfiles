# pi-voice-stt (client extension) setup

The pi side of voice input. The official npm extension `pi-voice-stt` records
with ffmpeg, transcribes through a provider, and inserts the transcript into
the pi prompt. On both machines it points at the local whisper server on port
10301.

## Install

```bash
sudo apt install -y ffmpeg
pi install npm:pi-voice-stt
```

`pi install` adds `npm:pi-voice-stt` to `~/.pi/agent/settings.json` and
installs the package to `~/.pi/agent/npm/node_modules/pi-voice-stt`.

ffmpeg is required. The official extension records only with ffmpeg (it has
no pw-record path), which is also why it works unchanged on Linux, macOS, and
Windows.

## Config

`~/.pi/agent/stt.json` is the default config path. Provider type `local`
targets the whisper server on localhost:10301, model `whisper-1`, no API key.

```json
{
  "provider": {
    "type": "local"
  }
}
```

Capture defaults to ffmpeg `-f pulse -i default` at 16 kHz mono on Linux.
The full config written on linden 2026-09-08 is equivalent to this plus the
default capture and output blocks.

## Keys and commands

- `ctrl+r` record, `ctrl+r` again to stop and insert into the prompt
- `Enter` while recording stops and sends the transcript straight to chat
- `Esc` while recording cancels
- `alt+r` profile menu
- `/stt status`, `/stt doctor`, `/stt start|stop|send|cancel`

## History

- An earlier hand-written extension shared this name and used pw-record, so it
  needed no ffmpeg. It was removed on 2026-09-08 and replaced by the npm
  package. Do not recreate it.
- The whisper server is the transcription backend. See
  [rust-whisper-server/SETUP.md](rust-whisper-server/SETUP.md).

## Troubleshooting

- **Recording starts but no transcript inserts.** The whisper server is
down, not the mic. `curl -m 3 localhost:10301/health` must print `OK`;
check `systemctl --user status rust-whisper-server` and `journalctl --user
-u rust-whisper-server -n 20`. Server-side faults (stale unit paths after a
repo move, missing `ggml-base.bin`) and the verification checklist are in
the incident section of
[rust-whisper-server/SETUP.md](rust-whisper-server/SETUP.md).
- **Nothing records at all.** ffmpeg missing (`command -v ffmpeg`) or the
mic is captured/ dead at the OS level. On linden the Blue Yeti has known
PipeWire and USB failure modes; see the ls-trader doc
`resource/linden-blue-yeti-microphone-issues.md`.
