#!/usr/bin/env bash
# starship.install.sh — install the starship prompt.
# Usage: scripts/starship.install.sh [--check]
set -euo pipefail

if [ "${1:-}" = "--check" ]; then
  if command -v starship >/dev/null 2>&1; then
    echo "starship.install: starship present"
  else
    echo "starship.install: MISSING starship"
    echo "  fix: scripts/starship.install.sh"
    exit 1
  fi
  exit 0
fi

curl -sS https://starship.rs/install.sh | sh
