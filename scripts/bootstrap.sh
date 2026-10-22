#!/usr/bin/env bash
# bootstrap.sh — make this machine match the repo.
#
# Composes the install.* (software) and config.* (settings) scripts, then
# stows the repo's stow packages and runs the dsh harness setup.
# Every step is idempotent; re-running on a drifted machine repairs it.
#
# HARD RULE: every composed script must support --check and --check must
# never install anything. A neovim.install.sh without --check once ran a
# full install during a check pass; its cleanup trap deleted the repo.
#
# Usage:
#   scripts/bootstrap.sh           full setup
#   scripts/bootstrap.sh --check   parity report only, change nothing

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"

STEPS=(
  path.config.sh
  ubuntu.install.sh
  udev.config.sh
  pi.install.sh
  nerdfonts.install.sh
  neovim.install.sh
  starship.install.sh
  wezterm.install.sh
)

if [ "${1:-}" = "--check" ]; then
  fail=0
  for step in "${STEPS[@]}"; do
    [ -f "$HERE/$step" ] || continue
    grep -q -- '--check' "$HERE/$step" || { echo "bootstrap: $step has no --check mode, skipping (unsafe)"; fail=1; continue; }
    "$HERE/$step" --check || fail=1
  done
  exit "$fail"
fi

for step in "${STEPS[@]}"; do
  [ -f "$HERE/$step" ] && { echo "== $step"; "$HERE/$step"; }
done

echo "== stow"
cd "$REPO"
stow nushell/ shell/ starship/ wezterm/ && echo "  shell tool configs deployed"
stow pi/ && echo "  pi config deployed"

echo "== dsh harness"
npm run dsh:setup && npm run skills:install && echo "  dsh deployed"

echo "bootstrap: done"
