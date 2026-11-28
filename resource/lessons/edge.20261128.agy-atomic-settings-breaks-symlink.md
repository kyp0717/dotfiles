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

## The fix

Merged `"enabled": true` into
`gemini/.gemini/antigravity-cli/settings.json`, removed the regular file
at `~/.gemini/antigravity-cli/settings.json`, and re-ran
`stow --no-folding gemini` to restore the symlink. Noted the behavior in
`resource/handoff/20261128-gemini-agy-statusline.md` for `linden`.

## Rules that fall out

- After any interactive `agy` setting change (`/statusline`, `/title`,
  `/config`, trusting a workspace), check
  `ls -la ~/.gemini/antigravity-cli/settings.json` — if it is no longer
  a symlink, diff it against
  `~/dotfiles/gemini/.gemini/antigravity-cli/settings.json`, merge
  intentional changes into the repo file, remove the regular file, and
  run `stow --no-folding gemini`.
- Always deploy `gemini/` with `stow --no-folding gemini` (after
  `mkdir -p ~/.gemini/antigravity-cli`) so GNU Stow never folds
  `~/.gemini/` runtime state or OAuth tokens into the repo.
- Never `stow --adopt gemini` without diffing first; adopt overwrites
  the repo copy with the machine's local file.

See also `edge.20261122.stow-conflict-real-file-drift.md` (same failure
mode with Zed).
