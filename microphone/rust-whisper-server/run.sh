#!/usr/bin/env bash
# Selects and launches the correct whisper server build for this machine.
# The systemd unit (rust-whisper-server.service) execs this script, so the
# unit file is identical on woodlawn and linden.
#
# Backends (per-machine facts live in machine-rotation/MACHINES.md):
#   cpu   - no CUDA GPU (woodlawn, and linden since the AMD 6700 XT swap).
#           Plain `cargo build --release`.
#   cuda  - NVIDIA GPU only. `cargo build --release --features cuda`.
#           Requires the CUDA toolkit at build time and the NVIDIA driver.
set -euo pipefail
cd "$(dirname "$0")"

host="$(hostname)"
case "$host" in
  woodlawn) backend=cpu ;;
  linden)
    # AMD 6700 XT since 2026-10 (was GTX 1070 + CUDA). whisper-rs has no
    # ROCm/Vulkan feature here, so linden uses the cpu backend.
    backend=cpu
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
    # Compute capability for the target NVIDIA GPU; 61 is Pascal (old GTX 1070).
    CMAKE_CUDA_ARCHITECTURES="${CMAKE_CUDA_ARCHITECTURES:-61}" \
      CARGO_TARGET_DIR="$target_dir" cargo build --release --features cuda
  else
    CARGO_TARGET_DIR="$target_dir" cargo build --release
  fi
fi

echo "run.sh: hostname=$host backend=$backend" >&2
exec "$bin"
