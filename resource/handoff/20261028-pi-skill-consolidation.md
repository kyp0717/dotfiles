# 2026-10-28 — pi local skills consolidated under the agent directory

## Final state (linden)

- `graft`, `lesson-learned`, and `project-setup` moved from
  `pi/.agents/skills/` to `pi/.pi/agent/skills/`.
- All local pi skills now use pi's built-in global skill location,
  `~/.pi/agent/skills/`. `brave-search` was already there.
- `pi/.agents/` is gone. `stow -R pi` removed the old `~/.agents` symlink
  and linked the moved skills into `~/.pi/agent/skills/`.
- The npm-installed pstack skills and dsh's independent skill set are
  unchanged.
- `AGENTS.md` and the active layout and rotation docs use the new path.
  `.agents` references in older handoffs are historical; this unit
  supersedes them.

## For woodlawn (after `git pull`)

```bash
cd ~/dotfiles
stow -R pi
ls ~/.pi/agent/skills/
```

The old stowed `~/.agents` symlink should be gone. Restart pi or run
`/reload` to refresh the skill catalog.
