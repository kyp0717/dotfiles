# 2026-10-26 — wezterm window died the second a `git pull` rewrote wezterm.lua

## Symptom

A wezterm window running pi vanished mid-session, immediately after a
`git pull` fast-forward in `~/dotfiles`. No OOM, no coredump, no error
visible to the user — the window just disappeared, taking the pi session
and its scrollback with it.

## Diagnosis

Timeline from `journalctl --user` and `git reflog`, matching to the
second:

1. 09:08:00 — wezterm-gui (pid 11183) launched.
2. 09:08:59 — `git pull: Fast-forward` (7439fdb..d6c8be9) rewrote
   `wezterm/.config/wezterm/wezterm.lua` among ~164 files.
3. 09:08:59 — gnome-shell logged `WL: error in client communication
   (pid 11183)` and wezterm-gui was destroyed. Same second.

wezterm live-reloads its config when the config file changes
(`automatic_config_reload` defaults to true). On Wayland this build
(20240203-110809-5046fc22, ~2 years old) commits a protocol violation
during the reload — gnome-shell had already flagged the same client at
startup: `Buggy client ... committed initial non-empty content without
acknowledging configuration`. mutter tolerates it at startup, then
enforces it at the reload. The `queue ... destroyed while proxies still
attached` flood is just teardown noise after the kill.

## Ruled out

- **OOM** — no oom-kill in kernel log; 850 MB peak is normal.
- **pi crash** — pi or nu exiting closes a *pane*, not wezterm-gui; the
  compositor killed the whole client (pid = wezterm-gui).
- **The skill-file deletions in the same pull** — they broke
  `~/.agents/skills` symlinks (pi-side problem, fixed by
  `stow -R pi`), but nothing in that path can kill wezterm-gui.

## Fix

- `automatically_reload_config = false` in `wezterm.lua` — removes the
  trigger class entirely. Config edits need a manual
  `wezterm.reload_configuration()` (leader key) or window restart.
- Upgrade wezterm: the apt repo in `scripts/wezterm.install.sh` tracks
  current builds; `sudo apt update && sudo apt install wezterm`
  replaces the 2024 build. The old build has many Wayland fixes pending.

## Compounding error same morning

The first fix attempt used `automatic_config_reload` — not a real field.
An invalid config field makes wezterm terminate on startup
(`Configuration Error ... ; terminating` in journalctl), so every
restart crashed again until the field was corrected to
`automatically_reload_config`. Validate a wezterm config edit by
launching `wezterm start` and checking the log for `Configuration
Error` before walking away.

## Lessons

- **A `git pull` in `~/dotfiles` rewrites live config files out from
  under running programs.** wezterm watches its config; pi watches its
  skills. Either can kill the session mid-work. After a pull that
  touches `wezterm/`, `pi/`, or `nvim/`, expect reloads; run pulls in a
  dedicated window you can afford to lose.
- **When a window vanishes, check who died: pane process or the GUI
  client.** `journalctl --user` around the death second plus
  `git reflog` matched to the same second pinned this in one pass.
  gnome-shell's `WL: error in client communication` means the
  *compositor* killed the client — that is a client bug, not a crash of
  whatever ran inside the pane.
- **Stale apt-installed GUI binaries drift silently.** The install
  script adds the repo but nothing upgrades the package; check
  `wezterm --version` age during machine-rotation parity checks.
