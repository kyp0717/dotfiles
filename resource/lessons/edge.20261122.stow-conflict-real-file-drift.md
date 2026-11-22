# Lesson: a stow conflict means the live file drifted into a real file; back up, merge, restow

Date: 2026-11-22. Machine: woodlawn. Surfaced during the linden ->
woodlawn transfer when `stow -n pi nushell zed nvim` refused zed:
"cannot stow dotfiles/zed/.config/zed/settings.json over existing
target ... since neither a link nor a directory".

## What happened

`~/.config/zed/settings.json` on woodlawn was a regular file, not a
symlink into the repo, and had diverged substantially from the tracked
version: it carried `agent_servers` (pi-acp, kimi registry entries) and
different theme/font preferences, while the repo version (linden's) had
`vim_mode`, `trust_all_worktrees`, and other settings the live file
lacked. Both directions had unique content; a blind `stow --adopt`
would have overwritten the repo's version with the machine's.

## Why it happened

At some point the zed symlink on woodlawn was replaced by (or restored
as) a real file, and edits accumulated locally. Nothing in the normal
flow (git pull, stow) surfaces a real-file target until stow conflicts;
zed kept working, so the drift was invisible. This is the general
failure mode behind the AGENTS.md rule "a file under `~` that is not a
symlink into the repo is either per-machine state or not yet adopted" —
here it was neither, just untracked divergence in a tracked package's
target.

## The fix

Backed up the live file to /tmp, merged the functional woodlawn-only
block (`agent_servers`) into the repo's `zed/.config/zed/settings.json`,
removed the real file, and `stow zed` linked the repo version into
place. Also fixed a pre-existing JSONC trailing comma in the repo file
so standard JSON validation passes. Theme/font preferences follow the
repo (linden's values) per the user's ruling that the dotfiles zed
settings are the source of truth. Woodlawn's old file:
`/tmp/zed-settings-woodlawn-backup.json` (gone after reboot; the unique
content was merged).

## Rules that fall out

- A stow conflict is a signal, not an obstacle: diff the real file
  against the repo version first, salvage machine-unique functional
  blocks into the repo file, back up, then restow.
- Never `stow --adopt` on a diverged tracked target without reading the
  diff; adopt overwrites the repo copy with the machine's.
- Zed settings are JSONC (comments, trailing commas); validate with
  `grep -v '^\s*//' file | python3 -m json.tool`, not plain json.load.
- After restowing a previously-diverged package, run `stow -n` over all
  packages to catch siblings with the same disease.
