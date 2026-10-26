# 2026-10-26 — Linden H100i fan control (per-machine state) + wezterm crash fix

## Done on linden

- Diagnosed "loud fan on reboot, quiet on cold boot": Corsair H100i
  radiator fans, coolant-temp controlled over USB, invisible to
  lm-sensors. See
  `resource/lessons/domain.20261026.h100i-aio-fans-invisible-to-lm-sensors.md`.
- Installed `liquidctl` (apt), set quiet curve (20% below 30C coolant,
  100% at 45C), enabled `/etc/systemd/system/liquidctl.service`.
- `/etc/modules-load.d/nct6775.conf` for chassis fan telemetry.
- wezterm: `automatically_reload_config = false` committed (config
  auto-reload crashed wezterm-gui on Wayland when git pull rewrote
  wezterm.lua). Lesson: `resource/lessons/edge.20261026.wezterm-config-reload-kills-window.md`.
  Optional follow-up: `sudo apt update && sudo apt install wezterm` to
  get a build with the reload fixes (installed build is 2024-02).

## For woodlawn

- Apply the H100i recreate steps from the lesson (liquidctl install +
  udev reload + liquidctl.service + nct6775.conf).
- Consider porting liquidctl setup into a `scripts/*.config.sh` with
  `--check` so bootstrap.sh covers both machines.
- wezterm fix arrives via `git pull` + new windows; consider the
  wezterm upgrade there too.
