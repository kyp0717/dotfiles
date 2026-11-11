# In pi fullscreen, WezTerm's Ctrl+Shift+C/V are bound and still do nothing

**Date:** 2026-11-11 · **Source:** "why is ctrl-shift-v and ctrl-shift-c
not working inside pi running with wezterm" on linden, one week after
the same complaint was already written down for woodlawn in
`domain.20261022.pi-clipboard-needs-wl-clipboard.md`.

## What happened

Ctrl+Shift+C and Ctrl+Shift+V did nothing in a pi session on linden.
`wl-copy`/`wl-paste` were installed, so the earlier lesson's fix was in
place and did not explain it. Two probes settled it:

```
wezterm show-keys | grep -E "SHIFT \| CTRL\s+[CV] "
  SHIFT | CTRL  C  ->  CopyTo(Clipboard)
  SHIFT | CTRL  V  ->  PasteFrom(Clipboard)

wl-paste --no-newline      # empty, exit 0
```

Both bindings exist, so this is not a keymap problem. The clipboard was
empty because the copy never put anything on it.

## Why it happened

`pi/.pi/agent/settings.json` sets no `tuiMode`, so pi runs fullscreen
and turns on mouse reporting (`pi-tui/dist/tui-alt-screen.js:16`, the
`\x1b[?1000h\x1b[?1002h\x1b[?1003h\x1b[?1006h` init string). WezTerm
therefore hands every drag to pi and never builds its own selection.
Ctrl+Shift+C is `CopyTo(Clipboard)` on WezTerm's selection, so it copies
nothing at all, not stale text. pi draws its own selection highlight
(`applySelection`), which makes the drag look successful.

Ctrl+Shift+V was working the whole time. It pasted the empty clipboard.
The two symptoms have one cause, and fixing the copy fixes both. pi's
copy-on-select (`fullscreenCopyOnSelect: true`) writes through
`copyToClipboard` in `dist/utils/clipboard.js`, i.e. `wl-copy` here, and
flashes "Copied!" on success.

## The fix

None, knowledge only. Nothing in the repo changed on 2026-11-11. What
now relies on this record:

- Read a "copy/paste is broken" report as one symptom, not two, and
  check `wl-paste` before touching any config.
- `wezterm show-keys` answers "is it bound" in one command; use it
  before editing `wezterm/.config/wezterm/keys.lua`.
- An empty clipboard is the expected state, not a bug, when the copy
  path never ran.

## Rules that fall out

- Diagnose copy before paste. Verify the clipboard contents
  (`wl-paste --no-newline`), then the binding (`wezterm show-keys`).
- In pi fullscreen, select with pi (it auto-copies, watch for the
  "Copied!" flash) or hold Shift while dragging to give the selection
  back to WezTerm. Plain drag then Ctrl+Shift+C cannot work.
- WezTerm does not bind plain Ctrl+V; `ctrl+v` inside pi is pi's own
  `app.clipboard.pasteImage`, which reads the clipboard with `wl-paste`.
  Bindings visible in `show-keys` for Ctrl+V are the shifted variant.
- When the same question arrives twice, the older lesson was not
  reachable. Cross-reference both files rather than restating only the
  fix.
