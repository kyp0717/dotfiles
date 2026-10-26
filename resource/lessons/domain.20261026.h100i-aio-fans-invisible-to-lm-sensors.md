# 2026-10-26 — "Loud fan after reboot" was the H100i radiator fans, invisible to lm-sensors

## Symptom

Fan roars after a warm `reboot`, whisper-quiet after shutdown + power on.
No motherboard sensor shows anything unusual; all temps idle. GPU fan
verified fine (0 RPM, zero-RPM mode, controllable via amdgpu pwm).

## Root cause

The machine has a **Corsair iCUE H100i Elite RGB AIO** (USB ID
`1b1c:0c35`). Its two radiator fans are controlled by the cooler's own
MCU from **coolant temperature**, over USB. Linux sees none of it
without `liquidctl`:

- **Warm reboot**: coolant still 35+ C from prior use → fans run high
  duty for minutes. Nothing in the OS can see or change it.
- **Cold boot**: coolant at room temp → ~20% duty, quiet.

The PSU (Corsair AX1200i) is a red herring: zero-RPM fan below ~30%
load (idle system draws far less), and its Corsair Link USB dongle is
not connected, so it does not even enumerate on lsusb.

## The pump-tach trap (do not chase this)

The AIO pump tach is wired to the motherboard `CPU_FAN` header. It
shows up in `nct6798` (Super I/O) as a constant ~2500 RPM fan that
**ignores every PWM and DC speed command** — because the pump takes
orders over USB, not from the header. A fan-shaped sensor that cannot
be controlled and never changes speed is probably a pump tach. Check
`lsusb` for an AIO before spending time on it.

## Diagnosis method that worked

1. `lsusb` for Corsair/NZXT/other AIO or digital-PSU devices — the
   noise source was visible here the whole time.
2. Dump all `nct6798` pwm/fan registers in the loud state and the quiet
   state and diff. **Identical registers with different noise means the
   source is outside the readable set** (AIO fans, PSU fan).
3. Stop-test fans one at a time (`pwmN_enable=1`, `pwmN=0`, 6 s) —
   but only meaningful **during the loud state**; stopping fans during
   the quiet state proves nothing. The loud state here only exists
   for minutes after a warm reboot.
4. `sudo liquidctl status` gives coolant temp, radiator fan speeds and
   duties, pump speed — instant confirmation.

## Fix applied (linden, per-machine state)

- `apt install liquidctl`; after install run
  `sudo udevadm control --reload-rules && sudo udevadm trigger` or
  status needs root (package ships udev rules but they are not
  triggered on install).
- Quiet coolant-based curve:
  `liquidctl --match H100i set fan speed 20 20 30 35 35 60 40 80 45 100`
- `/etc/systemd/system/liquidctl.service` (enabled, oneshot, same two
  commands as ExecStart) — device settings reset on power loss, so the
  unit is required, not optional.
- `/etc/modules-load.d/nct6775.conf` loads the Super I/O driver for
  chassis fan telemetry (was not auto-loaded).

## Recreate on woodlawn (or any fresh machine with the H100i)

1. `apt install liquidctl`, reload udev rules as above.
2. Copy `/etc/systemd/system/liquidctl.service` from linden, enable it.
3. Optionally `/etc/modules-load.d/nct6775.conf`.
4. Verify: `liquidctl --match H100i status` without sudo.

## Pending (portable pieces for this repo)

- `liquidctl.service` + udev reload belong in a script following the
  `scripts/udev.config.sh` pattern so both machines converge.
