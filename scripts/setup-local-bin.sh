#!/bin/bash
# Setup script to ensure ~/.local/bin directory exists and is in PATH

set -e

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
echo "You can now place executables like 'claude' in ~/.local/bin/"