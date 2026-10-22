#!/usr/bin/env bash
# nerdfonts.install.sh — install a Nerd Font via getnf.
# Usage: scripts/nerdfonts.install.sh [--check]
set -euo pipefail

if [ "${1:-}" = "--check" ]; then
  if fc-list 2>/dev/null | grep -qi "nerd"; then
    echo "nerdfonts.install: a Nerd Font is installed"
  else
    echo "nerdfonts.install: MISSING Nerd Font"
    echo "  fix: scripts/nerdfonts.install.sh"
    exit 1
  fi
  exit 0
fi

curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash
# ensure that ~/.local/bin is in your path (path.config.sh)
