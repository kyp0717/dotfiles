# Rust Whisper server setup

A small HTTP server that wraps whisper.cpp (via the `whisper-rs` crate) and serves
an OpenAI-compatible transcription endpoint on port 10301. It loads the local
`ggml-base.bin` model and accepts WAV uploads. This is the backend for the
`pi-voice-stt` voice input.

## What to copy to the new machine

```
rust-whisper-server/
├── Cargo.toml        # dependencies
├── Cargo.lock        # pinned versions (keep this so the build is reproducible)
├── src/main.rs       # the whole server, ~112 lines
└── ggml-base.bin     # the model, 147 MB (or re-download it, see below)
```

Do not copy `target/`. It holds several GB of build artifacts and Cargo will
rebuild it. The log files and the `.service` file are optional; the service file
lives at `~/.config/systemd/user/rust-whisper-server.service` and is reproduced
below.

## Prerequisites

Debian/Ubuntu packages:

```bash
sudo apt install build-essential cmake clang libclang-dev pkg-config libssl-dev
```

`cmake`, a C++ compiler, and `libclang` are needed because `whisper-rs-sys`
compiles whisper.cpp from source and runs bindgen during the build.

On a machine with an NVIDIA GPU (linden), also install the CUDA toolkit so
whisper.cpp can build its CUDA backend:

```bash
sudo apt install nvidia-cuda-toolkit   # provides nvcc
nvidia-smi                             # confirms the driver sees the card
```

Rust toolchain (1.97.0 was used originally, anything recent should work):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## Model file

Either copy `ggml-base.bin` over, or download it from Hugging Face:

```bash
curl -L -o ggml-base.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin
```

Verify the checksum if you want to confirm you have the same file:

```bash
sha256sum ggml-base.bin
# 60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe
```

The file must sit in the server's working directory, since `main.rs` loads the
relative path `ggml-base.bin`.

Other sizes (`ggml-tiny.bin`, `ggml-small.bin`, etc.) come from the same
Hugging Face repo. Bigger models are more accurate and slower. If you switch,
just place the new file next to the binary and update the filename in `main.rs`.

## Build and run

Don't invoke cargo directly. `run.sh` picks the right backend for the
machine it's on (hostname first, `nvidia-smi` probe on unknown hosts),
builds into `target/<backend>/` if needed, and execs the server:

```bash
cd rust-whisper-server
./run.sh
```

| Machine | Backend | Build command run.sh uses |
|---|---|---|
| woodlawn (no NVIDIA GPU) | `cpu` | `cargo build --release` |
| linden (GTX 1070) | `cuda` | `cargo build --release --features cuda` |

The GTX 1070 is a Pascal card (compute capability 6.1), so run.sh sets
`CMAKE_CUDA_ARCHITECTURES=61` for the CUDA build. The first CUDA build takes
a while since it compiles whisper.cpp's CUDA kernels.

The server prints its backend at startup ("Loading GGML Whisper model
(backend: cuda)..."), so check `server.log` or `nvidia-smi` while
transcribing to confirm the GPU is actually in use.

Test it:

```bash
curl http://localhost:10301/health
# OK

curl -X POST http://localhost:10301/v1/audio/transcriptions \
  -F "file=@test.wav" \
  -F "model=whisper-1"
# {"text":" your transcribed text"}
```

Input must be a WAV file, 16 kHz, mono. The server decodes WAV with `hound`
and does not resample, so feed it the right format or convert first with
ffmpeg:

```bash
ffmpeg -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le test.wav
```

## Autostart with systemd (user service)

Create `~/.config/systemd/user/rust-whisper-server.service`, adjusting the
paths to wherever you put the project:

```ini
[Unit]
Description=Rust Whisper STT server (pi-voice-stt local endpoint)
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/USER/path/to/rust-whisper-server
ExecStart=/home/USER/path/to/rust-whisper-server/run.sh
Restart=always
RestartSec=2
StandardOutput=append:/home/USER/path/to/rust-whisper-server/server.log
StandardError=append:/home/USER/path/to/rust-whisper-server/server.err.log

[Install]
WantedBy=default.target
```

Then:

```bash
systemctl --user daemon-reload
systemctl --user enable --now rust-whisper-server
systemctl --user status rust-whisper-server
```

This starts the server at login and restarts it if it crashes. If you want it
running before anyone logs in, enable lingering with
`sudo loginctl enable-linger USER`.

## Notes

- CPU thread count comes from the `WHISPER_THREADS` environment variable
  (default 16, tuned for woodlawn's Threadripper). Set
  `Environment=WHISPER_THREADS=<n>` in the systemd unit on machines with
  fewer cores. With the cuda backend the GPU does the heavy lifting and the
  thread count matters less.
- `WHISPER_USE_GPU=0` forces CPU mode on a CUDA build, for debugging.
- The port (10301) is also hardcoded in `main.rs`. Change it there if it
  collides with something.
- `whisper-rs` is pinned to 0.13.2 in `Cargo.lock`. Keep the lockfile to avoid
  surprises.
- The endpoint mimics OpenAI's `/v1/audio/transcriptions`, so any client that
  talks to OpenAI's audio API can be pointed at `http://localhost:10301`
  instead.
