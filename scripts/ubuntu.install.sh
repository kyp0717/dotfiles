#!/usr/bin/env bash
# ubuntu.install.sh — install the Ubuntu system packages this setup needs.
#
# The package list lives in ubuntu.requirements.txt (next to this script).
# To add a package, add a line there — do not edit this script.
#
# Idempotent: installed packages are skipped.
#
# Usage:
#   scripts/ubuntu.install.sh          install anything missing (needs sudo)
#   scripts/ubuntu.install.sh --check  report what's missing, change nothing

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$HERE/ubuntu.requirements.txt"

mapfile -t PACKAGES < <(grep -vE '^\s*(#|$)' "$LIST" | sed 's/\s*#.*//' | awk '{print $1}')

missing=()
for pkg in "${PACKAGES[@]}"; do
  dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done

if [ "${1:-}" = "--check" ]; then
  if [ ${#missing[@]} -eq 0 ]; then
    echo "ubuntu.install: all ${#PACKAGES[@]} required packages installed"
  else
    echo "ubuntu.install: MISSING: ${missing[*]}"
    echo "  fix: scripts/ubuntu.install.sh"
    exit 1
  fi
  exit 0
fi

if [ ${#missing[@]} -eq 0 ]; then
  echo "ubuntu.install: nothing to do, all ${#PACKAGES[@]} packages installed"
  exit 0
fi

echo "ubuntu.install: installing: ${missing[*]}"
sudo apt install -y "${missing[@]}"
