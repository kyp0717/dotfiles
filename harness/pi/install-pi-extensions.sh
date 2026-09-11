#!/usr/bin/env bash
# Install the pi extensions globally.
# Extensions land in ~/.pi/agent/extensions/ (auto-loaded by pi).
# Idempotent: safe to re-run after pulling dotfiles updates.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.pi/agent/extensions
cp "$here/extensions/unslop.ts" ~/.pi/agent/extensions/

echo "installed: ~/.pi/agent/extensions/unslop.ts"
echo "extension loads on next pi start"
