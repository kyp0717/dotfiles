#!/usr/bin/env bash
# pi.install.sh — install the pi harness and its required packages.
#
# Everything is pinned in pi.requirements.txt (next to this script):
#   npm:@earendil-works/pi-coding-agent@X  -> installed with npm -g
#   npm:<anything-else>@X                  -> installed with pi install
# To add or upgrade, edit that file — not this script.
#
# Idempotent: present pieces are skipped. The harness version is read
# from the global node_modules package.json, so an nvm node upgrade
# (which hides the binary) is detected and repaired.
#
# Usage:
#   scripts/pi.install.sh          install anything missing
#   scripts/pi.install.sh --check  report status, change nothing

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$HERE/pi.requirements.txt"
SETTINGS="$HOME/.pi/agent/settings.json"
NPM_DIR="$HOME/.pi/agent/npm/node_modules"
HARNESS="@earendil-works/pi-coding-agent"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1
fail=0

note() { echo "pi.install: $1"; }
miss() { note "MISSING $1"; fail=1; }

while read -r spec _; do
  case "$spec" in ''|\#*) continue ;; esac
  name="${spec#npm:}"; name="${name%@*}"     # npm:pi-pstack@0.1.0 -> pi-pstack
  want="${spec##*@}"                          # ... -> 0.1.0

  if [ "$name" = "$HARNESS" ]; then
    have=""
    pkg_json="$(npm root -g 2>/dev/null)/$HARNESS/package.json"
    [ -f "$pkg_json" ] && have="$(python3 -c "import json;print(json.load(open('$pkg_json'))['version'])" 2>/dev/null || true)"
    if [ "$have" = "$want" ]; then
      note "harness $want installed"
    elif [ "$CHECK_ONLY" = 1 ]; then
      miss "harness (want $want, have ${have:-none})"
    else
      note "installing harness $want (have ${have:-none})"
      npm install -g --ignore-scripts "$HARNESS@$want"
    fi
  else
    if [ -d "$NPM_DIR/$name" ] && grep -qF "\"$spec\"" "$SETTINGS" 2>/dev/null; then
      note "$spec installed"
    elif [ "$CHECK_ONLY" = 1 ]; then
      miss "$spec"
    else
      pi install "$spec"
    fi
  fi
done < "$LIST"

[ "$CHECK_ONLY" = 1 ] && [ "$fail" = 1 ] && { echo "  fix: scripts/pi.install.sh"; exit 1; }
exit 0
