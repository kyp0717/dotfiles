# 2026-11-06 — pstack model remap for pi (kimi/deepseek, no anthropic)

## Why

First real pstack run in another project failed: every subagent exited
`No API key found for anthropic`. pstack skills name Claude aliases,
and without anthropic credentials the extension's alias resolution
falls to `anthropic/*` IDs. Full diagnosis in
`resource/lessons/edge.20261106.pstack-pi-model-remap.md`.

## Done on woodlawn

- New repo file `pi/.pi/agent/pstack-models.md`: the pi override sheet
  with `pi models:` remapping opus/fable/sonnet/haiku onto
  kimi-coding/k3.1-pro, deepseek/deepseek-v4-pro, kimi-coding/k3,
  deepseek/deepseek-flash, plus the default role rows and
  `session hook: on`.
- `stow -R pi` deployed it to `~/.pi/agent/pstack-models.md`.
- Proven live: a subagent dispatched with `model opus` ran as
  `kimi-coding/k3.1-pro`. No restart needed for new sessions; the
  extension reads the sheet at session start.

## Next machine (linden)

1. `git pull` in `~/dotfiles`.
2. `stow -R pi` (links pstack-models.md).
3. Confirm: `ls -la ~/.pi/agent/pstack-models.md` is a symlink into
   the repo, and `pi --list-models` still lists the four remap targets
   (provider config is per-machine).

## Notes

- The sheet is global; every project gets it. No per-project wiring.
- Panels (arena, architect, interrogate) run two families, not four;
  verdicts should note reduced diversity.
- To change role models later: edit the repo file, `stow -R pi`, or
  run `/skill:setup-pstack` in pi (it rewrites the same file — commit
  intentional diffs like settings.json).
