#!/usr/bin/env bash
# Selects and launches the correct whisper server build for this machine.
# The systemd unit (rust-whisper-server.service) execs this script, so the
# unit file is identical on woodlawn and linden.
#
# Backends (per-machine facts live in sync/MACHINES.md):
#   cpu   - no NVIDIA GPU (woodlawn). Plain `cargo build --release`.
#   cuda  - NVIDIA GPU (linden, GTX 1070). `cargo build --release --features cuda`.
#           Requires the CUDA toolkit at build time and the NVIDIA driver at runtime.
set -euo pipefail
cd "$(dirname "$0")"

host="$(hostname)"
case "$host" in
  woodlawn) backend=cpu ;;
  linden)
    # CUDA needs nvcc at build time; fall back to cpu when the toolkit is
    # not installed yet (install nvidia-cuda-toolkit to enable the GPU).
    if command -v nvcc >/dev/null 2>&1; then
      backend=cuda
    else
      echo "run.sh: linden has no nvcc, using cpu backend (install nvidia-cuda-toolkit for cuda)" >&2
      backend=cpu
    fi
    ;;
  *)
    # Unknown machine: probe the hardware instead of guessing.
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
      backend=cuda
    else
      backend=cpu
    fi
    ;;
esac

target_dir="target/$backend"
bin="$target_dir/release/rust-whisper-server"

if [ ! -x "$bin" ]; then
  echo "run.sh: no $backend build found, building into $target_dir" >&2
  if [ "$backend" = cuda ]; then
    # GTX 1070 is Pascal, compute capability 6.1.
    CMAKE_CUDA_ARCHITECTURES="${CMAKE_CUDA_ARCHITECTURES:-61}" \
      CARGO_TARGET_DIR="$target_dir" cargo build --release --features cuda
  else
    CARGO_TARGET_DIR="$target_dir" cargo build --release
  fi
fi

echo "run.sh: hostname=$host backend=$backend" >&2
exec "$bin"
