#!/usr/bin/env bash
# node.install.sh — install pinned global npm tools from node.requirements.txt.
#
# Plain npm globals only (playwright, ...). Pi packages are NOT here;
# they live in pi.requirements.txt and install via `pi install`.
#
# Playwright needs two extra layers beyond the npm package:
#   browsers:     <tool> install chromium          (no sudo, idempotent)
#   system deps:  <tool> install-deps chromium     (sudo apt; needed once)
#
# Usage:
#   scripts/node.install.sh          install anything missing
#   scripts/node.install.sh --check  report status, change nothing

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$HERE/node.requirements.txt"
BROWSERS="$HOME/.cache/ms-playwright"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1
fail=0

note() { echo "node.install: $1"; }
miss() { note "MISSING $1"; fail=1; }

global_version() {  # name -> installed global version or empty
  local pkg_json
  pkg_json="$(npm root -g 2>/dev/null)/$1/package.json"
  [ -f "$pkg_json" ] && python3 -c "import json;print(json.load(open('$pkg_json'))['version'])" 2>/dev/null || true
}

while read -r spec _; do
  case "$spec" in ''|\#*) continue ;; esac
  name="${spec%@*}"; want="${spec##*@}"
  have="$(global_version "$name")"
  if [ "$have" = "$want" ]; then
    note "$spec installed"
  elif [ "$CHECK_ONLY" = 1 ]; then
    miss "$spec (have ${have:-none})"
  else
    note "installing $spec (have ${have:-none})"
    npm install -g "$spec"
  fi
done < "$LIST"

# Playwright browser binaries (idempotent; skips what exists).
if command -v playwright >/dev/null 2>&1 || [ -n "$(global_version playwright)" ]; then
  if ls "$BROWSERS"/chromium-* >/dev/null 2>&1; then
    note "playwright chromium browser present"
  elif [ "$CHECK_ONLY" = 1 ]; then
    miss "playwright chromium browser (run: playwright install chromium)"
  else
    playwright install chromium
    note "system deps need sudo once: playwright install-deps chromium"
  fi
fi

[ "$CHECK_ONLY" = 1 ] && [ "$fail" = 1 ] && { echo "  fix: scripts/node.install.sh"; exit 1; }
exit 0
