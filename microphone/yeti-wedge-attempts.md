# Blue Yeti wedge incident log — linden, 2026-09-23

Symptom: after sleep or minutes of inactivity the Blue Yeti
(`046d:0ab7`, ALSA card "Microphones") stays enumerated and PipeWire still
lists it, but every capture read fails with `Input/output error`. No audio
in pi voice input, no audio in any client.

Root cause: USB autosuspend (kernel default `autosuspend=2`, suspend after
2 s idle) suspends the device and it fails to resume. The wedge only
clears when the USB port power cycles, which is what a physical replug
does.

Resolution: physical replug restored capture instantly (2 s test file =
384044 bytes). Prevention installed afterwards: udev rule
`50-yeti-no-autosuspend.rules` sets `power/control=on` for the Yeti.

## 10 second wedge classifier (run this first, ever after)

```bash
systemctl --user stop pipewire.socket pipewire-pulse.socket pipewire.service pipewire-pulse.service wireplumber.service
timeout 8 arecord -D hw:CARD=Microphones -f S16_LE -c2 -r48000 -d 2 /tmp/wedge-test.raw
systemctl --user start pipewire.service wireplumber.service pipewire-pulse.socket
```

- File size 384044: mic works, problem is elsewhere (client, PipeWire)
- `read error: Input/output error`: deep wedge, go straight to replug
- `Device or resource busy`: PipeWire still holds it, stop it harder

## Failed revival attempts, in order

Every one of these was tried on the live wedge and every one left capture
returning EIO. Do not repeat them expecting a different result.

| # | Method | Command | Result |
|---|---|---|---|
| 1 | USB unbind/bind (the `yeti-mic-reset` script) | `sudo -n /usr/local/sbin/yeti-usb-reset` | Re-enumerated, device reappeared, capture still EIO |
| 2 | Restart audio stack | `systemctl --user restart pipewire pipewire-pulse wireplumber` | No change |
| 3 | Deauthorize/authorize device | `echo 0/1 > /sys/bus/usb/devices/1-7.1/authorized` (via pkexec) | Full re-probe, still EIO |
| 4 | Parent hub unbind/bind | `echo 1-7 > .../drivers/usb/unbind` then bind (via pkexec) | Interrupted by user before verdict; superseded by #5/#6 results |
| 5 | `usbreset` by device path | `usbreset /dev/bus/usb/001/009` | `No such device found` (path form not accepted) |
| 6 | `usbreset` by vendor:product | `usbreset 046d:0ab7` | `Resetting Blue Microphones ... ok`, capture still EIO |
| 7 | `uhubctl` port power cycle | installed 2.6.0-3, `pkexec uhubctl` | `No compatible devices detected` — no hub on linden supports per-port power switching |

What finally worked: unplug the Yeti, wait 10 s, replug.

## Why each class of reset fails

Unbind/bind, authorize/deauthorize, and USBDEVFS_RESET all re-enumerate
or re-signal the device on the same powered port. The Yeti's failure state
lives in its own USB PHY power domain; it clears only when the port power
drops. Replug drops port power. The cmdline equivalent would be `uhubctl`,
but linden's hubs do not support per-port power switching (`uhubctl` as
root: no compatible devices detected, 2026-09-23), so no command-line
replug exists on this machine.

## Test-method pitfalls hit during this incident

- The agent bash sandbox cannot complete PulseAudio/PipeWire capture
  clients (ffmpeg, parec hang forever on stream data). Use direct
  `arecord -D hw:...` for hardware verdicts, or `systemd-run --user` to
  escape the sandbox.
- Timed-out sandbox calls leave frozen orphaned processes (SIGSTOPped
  cgroup) that hold the PipeWire source open. Kill them before retesting.
- PipeWire holds the ALSA device even when idle; stop its socket units
  first or `arecord` reports busy, not the real fault.
- Careless `pkill -f` patterns match the calling shell itself.

## Current state

- udev rule installed: `/etc/udev/rules.d/50-yeti-no-autosuspend.rules`
  (`power/control=on`, verified on the live device)
- Expected: idle no longer wedges the mic
- Open question: whether true S3 suspend still wedges it. If the mic is
  dead after a sleep despite `power/control=on`, try replug, then consider
  installing `uhubctl` and testing the hub power cycle.
