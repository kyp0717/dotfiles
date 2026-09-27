# Generic modular PSU cable: buy checklist and pinout test

Written for the linden RX 6700 XT install (2026-09-26), applies to any
generic male-to-male modular cable purchase. Reference: the AX1200's modular
jacks are not wired to any standard; only a cable made for the exact PSU
model has a guaranteed pinout. A wrong pinout can destroy the GPU.

## Why this exists

Corsair's official AX1200 PCIe cable (CP-8920016) is often out of stock.
Third-party cables sold as "for Corsair" frequently reuse one pinout across
incompatible brands (Corsair, Thermaltake, ARESGAME listings are the tell).
Buy generic only if it passes the test below before it touches the GPU.

## Buy checklist

- Listing must name the exact PSU ("compatible with AX1200") or be the
  Corsair part CP-8920016. "For Corsair PSUs" alone is not enough.
- Termination must be PCIe 6+2 on the GPU end. Do not buy an EPS/CPU 8-pin
  cable; it fits the same jack style and is pinned differently.
- 18 AWG wire or thicker.
- One cable per connector. For the 6700 XT's 8+6 sockets, use two separate
  leads, never both sockets of one daisy-chained lead.

## Pinout reference (GPU end, 6+2 connector)

| Pin | Signal |
|---|---|
| 1 | +12 V |
| 2 | +12 V |
| 3 | +12 V |
| 4 | GND |
| 5 | Sense (reads GND) |
| 6 | GND |
| 7 | GND (the "+2" half) |
| 8 | GND (the "+2" half) |

## Voltage test (do this before installing the GPU)

1. Install the generic cable into a PCIe jack on the PSU. Connect nothing
   to the GPU end. Unplug the cable immediately if the PSU is live while
   plugging.
2. Power the PSU on (full boot is fine; the cable is the only unknown).
3. Set a multimeter to DC volts, 20 V range.
4. Probe each pin of the 6+2 end, negative lead on the PSU case or pin 4:
   - Pins 1, 2, 3 must read +11.4 to +12.6 V.
   - Pins 4 through 8 must read 0 V.
5. Fail conditions, any of these means mis-pinned; return it:
   - A pin 1-3 reads 0 V or negative.
   - Any pin 4-8 reads 12 V.
   - Readings jump around when the cable is flexed (broken crimp).
6. Power off before unplugging. Re-run the test on the second cable.

## Fallback

- If no generic passes or none can be tested: CableMod configurator with
  AX1200 selected, or a reseller listing for CP-8920016.

## Related

- `MACHINES.md` PSU row: linden runs a Corsair AX1200.
- GPU needs 8+6 PCIe; the 8-pin comes from the freed GTX 1070 lead, the
  6-pin from the new cable.
