# Blue Yeti suspend fix

The Blue Yeti (USB id `046d:0ab7`) wedges across S3 suspend on linden: after
resume the device is still enumerated but delivers no audio, and only a
physical unplug/replug revives it. USB re-enumeration is the fix, and it can
be forced in software.

Two parts: a system helper script (runs as root) and a pi extension
(`harness/pi/extensions/yeti-mic-reset.ts`) that detects resume from sleep
and runs the helper. A `/mic-reset` command in pi triggers it manually.

## One-time setup (per machine, needs sudo)

From the repo root:

```bash
sudo install -m 755 microphone/yeti-usb-reset.sh /usr/local/sbin/yeti-usb-reset
echo 'phage ALL=(root) NOPASSWD: /usr/local/sbin/yeti-usb-reset' | sudo tee /etc/sudoers.d/yeti-usb-reset
sudo chmod 440 /etc/sudoers.d/yeti-usb-reset
sudo visudo -c   # validate the sudoers file
sudo -n /usr/local/sbin/yeti-usb-reset   # must print "reset 1-7.x" without asking
```

The sudoers rule is scoped to that one script, so the extension gets no
general root. These files live in `/etc` and are per-machine state; this
document is the recreate step. The extension itself stows to both machines
with the rest of the pi package.

Without the sudoers rule the extension falls back to `pkexec` (GNOME shows a
GUI password dialog once per reset), then gives up with a warning.

## How resume detection works

pi has no system-resume event, so the extension polls every 30 s while a
session is running and compares wall-clock time against `os.uptime()`. If
wall time advanced more than uptime by more than 5 seconds, the machine was
asleep in between, and the mic gets reset. Idle detection, no root needed
until the reset itself.

## Test

```bash
systemctl suspend            # or close the lid
# after resume, within ~30 s:
journalctl --user -n 5       # no direct log; watch for the pi notification
sudo -n /usr/local/sbin/yeti-usb-reset   # manual check, should print "reset 1-7.x"
/mic-reset                  # inside pi, same thing via the extension
pactl get-default-source | grep blue     # mic back as default source
```

## Notes

- The script matches by vendor:product id, not USB port, so it survives
  port changes and works on woodlawn unchanged if a Yeti is ever attached.
- On machines without a Yeti the script prints "no Blue Yeti found" and the
  extension stays silent.
- If the mic model changes, update `USB_VID`/`USB_PID` in the extension and
  the ids in the script.
