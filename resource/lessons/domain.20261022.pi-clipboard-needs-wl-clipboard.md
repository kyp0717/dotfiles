# pi fullscreen owns the mouse and the clipboard; on Wayland it needs wl-clipboard

**Date:** 2026-10-22 · **Source:** "why can't I copy and paste in a pi
session" on woodlawn; `dist/utils/clipboard.js` throws `Clipboard
unavailable: install wl-clipboard (wl-copy)`.

## What happened

Copy and paste did nothing inside a pi session on woodlawn. WezTerm's
own selection never engaged because pi runs fullscreen by default
(`tuiMode: "fullscreen"`) and captures the mouse. Pi's own copy paths
(drag-select auto-copy via `fullscreenCopyOnSelect: true`, `ctrl+c`,
`ctrl+x`, `ctrl+v` paste) shell out to `wl-copy`/`wl-paste` on Wayland
and `xclip`/`xsel` on X11. None were installed on woodlawn.

## Why it happened

`wl-clipboard` was listed in `scripts/util.sh`, but `setup-all.sh`
never called `util.sh`, so a fresh machine setup never installed it.
An install script nobody runs is the same as no script.

## The fix

`scripts/setup-packages.sh` now owns the required apt package list
(including `wl-clipboard` and `xclip`) and is wired into
`setup-all.sh`; `--check` gives a sudo-free parity probe.
`scripts/setup-udev.sh` does the same for udev rules. Both are in the
machine-rotation fresh-machine recipe.

## Rules that fall out

- In pi fullscreen, mouse copy goes through pi, not the terminal.
  Shift+drag bypasses pi's mouse capture for native terminal selection.
- Wayland sessions need `wl-clipboard`; X11 needs `xclip` or `xsel`.
  Over SSH pi falls back to OSC 52.
- Required dependencies belong in scripts on the setup path
  (`setup-all.sh`), with a `--check` mode for drift detection.
