# 2026-11-06 — pstack source switch: pi-pstack (npm) -> pstack-claude (git)

## Why

- `pi-pstack` npm port is abandoned: single 0.1.0 publish 2026-08-08,
  repo untouched since. Upstream `cursor/plugins` moved to pstack
  0.15.36 (58 skills, reworked interrogate).
- Lauren Tan (2026-11-03, X): adversarial reviews "mostly a waste of
  tokens"; interrogate now requires findings proven by a run, and
  poteto-mode no longer gates every PR on it. Not removed, deprioritized.
- Replacement: `github.com/michael-denyer/pstack-claude`, actively
  maintained (v0.9.132, same-day commits), ships a real pi extension
  (`plugins/pstack/pi/index.ts`: subagent, ask, wakeup tools) with a
  tested pi-equivalence matrix (`docs/pi-equivalence.md`).

## Done on woodlawn

- `pi install git:github.com/michael-denyer/pstack-claude@v0.9.132`
  (lands in `~/.pi/agent/git/github.com/michael-denyer/pstack-claude`).
- `pi remove npm:pi-pstack@0.1.0` (67 new skills vs 44 old; overlapping
  names would collide, so removal is required, not optional).
- `scripts/pi.requirements.txt`: git spec replaces the npm pin.
- `scripts/pi.install.sh`: handles `git:` specs and auto-removes a
  leftover pi-pstack install. `--check` passes on woodlawn.
- `AGENTS.md`, `resource/machine-rotation/README.md`,
  `scripts/node.requirements.txt` updated.

## Next machine (linden)

1. `git pull` in `~/dotfiles`.
2. `scripts/pi.install.sh` — installs the git package and removes
   pi-pstack if present.
3. `scripts/pi.install.sh --check` must pass with no MISSING lines.
4. Restart pi (or `/reload`) so the new skill catalog and extension load.

## Per-machine state to re-establish

- `models.json` for pstack roles now lives inside the plugin checkout
  (`~/.pi/agent/git/github.com/michael-denyer/pstack-claude/models.json`,
  written by `/setup-pstack`). The old `~/.pi/agent/pstack/models.json`
  from pi-pstack is orphaned; delete it.
- First interrogate/arena run may need `/setup-pstack` per machine.

## Verify

- `ls ~/.pi/agent/git/github.com/michael-denyer/pstack-claude/plugins/pstack/skills | wc -l` -> 67
- `ls ~/.pi/agent/npm/node_modules | grep pi-pstack` -> nothing
- In pi: `/skill:interrogate` exists; its SKILL.md says findings
  survive only when proven by a run.
