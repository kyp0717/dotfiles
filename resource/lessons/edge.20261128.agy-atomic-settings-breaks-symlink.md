# Lesson: agy writes settings.json atomically and breaks the stow symlink

Date: 2026-11-28. Machine: woodlawn. Surfaced immediately after running
`/statusline on` inside `agy` right after deploying `gemini/` with GNU
Stow.

## What happened

`~/.gemini/antigravity-cli/settings.json` was stowed as a symlink into
`~/dotfiles/gemini/.gemini/antigravity-cli/settings.json`. Running
`/statusline on` in the live `agy` TUI added `"enabled": true` to the
`statusLine` block and replaced the symlink with a regular file
(`-rw-------`). The repo copy stayed untouched and `git status` showed
no diff, hiding the live change.

## Why it happened

`agy` persists settings updates via atomic write-and-rename (writing a
temporary file and renaming it onto `~/.gemini/antigravity-cli/settings.json`).
On POSIX filesystems, `rename()` replaces a symlink entry in the parent
directory rather than writing through it. The same happens when
trusting a new workspace, running `/title on`, `/config`, or
`/statusline`.

## How to handle it

After any interactive `agy` setting change you want to keep across
woodlawn and linden:

1. Check `ls -la ~/.gemini/antigravity-cli/settings.json` — if it is no
   longer a symlink, diff it against
   `~/dotfiles/gemini/.gemini/antigravity-cli/settings.json`.
2. Merge intentional changes into the repo file.
3. Remove the real file and re-link:
   ```bash
   rm ~/.gemini/antigravity-cli/settings.json
   cd ~/dotfiles && stow --no-folding gemini
   ```
4. Commit and push.

See also `edge.20261122.stow-conflict-real-file-drift.md` (same failure
mode with Zed).
