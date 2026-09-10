#!/bin/bash
# Install the latest Neovim release from the official GitHub tarball
# (no source build, no PPA), then deploy the kickstart.nvim configuration
# from this dotfiles repo (git submodule + GNU Stow).
#
# Usage: scripts/neovim.install.sh
set -euo pipefail

ARCHIVE=nvim-linux-x86_64.tar.gz
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# 1. Install the Neovim binary.
#    Prefer /opt (system-wide); fall back to ~/.local when sudo is
#    unavailable (e.g. no passwordless sudo in this session).
# ---------------------------------------------------------------------------
cd "$(mktemp -d)"
trap 'rm -rf "$PWD"' EXIT

echo "Downloading latest Neovim..."
curl -fLO "https://github.com/neovim/neovim/releases/latest/download/$ARCHIVE"

if sudo -n true 2>/dev/null; then
    echo "Installing to /opt/nvim-linux-x86_64..."
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf "$ARCHIVE"
    sudo ln -sfn /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    NVIM_BIN=/usr/local/bin/nvim
else
    echo "sudo not available — installing to ~/.local/nvim-linux-x86_64 instead."
    rm -rf "$HOME/.local/nvim-linux-x86_64"
    tar -C "$HOME/.local" -xzf "$ARCHIVE"
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$HOME/.local/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
    NVIM_BIN="$HOME/.local/bin/nvim"
    echo "NOTE: ~/.local/bin must be on PATH (scripts/setup-local-bin.sh handles this)."
fi

# ---------------------------------------------------------------------------
# 2. Deploy the kickstart.nvim configuration (submodule + stow).
# ---------------------------------------------------------------------------
echo "Deploying kickstart.nvim configuration..."
cd "$DOTFILES_DIR"

if ! command -v stow >/dev/null 2>&1; then
    echo "ERROR: GNU Stow is required (sudo apt install stow)." >&2
    exit 1
fi

git submodule update --init nvim/.config/nvim
stow -R nvim/

# ---------------------------------------------------------------------------
# 3. First-launch dependencies + plugin bootstrap.
# ---------------------------------------------------------------------------
echo ""
echo "Checking first-launch dependencies..."
for tool in rg tree-sitter cc unzip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "  WARNING: '$tool' not found — install it for full functionality:"
        echo "    sudo apt install -y ripgrep unzip build-essential   # rg, unzip, cc"
        echo "    npm install -g tree-sitter-cli                       # tree-sitter"
    fi
done

echo "Bootstrapping plugins (vim.pack) and treesitter parsers..."
"$NVIM_BIN" --headless "+sleep 90" +qa || true

echo ""
echo "Installed: $("$NVIM_BIN" --version | head -1)"
echo "Config:    $(readlink -f "$HOME/.config/nvim")"
