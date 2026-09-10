# Machines

Facts that differ between the two computers. Update this file when hardware,
installs, or tuning change. Anything not listed here should be identical on
both (enforced by the repo, see `README.md` in this folder).

| | woodlawn | linden |
|---|---|---|
| Status | current daily driver | active since 2026-09-07; mic is a Blue Yeti (see ls-trader resource doc for its suspend/resume failure modes) |
| CPU | Threadripper, 16 threads used for whisper | Ryzen, 24 threads; `WHISPER_THREADS` not tuned yet (GPU does the work) |
| GPU | none (no NVIDIA card, no `nvidia-smi`) | GTX 1070, 8 GB, Pascal (compute capability 6.1) |
| Whisper backend (`run.sh` picks by hostname) | `cpu` | `cuda` — nvidia-cuda-toolkit 12.4 installed 2026-09-07 (`/usr/bin/nvcc`, accepts system gcc-15); run.sh falls back to `cpu` if nvcc disappears |
| OS | Linux (systemd) | Ubuntu 26.04 (systemd), PipeWire + WirePlumber |
| Whisper threads (`WHISPER_THREADS` env) | 16 (default) | set in the systemd unit once cores are known |
| Whisper server port | 10301 | 10301 (same, hardcoded) |
| Repo path | `/home/phage/.dotfiles/harness` | same, assumed |

## Per-machine services

**rust-whisper-server** (systemd user service, both machines):

- Unit: `~/.config/systemd/user/rust-whisper-server.service`
- `ExecStart` points at `run.sh`, which picks the `cpu` or `cuda` build by
  hostname and builds it if missing. The unit file is identical on both
  machines.
- `WorkingDirectory` is `<repo>/pi/speech-to-text/rust-whisper-server`. If
  the repo moves, update the unit and `systemctl --user daemon-reload`.
- `Restart=always`, starts at login (`WantedBy=default.target`),
  `Linger=no`.
- Logs: `server.log` / `server.err.log` in the working directory (gitignored).

## Notes

- The whisper model file (`ggml-base.bin`, 147 MB) is not in git. Transfer it
  with rsync or re-download; the sha256 is in the whisper SETUP.md.
- dsh has no per-machine tuning beyond secrets; `npm run dsh:setup` writes
  identical config everywhere.
