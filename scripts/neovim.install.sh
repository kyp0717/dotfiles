#!/bin/bash
# Install the latest Neovim release from the official GitHub releases
# (replaces the old neovim-ppa/unstable apt approach, which lags behind
# and requires sudo apt on Debian/Ubuntu only).
set -euo pipefail

ARCHIVE=nvim-linux-x86_64.tar.gz
INSTALL_DIR=/opt/nvim-linux-x86_64

cd "$(mktemp -d)"
trap 'rm -rf "$PWD"' EXIT

echo "Downloading latest Neovim..."
curl -fLO "https://github.com/neovim/neovim/releases/latest/download/$ARCHIVE"

echo "Installing to $INSTALL_DIR..."
sudo rm -rf "$INSTALL_DIR"
sudo tar -C /opt -xzf "$ARCHIVE"
sudo ln -sfn "$INSTALL_DIR/bin/nvim" /usr/local/bin/nvim

echo "Installed: $(nvim --version | head -1)"
