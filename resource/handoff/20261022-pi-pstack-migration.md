# 2026-10-22 — pi-pstack: pinned npm install + setup script

## Final state (woodlawn)

- Canonical pstack = the `pi-pstack` npm package (44 skills + subagent
  extension + poteto agents), **pinned `@0.1.0`, installed per machine**
  by `scripts/setup-pi-pstack.sh` (`pi install npm:pi-pstack@0.1.0`,
  `--check` mode for parity). Wired into `setup-all.sh`.
- `pi/.agents/skills/` = exactly two local skills: `lesson-learned`,
  `graft`. All pstack-family customs (poteto-help, correct,
  benchmark-checklist, three extra principles) deleted — user decision,
  git history has them.
- dsh's `dsh/skills/` untouched (no package mechanism in dsh).

## Design decision (changed twice today; this is the landing point)

First attempt vendored the package into the repo; rejected because
third-party code does not belong in dotfiles — the repo manages config,
not upstream content. Same pattern as pi-voice-stt: npm-installed,
pinned, scripted. The repo's job is the pin + the idempotent installer
so both machines converge.

(The earlier problem that started all this was different: the
lesson-learned skill was the user's own uncommitted file. Own code
lives in git; third-party code comes from its registry, pinned.)

## For linden (after `git pull`)

```bash
cd ~/dotfiles
stow -R pi                      # prunes old skills from ~/.agents/skills
scripts/setup-pi-pstack.sh      # installs npm:pi-pstack@0.1.0 if missing
```

Verify: `ls ~/.agents/skills` → `graft lesson-learned`;
`ls ~/.pi/agent/npm/node_modules/pi-pstack/skills | wc -l` → 44.

## Notes

- First pstack workflow run may need `/setup-pstack` (writes per-machine
  `~/.pi/agent/pstack/models.json`).
- Extension source reviewed: no network, spawns only `pi` child
  processes, writes confined to tmp + `~/.pi/agent/pstack/`.
- Skills resolve flat by name across all discovery locations; keeping
  the repo set free of package names is what prevents collisions.
- Upgrade path: bump `PSTACK_VERSION` in `scripts/setup-pi-pstack.sh`,
  run on both machines, commit.
