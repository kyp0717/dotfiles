#!/usr/bin/env bash
# setup-pi-pstack.sh — ensure the pi-pstack package is installed for pi.
#
# pi-pstack is a third-party npm package (44 pstack skills + subagent
# extension + poteto agents). Like pi-voice-stt it is per-machine state
# installed by pi itself; the repo only pins the version here.
#
# Idempotent: skips when the pinned version is already installed.
#
# Usage:
#   scripts/setup-pi-pstack.sh          install if missing
#   scripts/setup-pi-pstack.sh --check  report status, change nothing
#
# Upgrade: bump PSTACK_VERSION and run on both machines.

set -euo pipefail

PSTACK_VERSION="0.1.0"
SPEC="npm:pi-pstack@${PSTACK_VERSION}"
SETTINGS="$HOME/.pi/agent/settings.json"
PKG_DIR="$HOME/.pi/agent/npm/node_modules/pi-pstack"

installed() {
  [ -d "$PKG_DIR/skills" ] && \
  grep -q "\"${SPEC}\"" "$SETTINGS" 2>/dev/null
}

if [ "${1:-}" = "--check" ]; then
  if installed; then
    echo "setup-pi-pstack: ${SPEC} installed"
  else
    echo "setup-pi-pstack: MISSING ${SPEC}"
    echo "  fix: scripts/setup-pi-pstack.sh"
    exit 1
  fi
  exit 0
fi

if installed; then
  echo "setup-pi-pstack: nothing to do, ${SPEC} already installed"
  exit 0
fi

pi install "$SPEC"
installed && echo "setup-pi-pstack: installed ${SPEC}"
