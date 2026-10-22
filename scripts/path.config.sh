#!/bin/bash
# path.config.sh — ensure ~/.local/bin exists and shell config is deployed.
# Usage: scripts/path.config.sh [--check]

set -e

if [ "${1:-}" = "--check" ]; then
  if [ -d "$HOME/.local/bin" ]; then
    echo "path.config: ~/.local/bin exists"
  else
    echo "path.config: MISSING ~/.local/bin"
    echo "  fix: scripts/path.config.sh"
    exit 1
  fi
  exit 0
fi

echo "Setting up ~/.local/bin directory and PATH configuration..."

# Create ~/.local/bin if it doesn't exist
mkdir -p "$HOME/.local/bin"

# Deploy shell configuration using stow
cd "$(dirname "$0")/.."
stow shell/

echo "Shell configuration deployed!"
echo ""
echo "To apply changes immediately, run one of these commands:"
echo "  source ~/.profile    # For login shells"
echo "  source ~/.bashrc     # For non-login shells"
echo ""
echo "Or log out and log back in for changes to take effect."
echo ""
echo "You can now place user executables in ~/.local/bin/"