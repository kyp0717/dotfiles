# 2026-11-07 — apply DeepSeek V4.1 Flash to live dsh NVIDIA profile

Commit `d44da5e` replaced retired `deepseek-ai/deepseek-v4-flash-0731`
with `deepseek-ai/deepseek-v4.1-flash` in `dsh/scripts/setup-kimi.mjs`.
The setup script is idempotent and only writes the profile when missing,
so the change does not reach existing machines by itself.

## Per machine

1. Edit `~/.dsh/settings.yaml` (or the profile file it loads) and swap
   the model id in the nvidia profile, or delete the nvidia profile and
   re-run `npm run dsh:setup` from the repo root.
2. Verify: `dsh --profile web --dump-config | grep -i deepseek` shows
   `deepseek-ai/deepseek-v4.1-flash`.

## Notes

- `deepseek-v4-pro-0813` is unchanged: there is no V4.1 Pro; the API
  `deepseek-v4-pro` still serves V4 Pro 0813.
- pi side needs nothing: pi 1.5.0's bundled catalog already lists
  `deepseek/deepseek-flash` (DeepSeek V4.1 Flash, 1M ctx). The pstack
  remap keeps v4-pro deliberately (two-preferred-models decision,
  commit `3b1b1ed`).
- Retire this unit once both machines show the new id.
