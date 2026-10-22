#!/usr/bin/env bash
# setup-packages.sh — install the apt packages the harness needs.
#
# Idempotent: packages already installed are skipped. Safe to re-run on a
# drifted machine. This is the single source of truth for required apt
# packages; scripts/util.sh (desktop extras) is separate.
#
# Usage:
#   scripts/setup-packages.sh          install anything missing (needs sudo)
#   scripts/setup-packages.sh --check  report what's missing, install nothing
#
# Why each package is required:
#   stow            deploys pi/nushell/wezterm/... configs from this repo
#   ffmpeg          pi-voice-stt records with it (`-f pulse -i default`)
#   wl-clipboard    pi clipboard on Wayland (wl-copy/wl-paste); without it
#                   copy/paste inside pi fails ("Clipboard unavailable")
#   xclip           pi clipboard fallback on X11
#   build-essential, pkg-config, libssl-dev, cmake
#                   build the whisper server (whisper-rs compiles whisper.cpp)
#   curl, git       repo + downloads (model, installers)

set -euo pipefail

PACKAGES=(
  stow
  ffmpeg
  wl-clipboard
  xclip
  build-essential
  pkg-config
  libssl-dev
  cmake
  curl
  git
)

missing=()
for pkg in "${PACKAGES[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi
done

if [ "${1:-}" = "--check" ]; then
  if [ ${#missing[@]} -eq 0 ]; then
    echo "setup-packages: all ${#PACKAGES[@]} required packages installed"
  else
    echo "setup-packages: MISSING: ${missing[*]}"
    echo "  fix: scripts/setup-packages.sh"
    exit 1
  fi
  exit 0
fi

if [ ${#missing[@]} -eq 0 ]; then
  echo "setup-packages: nothing to do, all ${#PACKAGES[@]} packages installed"
  exit 0
fi

echo "setup-packages: installing: ${missing[*]}"
sudo apt install -y "${missing[@]}"
