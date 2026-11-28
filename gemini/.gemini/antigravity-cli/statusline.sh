#!/usr/bin/env bash
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
dir=$(printf '%s' "$input" | jq -r '.workspace.project_dir // .cwd // ""')
project=${dir:+$(basename -- "$dir")}
branch=""
if [ -n "$dir" ] && [ -d "$dir" ]; then
  branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi
model=$(printf '%s' "$input" | jq -r '.model.display_name // ""')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty | if . != "" then (round | tostring) + "%" else "" end')

printf '\033[1;36m%s\033[0m' "$project"
[ -n "$branch" ] && printf ' \033[33m(%s)\033[0m' "$branch"
[ -n "$model" ] && printf ' | %s' "$model"
[ -n "$ctx" ] && printf ' | ctx %s' "$ctx"
printf '\n'
