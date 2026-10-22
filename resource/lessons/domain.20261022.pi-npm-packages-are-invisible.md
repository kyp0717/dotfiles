# pi npm-installed packages live in a hidden per-machine folder, invisible to the repo

**Date:** 2026-10-22 · **Source:** user could not find pi-pstack after
`pi install npm:pi-pstack@0.1.0`; correction that the skill set must be
a visible repo folder.

## What happened

`pi install npm:<pkg>` writes the package to
`~/.pi/agent/npm/node_modules/<pkg>/` and a source string into
`~/.pi/agent/settings.json` (`packages: [...]`). That location is a
hidden dot-directory in `$HOME`, not shown by editors browsing
`~/dotfiles`, not tracked by git, and independent per machine. The user
reasonably concluded the install had not happened.

## Why it happened

pi's npm mechanism optimizes for sharing packages, not for
repo-as-source-of-truth setups. In this repo the rule is the opposite:
anything pi loads should be visible in `~/dotfiles` and deployed by
`stow pi`. Local packages support exactly that: a directory with a
`pi` manifest in `package.json` (skills, extensions, agents) declared
in settings.json by path. pi normalizes the declaration relative to the
settings file, so `../../dotfiles/pi/.pi/pi-pstack` resolves
identically on both machines.

## The fix

pi-pstack is vendored at `pi/.pi/pi-pstack/`, stowed to
`~/.pi/pi-pstack`, declared as a local package. The npm copy was
removed. Handoff: `resource/handoff/20261022-pi-pstack-migration.md`.

## Rules that fall out

- Skill sets this repo owns are vendored directories, not npm installs.
  npm installs are acceptable only for leaf tools pi manages itself
  (pi-voice-stt), never for content the user edits or inspects.
- pi's convention for isolating a related skill set is a package
  (folder with `skills/`, `extensions/`, `agents/` + manifest). Plain
  skills directories have no namespacing: names are flat,
  first-discovered wins, collisions only warn.
- To upgrade a vendored package: `npm pack pi-pstack@<ver>`, unpack
  over `pi/.pi/pi-pstack/`, commit. Version history lives in git log.
