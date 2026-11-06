# pstack on pi dies with "No API key found for anthropic" without a `pi models:` remap

**Date:** 2026-11-06 · **Source:** user ran a pstack agent in another
project; every subagent failed with `No API key found for anthropic`.

## What happened

pstack skills name models by Claude aliases (`opus`, `fable`, `sonnet`,
`haiku`). The pstack-claude pi extension resolves an alias through the
provider column of the session's current model, and falls back to the
`anthropic` column for any provider it has no column for. This setup
runs `kimi-coding` and `deepseek` only, so every alias became an
`anthropic/*` ID and each child pi exited `No API key found for
anthropic`. The extension documents this exact failure in
`plugins/pstack/skills/poteto-mode/references/pi-tools.md` (Model
names).

## Fix

Write the pi override sheet `pstack-models.md` in the pi agent
directory with a remap line, tracked in the repo at
`pi/.pi/agent/pstack-models.md` and deployed by `stow pi`:

```
pi models: opus=kimi-coding/k3.1-pro, fable=deepseek/deepseek-v4-pro, sonnet=kimi-coding/k3, haiku=deepseek/deepseek-flash
```

Keep the role rows on the aliases; the remap line does the
provider-specific work. Proven live: an `agent` call with `model opus`
then runs on `kimi-coding/k3.1-pro`.

## Consequences to remember

- Panel diversity drops to two families (kimi, deepseek). Treat
  cross-model agreement in arena/architect/interrogate verdicts as a
  weaker signal than the four-family design assumes.
- `pi --list-models` is the source of truth for valid remap targets;
  never write an unlisted slug.
- The sheet is global per machine (`~/.pi/agent/`), so it applies to
  every project; no per-project setup is needed.
- Adding anthropic credentials later does not break the remap; delete
  the `pi models:` line to return to provider-column resolution.
