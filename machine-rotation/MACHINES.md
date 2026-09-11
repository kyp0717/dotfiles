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
| Repo path | `/home/phage/dotfiles/harness` | `/home/phage/dotfiles/harness` |

**Repo location (2026-09-11):** the canonical checkout on both machines is
`~/dotfiles` (no dot). `~/.dotfiles` is retired; if a machine still has the
checkout there, move it and fix the whisper unit paths (see the incident
section in the whisper SETUP.md).

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
- The unit's `WorkingDirectory`/`ExecStart`/log paths must match this
  machine's actual checkout. A mismatch does not fail in the app — it
  crash-loops with `status 209/STDOUT` and voice input just dies.

## Notes

- The whisper model file (`ggml-base.bin`, 147 MB) is not in git. Transfer it
  with rsync or re-download; the sha256 is in the whisper SETUP.md.
- dsh has no per-machine tuning beyond secrets; `npm run dsh:setup` writes
  identical config everywhere.

## Two-machine rules

Inherited from the ls-trader two-machine workflow; they apply to everything
in this repo:

- **Identify the machine first.** Run `hostname` before any setup or
  diagnosis. Per-machine facts live in this file; acting on the wrong
  assumption breaks things (the 2026-09-11 whisper outage: a unit written
  against `~/.dotfiles` while the checkout is `~/dotfiles`).
- **Commit everything portable.** Never leave finished work uncommitted on
  one machine; the weekly swap assumes `git push`/`git pull`.
- **Never hardcode machine-specific paths, hostnames, or users in tracked
  files.** Render them at setup time from the facts in this file.
- **Per-machine state stays out of git** and needs documented recreate steps
  (the systemd units, `stt.json`, Kimi/dsh credentials, API keys).

## Trading host context

The trading setup (ls-trader + the Windows bridge VM) rotates across the
same two hosts. These facts change rarely; the master copy lives in the
ls-trader sibling repo at `~/work/tradedeck-cpp/docs/bare-metal-vm.md`
("Machine rotation") — update it there, not here.

| | woodlawn | linden |
|---|---|---|
| VM domain | `tiny11` | `linden-tiny11` (rename to `tiny11` pending) |
| VM Windows user (SSH) | `Phage` | `linden-tiny11` |
| Wired NIC | `eno1` (Intel I225-V quirks) | `enp12s0` |
