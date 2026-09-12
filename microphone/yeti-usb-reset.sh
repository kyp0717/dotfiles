#!/bin/sh
# Software replug for the Blue Yeti (046d:0ab7).
# After S3 suspend the Yeti often comes back wedged and only a physical
# unplug/replug revives it. Unbind/bind forces the same USB re-enumeration.
# See microphone/yeti-usb-reset.md in the dotfiles repo.
set -u

found=0
for d in /sys/bus/usb/devices/*-*; do
    [ -f "$d/idVendor" ] || continue
    [ "$(cat "$d/idVendor")" = "046d" ] || continue
    [ "$(cat "$d/idProduct")" = "0ab7" ] || continue
    dev=${d##*/}
    echo "$dev" > /sys/bus/usb/drivers/usb/unbind
    sleep 1
    echo "$dev" > /sys/bus/usb/drivers/usb/bind
    echo "reset $dev"
    found=1
done

if [ "$found" = 0 ]; then
    echo "no Blue Yeti (046d:0ab7) found"
fi
exit 0
