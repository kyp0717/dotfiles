# 2026-10-22 — pi-pstack: vendored local package, customs removed

## Final state (woodlawn)

- Canonical pstack = the `pi-pstack` package (44 skills + subagent
  extension + poteto agents), **vendored in the repo** at
  `pi/.pi/pi-pstack/` (content of npm `pi-pstack@0.1.0`).
- Deployed by `stow pi` → `~/.pi/pi-pstack` symlink. Declared as a
  local package in `~/.pi/agent/settings.json`:
  `packages: [..., "../../dotfiles/pi/.pi/pi-pstack"]` (pi normalized
  the path relative to the settings file; works on both machines).
  Tracked reference: `resource/pi-agent-settings.json`.
- The npm install was removed (`pi remove npm:pi-pstack@0.1.0`);
  `~/.pi/agent/npm/` now holds only pi-voice-stt.
- `pi/.agents/skills/` = exactly two local skills: `lesson-learned`,
  `graft`. All pstack-family customs (poteto-help, correct,
  benchmark-checklist, three extra principles) deleted — user decision,
  git history has them.
- dsh's `dsh/skills/` untouched (no package mechanism in dsh).

## Why vendored instead of npm-installed

npm package installs land in `~/.pi/agent/npm/` — a hidden dot-folder,
invisible in the editor, outside git, per-machine. Vendoring keeps the
skill set visible, versioned in git, and identical on both machines
after `git pull && stow pi`. Upgrades = re-vendor from
`npm pack pi-pstack@<new>` + one commit.

## For linden (after `git pull`)

```bash
cd ~/dotfiles
stow -R pi    # links ~/.pi/pi-pstack, prunes old skills from ~/.agents/skills
# settings.json must declare the local package — check:
python3 -c "import json; print(json.load(open('$HOME/.pi/agent/settings.json'))['packages'])"
# if '../../dotfiles/pi/.pi/pi-pstack' is missing, add it (or re-copy
# resource/pi-agent-settings.json, which also carries pi-voice-stt etc.)
# and remove the npm one if present:
pi remove npm:pi-pstack@0.1.0 2>/dev/null || true
```

Verify: `ls ~/.agents/skills` → `graft lesson-learned`;
`ls ~/.pi/pi-pstack/skills | wc -l` → 44.

## Notes

- First pstack workflow run may need `/setup-pstack` (writes per-machine
  `~/.pi/agent/pstack/models.json`).
- Extension source reviewed: no network, spawns only `pi` child
  processes, writes confined to tmp + `~/.pi/agent/pstack/`.
- Skills resolve flat by name across all discovery locations; keeping
  the repo set free of package names is what prevents collisions.
