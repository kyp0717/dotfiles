#!/usr/bin/env bash
# tla.install.sh — install the pinned TLA+ toolchain for pstack's
# statechart skill: bun (runs the TypeScript pipeline) and mise
# (installs Java temurin-25 + tla2tools on the skill's first run).
#
# Versions are pinned in tla.requirements.txt (next to this script).
# To add or upgrade, edit that file — not this script.
#
# Binaries come from official GitHub release archives into ~/.local/bin
# (no sudo, both machines). Never build from source.
#
# Idempotent: a binary at the pinned version is skipped.
#
# Usage:
#   scripts/tla.install.sh          install anything missing
#   scripts/tla.install.sh --check  report status, change nothing

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$HERE/tla.requirements.txt"
BIN_DIR="$HOME/.local/bin"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1
fail=0

note() { echo "tla.install: $1"; }
miss() { note "MISSING $1"; fail=1; }

# Release archives name the arch differently per project.
case "$(uname -m)" in
  x86_64)  BUN_ARCH=x64;     MISE_ARCH=x64 ;;
  aarch64) BUN_ARCH=aarch64; MISE_ARCH=arm64 ;;
  *) echo "tla.install: unsupported arch $(uname -m)" >&2; exit 1 ;;
esac

installed_version() {  # tool -> version or empty
  local bin="$BIN_DIR/$1"
  [ -x "$bin" ] || return 0
  case "$1" in
    bun)  "$bin" --version 2>/dev/null ;;
    mise) "$bin" --version 2>/dev/null | awk '{print $1}' ;;
  esac
}

install_bun() {  # version
  local v="$1" tmpd
  tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' RETURN
  curl -fsSL -o "$tmpd/bun.zip" \
    "https://github.com/oven-sh/bun/releases/download/bun-v${v}/bun-linux-${BUN_ARCH}.zip"
  unzip -q "$tmpd/bun.zip" -d "$tmpd"
  mkdir -p "$BIN_DIR"
  install -m 0755 "$tmpd/bun-linux-${BUN_ARCH}/bun" "$BIN_DIR/bun"
}

install_mise() {  # version
  local v="$1" tmpd
  tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' RETURN
  curl -fsSL -o "$tmpd/mise.tar.gz" \
    "https://github.com/jdx/mise/releases/download/v${v}/mise-v${v}-linux-${MISE_ARCH}.tar.gz"
  tar -C "$tmpd" -xzf "$tmpd/mise.tar.gz"
  mkdir -p "$BIN_DIR"
  install -m 0755 "$tmpd/mise/bin/mise" "$BIN_DIR/mise"
}

while read -r spec _; do
  case "$spec" in ''|\#*) continue ;; esac
  tool="${spec%@*}"
  want="${spec##*@}"
  have="$(installed_version "$tool")"

  if [ "$have" = "$want" ]; then
    note "$spec installed"
    continue
  fi
  if [ "$CHECK_ONLY" = 1 ]; then
    miss "$spec (have ${have:-none})"
    continue
  fi

  note "installing $spec (have ${have:-none})"
  "install_$tool" "$want"
done < "$LIST"

[ "$CHECK_ONLY" = 1 ] && [ "$fail" = 1 ] && { echo "  fix: scripts/tla.install.sh"; exit 1; }
exit 0
