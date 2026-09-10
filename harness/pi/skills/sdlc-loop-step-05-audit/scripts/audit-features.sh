#!/usr/bin/env bash
# sdlc-loop step-05 gate: the feature map matches its contract.
#
# Usage: audit-features.sh [features-dir]   (default: resource/features)
#
# The map may be flat or split into type folders (behavior/, surface/).
# Checks, per feature file: an ID line naming the feature, a Type line naming
# Behavior or Surface, the required sections in order, an Anchors section,
# and every anchor "path: needle" greps in its file. Checks the index links
# every feature file, that every sub-feature ID has exactly one home, and
# that every "renders <id>" / "feeds <id>" / "consults <id>" /
# "consumes <id>" link resolves to a defined
# sub-feature ID. Exits non-zero on any failure and names what failed.
set -uo pipefail

dir="${1:-resource/features}"
fail=0
all_ids=""

if [ ! -f "$dir/README.md" ]; then
  echo "FAIL missing index $dir/README.md"
  exit 1
fi

# First pass: per-file structure, anchors, index links; collect sub-feature IDs.
while IFS= read -r f; do
  [ "$(basename "$f")" = "README.md" ] && continue
  rel="${f#$dir/}"

  # Required sections, in order.
  prev=0
  for h in "## Sub-features" "## How to get to it (user POV)" "## Driving it" "## Gotchas" "## Anchors"; do
    line="$(grep -n "^$h" "$f" | head -1 | cut -d: -f1)"
    if [ -z "$line" ]; then
      echo "FAIL $rel: missing section '$h'"
      fail=1
      continue
    fi
    if [ "$line" -le "$prev" ]; then
      echo "FAIL $rel: section '$h' out of order"
      fail=1
    fi
    prev="$line"
  done

  # ID line names the feature.
  if ! grep -qE '^ID: [a-z0-9][a-z0-9-]*$' "$f"; then
    echo "FAIL $rel: missing 'ID: <feature-id>' line"
    fail=1
  fi

  # Type line names Behavior or Surface.
  if ! grep -qE '^Type: (Behavior|Surface)$' "$f"; then
    echo "FAIL $rel: missing 'Type: Behavior' or 'Type: Surface' line"
    fail=1
  fi

  # Sub-feature IDs, collected for the uniqueness and link checks below.
  all_ids="$all_ids
$(awk '/^## Sub-features/{s=1;next} /^## /{s=0} s && /^- `/{ match($0, /`[^`]+`/); print substr($0, RSTART+1, RLENGTH-2) }' "$f")"

  # Anchors: "- <path>: <needle>" bullets under ## Anchors.
  in_anchors=0
  while IFS= read -r l; do
    case "$l" in
      "## Anchors") in_anchors=1; continue ;;
      "## "*) in_anchors=0; continue ;;
    esac
    [ "$in_anchors" = 1 ] || continue
    case "$l" in
      "- "*)
        spec="${l#- }"
        path="${spec%%:*}"
        needle="${spec#*: }"
        if [ ! -f "$path" ]; then
          echo "FAIL $rel: anchor path missing: $path"
          fail=1
        elif ! grep -qF "$needle" "$path"; then
          echo "FAIL $rel: anchor needle not found in $path: $needle"
          fail=1
        fi
        ;;
    esac
  done < "$f"

  # Index links every feature file.
  if ! grep -qF "$rel" "$dir/README.md"; then
    echo "FAIL README.md: no link to $rel"
    fail=1
  fi
done < <(find "$dir" -name '*.md' | sort)

# Every sub-feature ID has exactly one home.
dup="$(printf '%s\n' "$all_ids" | sed '/^$/d' | sort | uniq -d)"
if [ -n "$dup" ]; then
  echo "FAIL sub-feature ID defined in more than one file: $(printf '%s' "$dup" | tr '\n' ' ')"
  fail=1
fi

# Every renders/feeds/consults/consumes link resolves to a defined sub-feature ID.
known="$(printf '%s\n' "$all_ids" | sed '/^$/d' | sort -u)"
while IFS= read -r f; do
  [ "$(basename "$f")" = "README.md" ] && continue
  rel="${f#$dir/}"
  refs="$(grep -oE '(renders|feeds|consults|consumes) `[^`]+`' "$f" | sed -E 's/^(renders|feeds|consults|consumes) `([^`]+)`/\2/' || true)"
  while IFS= read -r r; do
    [ -z "$r" ] && continue
    if ! printf '%s\n' "$known" | grep -qxF "$r"; then
      echo "FAIL $rel: link target not defined anywhere: $r"
      fail=1
    fi
  done <<< "$refs"
done < <(find "$dir" -name '*.md' | sort)

if [ "$fail" = 1 ]; then
  exit 1
fi
echo "feature map audit: PASS"
