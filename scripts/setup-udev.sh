#!/usr/bin/env bash
# setup-udev.sh — install udev rules from this repo into /etc/udev/rules.d.
#
# Currently: 50-yeti-no-autosuspend.rules — keeps the Blue Yeti USB mic out
# of autosuspend so it survives sleep/suspend. Without it the mic wedges on
# resume (enumerated but capture dead; only a physical replug revives it —
# see resource/microphone/yeti-wedge-attempts.md).
#
# Idempotent: skips when the installed rule already matches the repo copy.
# The rule matches by USB vendor/product id, so it is harmless on machines
# where the Yeti is not plugged in.
#
# Usage:
#   scripts/setup-udev.sh          install/update rules (needs sudo)
#   scripts/setup-udev.sh --check  report drift, change nothing

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULES_SRC_DIR="$REPO_ROOT/resource/microphone"
RULES_DST_DIR="/etc/udev/rules.d"

stale=()
for src in "$RULES_SRC_DIR"/*.rules; do
  name="$(basename "$src")"
  dst="$RULES_DST_DIR/$name"
  if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
    stale+=("$name")
  fi
done

if [ "${1:-}" = "--check" ]; then
  if [ ${#stale[@]} -eq 0 ]; then
    echo "setup-udev: all rules installed and current"
  else
    echo "setup-udev: MISSING or STALE: ${stale[*]}"
    echo "  fix: scripts/setup-udev.sh"
    exit 1
  fi
  exit 0
fi

if [ ${#stale[@]} -eq 0 ]; then
  echo "setup-udev: nothing to do, rules already current"
  exit 0
fi

for name in "${stale[@]}"; do
  echo "setup-udev: installing $name"
  sudo cp "$RULES_SRC_DIR/$name" "$RULES_DST_DIR/$name"
done
sudo udevadm control --reload
echo "setup-udev: done (rules apply to newly plugged devices; replug or reboot for existing ones)"
