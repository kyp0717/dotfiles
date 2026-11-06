# 2026-11-06 — pstack panels capped at two runners

## Done on woodlawn

- `pi/.pi/agent/pstack-models.md` now maps every Claude alias to either
  `kimi-coding/k3.1-pro` or `deepseek/deepseek-v4-pro`.
- `arena runners`, `architect runners`, and `interrogate reviewers` each
  have exactly two entries, `opus, fable`.
- `arena cross-judge pool` prefers `fable` then `opus`, selecting a judge
  from a family other than the parent when available.
- Deployed with `stow -R pi`.

## Scope

This is a panel-size setting, not a global process limit. Arena may run one
cross-judge after its two runners. Swarm still uses the worker count requested
by the user or the calling workflow.

## Next machine

1. Run `git pull` in `~/dotfiles`.
2. Run `stow -R pi`.
3. Confirm that `~/.pi/agent/pstack-models.md` is a symlink into the repo.
4. Start a new pi session so the extension loads the updated sheet.
