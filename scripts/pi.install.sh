#!/usr/bin/env bash
# pi.install.sh — install the pi harness and its required packages.
#
# Everything is pinned in pi.requirements.txt (next to this script):
#   npm:@earendil-works/pi-coding-agent@X  -> installed with npm -g
#   npm:<anything-else>@X                  -> installed with pi install
#   git:<host>/<org>/<repo>@<ref>          -> installed with pi install
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
GIT_DIR="$HOME/.pi/agent/git"
HARNESS="@earendil-works/pi-coding-agent"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1
fail=0

note() { echo "pi.install: $1"; }
miss() { note "MISSING $1"; fail=1; }

while read -r spec _; do
  case "$spec" in ''|\#*) continue ;; esac
  name="${spec#npm:}"; name="${name%@*}"     # npm:pi-voice-stt@0.8.0 -> pi-voice-stt
  want="${spec##*@}"                          # ... -> 0.8.0

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
    case "$spec" in
      git:*)
        repo="${spec#git:}"; repo="${repo%@*}"   # git:host/org/repo@ref -> host/org/repo
        have_dir="$GIT_DIR/$repo" ;;
      *)
        have_dir="$NPM_DIR/$name" ;;
    esac
    if [ -d "$have_dir" ] && grep -qF "\"$spec\"" "$SETTINGS" 2>/dev/null; then
      note "$spec installed"
    elif [ "$CHECK_ONLY" = 1 ]; then
      miss "$spec"
    else
      pi install "$spec"
    fi
  fi
done < "$LIST"

# pstack switched from the abandoned pi-pstack npm port to the
# pstack-claude git package on 2026-11-06. A leftover pi-pstack install
# shadows the shared skill names, so it must be removed, not just unused.
if [ -d "$NPM_DIR/pi-pstack" ]; then
  if [ "$CHECK_ONLY" = 1 ]; then
    miss "pi-pstack still installed (run: pi remove npm:pi-pstack@0.1.0)"
  else
    note "removing superseded pi-pstack npm package"
    pi remove npm:pi-pstack@0.1.0
  fi
fi

# pi-session-move registers /move; our repo-local move-session-alias.ts
# extension (stowed to ~/.pi/agent/extensions/ by `stow pi`) also answers
# to /move-session. The package alone is not the full install.
alias_ext="$HOME/.pi/agent/extensions/move-session-alias.ts"
if [ ! -e "$alias_ext" ]; then
  if [ "$CHECK_ONLY" = 1 ]; then
    miss "move-session-alias.ts (run: stow pi from the repo root)"
  else
    note "WARNING: move-session-alias.ts missing; run 'stow pi' from the repo root"
  fi
fi

[ "$CHECK_ONLY" = 1 ] && [ "$fail" = 1 ] && { echo "  fix: scripts/pi.install.sh"; exit 1; }
exit 0
