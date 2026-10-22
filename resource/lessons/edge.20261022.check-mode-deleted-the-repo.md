# A --check pass deleted the entire repo: never trap rm -rf on $PWD

**Date:** 2026-10-22 · **Source:** first run of `bootstrap.sh --check`;
`/home/phage/dotfiles` was deleted mid-session. Recovered by re-clone
(everything was pushed through `7aa26b7`).

## What happened

`bootstrap.sh --check` ran each composed script with `--check`.
`neovim.install.sh` had no `--check` mode, so it ran a **full install**:
download, extract, stow, plugin bootstrap. Worse, the script contained:

```bash
cd "$(mktemp -d)"
trap 'rm -rf "$PWD"' EXIT
...
cd "$DOTFILES_DIR"     # section 2 returns to the repo
```

The trap removes `$PWD` **at exit**, and at exit `$PWD` is the repo.
The entire dotfiles checkout was deleted, silently, by a cleanup trap
that had been a loaded gun since the script was written.

## Why it happened

Two independent defects compounded:

1. `trap 'rm -rf "$PWD"'` evaluates `$PWD` when the trap fires, not when
   it is set. Any later `cd` retargets the deletion.
2. `--check` had no enforcement: bootstrap assumed every step honored
   it; one that didn't turned a read-only parity report into a mutation.

## The fix

- `neovim.install.sh`: temp dir captured in a variable
  (`TMPD="$(mktemp -d)"; trap 'rm -rf "$TMPD"' EXIT`), plus a real
  `--check` mode. Comment in the script records the incident.
- `bootstrap.sh --check` now refuses to run any step whose script does
  not declare `--check` support — a structural guard, not a convention.

## Rules that fall out

- Never `trap` on `$PWD` or any mutable variable for deletion. Capture
  the target in a variable at trap-set time.
- `--check` means zero mutation, enforced. A check that can install is
  an install.
- Anything that can `rm -rf` gets reviewed for its retargeting paths:
  what does the variable hold at every possible exit point?
- Push early, push often: the repo survived because every commit was on
  GitHub. Uncommitted work (the restructure in flight) had to be
  recreated from the transcript.
