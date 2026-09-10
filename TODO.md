# Reminders

## Linden (2026-08-25)

- [ ] Upgrade kimi CLI on linden (`~/.kimi-code/bin/kimi`; woodlawn is on 0.38.0)
- [ ] `git pull` this repo so nushell `env.nu` gets the `$nu.home-dir` fix
      (`$nu.home-path` was removed in nushell 0.114; without the fix, everything
      after line ~110 in env.nu silently stops running — including PATH prepends)
- [ ] After pulling, open a fresh wezterm tab and confirm `kimi --version` works
