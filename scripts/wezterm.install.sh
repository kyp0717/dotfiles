#!/usr/bin/env bash
# wezterm.install.sh — install WezTerm from its apt repo.
# Usage: scripts/wezterm.install.sh [--check]
set -euo pipefail

if [ "${1:-}" = "--check" ]; then
  if command -v wezterm >/dev/null 2>&1; then
    echo "wezterm.install: wezterm present"
  else
    echo "wezterm.install: MISSING wezterm"
    echo "  fix: scripts/wezterm.install.sh"
    exit 1
  fi
  exit 0
fi

curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
sudo apt update
sudo apt install wezterm
