#!/usr/bin/env bash
# Install the sdlc-loop skills and extension for pi, globally.
# Skills land in ~/.agents/skills/ (pi discovers them in every project).
# The extension lands in ~/.pi/agent/extensions/ (auto-loaded by pi).
# Idempotent: safe to re-run after pulling ai-harness updates.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.agents/skills ~/.pi/agent/extensions
cp -r "$here"/skills/sdlc-loop ~/.agents/skills/
cp -r "$here"/skills/sdlc-loop-step-* ~/.agents/skills/
cp "$here/extensions/sdlc-loop.ts" ~/.pi/agent/extensions/
cp "$here/extensions/unslop.ts" ~/.pi/agent/extensions/

echo "installed: ~/.agents/skills/sdlc-loop* and ~/.pi/agent/extensions/{sdlc-loop,unslop}.ts"
echo "skills are discovered by pi on next session start; extension on next pi start"
