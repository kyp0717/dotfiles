#!/bin/bash
# Install Graft (https://github.com/trailhq/Graft) — code-understanding graph
# that makes coding agents faster/cheaper. Distributed as an npm package.
#
# What this script does:
#   1. Installs the graft CLI globally via npm
#   2. Verifies the install
#
# What it deliberately does NOT do:
#   - `graft init` / `graft build` — those are per-repo operations; run
#     `graft init` inside whichever project you want to wire up.
#
# Usage: graft/graft-install.sh
set -euo pipefail

if ! command -v npm >/dev/null 2>&1; then
    echo "ERROR: npm is required to install graft (node is present via nvm on this machine)." >&2
    exit 1
fi

echo "Installing graft CLI (@nanonets/graft)..."
npm install -g @nanonets/graft

echo ""
echo "Installed: $(graft --version 2>/dev/null || echo 'graft (version check failed)')"

cat <<'EOF'

Next steps (per repo you want to wire up):
  cd <your-project>
  graft init --dry-run   # preview what it would touch
  graft init             # build graft/ + wire into your agent (cursor, pi, ...)

Notes:
  - graft/ is a regenerable local cache, auto-added to .gitignore
  - global install lives in your nvm bin dir (already on PATH)
EOF
