# 2026-10-22 — Switched pi to the pi-pstack npm package

## What changed (woodlawn)

- pi's canonical pstack now comes from the `pi-pstack` npm package
  (44 skills + subagent extension + poteto agents), pinned `@0.1.0`,
  installed per machine via `npm run pi:pstack:install`
  (`pi install npm:pi-pstack@0.1.0`).
- The 44 vendored Cursor-port skills were deleted from
  `pi/.agents/skills/`. Eight locally grown skills remain and are still
  stowed: `lesson-learned`, `graft`, `poteto-help`, `correct`,
  `benchmark-checklist`, `principle-attack-the-premise`,
  `principle-explain-the-number`, `principle-test-behavior-not-implementation`.
- Reason: the vendored set was the Cursor port — its workflow skills
  referenced `~/.cursor/rules/pstack-models.mdc` and Cursor's Task
  tool, which do not exist in pi. The package is the pi-native port
  (pi `subagent` tool, `~/.pi/agent/pstack/models.json`).
- dsh's `dsh/skills/` is untouched (dsh has no package mechanism).

## For linden (after `git pull`)

```bash
cd ~/dotfiles
stow pi                      # removes the 44 old skills from ~/.agents/skills
npm run pi:pstack:install    # installs pi-pstack@0.1.0
```

Verify: `ls ~/.agents/skills | wc -l` → 8, and
`ls ~/.pi/agent/npm/node_modules/pi-pstack/skills | wc -l` → 44.

## Notes

- First run of a pstack workflow may need `/setup-pstack` (writes
  `~/.pi/agent/pstack/models.json`, per machine).
- Extension source was reviewed before install: no network calls,
  spawns only `pi` child processes, writes confined to tmp +
  `~/.pi/agent/pstack/`.
- Package installs are per-machine state (`~/.pi/agent/settings.json`
  declaration); parity is kept by the pinned npm script, run on both.
