# 2026-11-28 — gemini/ stow package for Antigravity CLI (agy) status line

## Done on woodlawn

- Added new stow package `gemini/` mirroring `~/.gemini/antigravity-cli/`:
  - `gemini/.gemini/antigravity-cli/statusline.sh` (executable): renders
    `<project> (<git-branch>) | <model> | ctx <pct>%` from the `agy`
    session JSON piped to stdin. Uses `jq` and guards against missing
    `jq`, spaces in paths, and non-git directories.
  - `gemini/.gemini/antigravity-cli/settings.json`: merged woodlawn's
    existing `settings.json` (`allowNonWorkspaceAccess`, `permissions`,
    `trustedWorkspaces`) with the `statusLine` block
    (`"stack_with_default": true`).
- Added `jq` to `scripts/ubuntu.requirements.txt` and wired
  `mkdir -p "$HOME/.gemini/antigravity-cli" && stow --no-folding gemini/`
  into `scripts/bootstrap.sh`.
- Documented `gemini/` in `AGENTS.md` and `resource/README.md`.
- Backed up woodlawn's original `~/.gemini/antigravity-cli/settings.json`
  to `/tmp/agy-settings-woodlawn-backup.json` and deployed with
  `stow --no-folding gemini`.
- Confirmed `agy` rewrites `settings.json` atomically on `/statusline`
  changes (added `"enabled": true` and replaced the symlink with a real
  file). Merged `"enabled": true` into the repo copy, restowed, and
  recorded `resource/lessons/edge.20261128.agy-atomic-settings-breaks-symlink.md`.

## Why `--no-folding`

`~/.gemini/` and `~/.gemini/antigravity-cli/` hold per-machine secrets
and runtime state (`oauth_creds.json`, `mcp_oauth_tokens.json`,
`history.jsonl`, `conversations/`, `brain/`, SQLite DBs). Stowing with
`--no-folding` (and ensuring the directory exists first) guarantees GNU
Stow links only individual tracked files and never symlinks `~/.gemini`
itself into `~/dotfiles`.

## For linden at next rotation

1. `git pull` in `~/dotfiles`.
2. Ensure `jq` is installed (`scripts/ubuntu.install.sh` or
   `command -v jq`).
3. If `~/.gemini/antigravity-cli/settings.json` already exists as a real
   file on linden, diff it against
   `gemini/.gemini/antigravity-cli/settings.json`, salvage any unique
   permissions/trusted workspaces into the repo file, back up and remove
   the real file.
4. Deploy from `~/dotfiles`:
   ```bash
   mkdir -p ~/.gemini/antigravity-cli
   stow --no-folding gemini
   ```
5. Optionally run `/title on` inside `agy` to enable dynamic terminal
   window/tab titles (commit the resulting `settings.json` diff if
   desired).
