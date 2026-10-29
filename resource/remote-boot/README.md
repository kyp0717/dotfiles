# Remote boot and access with the ASUS RT-AX68U

Chosen design for woodlawn in Boston. The RT-AX68U replaces the Verizon
CR1000A as the main router. Its WireGuard server provides remote access,
and its native Wake-on-LAN page powers on woodlawn. No GL.iNet, Tailscale,
ASUS cloud dependency, UDP 9 forwarding, or RDP port forwarding is needed.

## Hardware and requirements

- Boston PC: ASUS ROG STRIX B650E-F GAMING WIFI, wired Ethernet
  (Intel 2.5 GbE). Use Ethernet, not Wi-Fi, for reliable wake.
- Router: ASUS RT-AX68U on stock firmware 3.0.0.4.388.xxxxx or newer.
- Internet: Verizon Fios ONT with Ethernet WAN handoff.
- Remote client: WireGuard app and Remmina on the Connecticut-side laptop.

## 1. Install the ASUS router

1. Disconnect the Ethernet WAN cable from the Verizon CR1000A.
2. Connect that ONT Ethernet cable to the RT-AX68U WAN port.
3. Connect woodlawn's Intel NIC to an RT-AX68U LAN port.
4. Power on the ASUS router and woodlawn.
5. Open `http://www.asusrouter.com` on woodlawn.
6. Run the setup wizard and create a new router admin password.
7. Select Automatic IP / DHCP for the Verizon Fios WAN connection.
8. Confirm that woodlawn has internet access.
9. Configure the Wi-Fi network names and passwords.

If WAN remains disconnected, reboot the ONT and ASUS router. Keep the
CR1000A disconnected to avoid double NAT.

## 2. Update the firmware

1. Open Administration > Firmware Upgrade.
2. Install the latest stock ASUS firmware.
3. Use firmware 3.0.0.4.388.xxxxx or newer.
4. Reboot the router if requested.
5. Confirm VPN > VPN Server > WireGuard VPN is present.

Merlin is not required.

## 3. Reserve woodlawn's LAN address

1. On woodlawn, run `ip link` and record the wired interface name and MAC
   address privately.
2. In the ASUS UI, open LAN > DHCP Server.
3. Add woodlawn's MAC address under manually assigned DHCP addresses.
4. Give it a reserved address within the ASUS LAN subnet.
5. Reconnect woodlawn's network and confirm it receives that address.

This gives Remmina a stable destination.

## 4. Configure ASUS DDNS

1. Open WAN > DDNS in the ASUS UI.
2. Enable DDNS, select ASUS DDNS, and choose an available hostname.
3. Apply the settings.
4. Confirm the router reports a public WAN address.

DDNS lets the WireGuard profile find the router when Verizon changes the
public IP address.

## 5. Configure the WireGuard server

1. Open VPN > VPN Server > WireGuard VPN.
2. Enable the WireGuard server.
3. Add a client profile for the Connecticut-side laptop.
4. Apply the settings and export the generated configuration.
5. Keep the configuration private because it contains credentials.
6. Install the official WireGuard app on the remote laptop and import the
   configuration.

Do not enable general WAN access to the router administration page.

## 6. Test WireGuard from outside the LAN

1. Disconnect the remote laptop from the Boston network.
2. Use a phone hotspot or another external connection.
3. Activate the imported WireGuard tunnel.
4. Open the ASUS router's LAN address in a browser.
5. Confirm that the router administration page loads.

Do not continue until this external VPN test works.

## 7. Enable Wake-on-LAN on woodlawn

BIOS (F2/Del at boot), under Advanced > APM Configuration:

- Power On By PCI-E: Enabled
- ErP: Disabled, because ErP cuts standby power to the NIC

Optionally enable Restore on AC Power Loss > Power On for outage recovery.

In Ubuntu:

```bash
# Find the interface name and check wake support.
ip link
sudo ethtool <interface>

# Find the NetworkManager connection name.
nmcli c show

# Enable magic-packet wake persistently.
sudo nmcli c mod "<connection-name>" 802-3-ethernet.wake-on-lan magic

# Verify the result. Want "Supports Wake-on: g" and "Wake-on: g".
sudo ethtool <interface>
```

## 8. Test ASUS Wake-on-LAN

1. Connect the remote laptop to the ASUS WireGuard tunnel.
2. Open the ASUS router administration page through the tunnel.
3. Open Network Tools > Wake on LAN.
4. Enter woodlawn's wired MAC address or select its saved entry.
5. Shut woodlawn down normally, not into hibernate.
6. Click Wake up in the ASUS UI.
7. Confirm that woodlawn powers on.

No UDP port forwarding is needed. The router generates the magic packet
locally while it remains powered on.

## 9. Configure Remmina

1. On woodlawn, open Settings > Sharing > Remote Desktop.
2. Enable Remote Desktop and set its RDP credentials.
3. On the remote laptop, create a new Remmina RDP profile.
4. Enter woodlawn's reserved LAN IP address and enable TLS.
5. Connect while the WireGuard tunnel is active.

GNOME Remote Desktop shares the console session. Do not create an RDP
port-forwarding rule.

## 10. Perform the full unattended test

1. Put the remote laptop on an external network.
2. Shut woodlawn down completely.
3. Connect to the ASUS WireGuard server.
4. Wake woodlawn through Network Tools > Wake on LAN.
5. Wait for Ubuntu and networking to finish starting.
6. Connect Remmina to woodlawn's reserved LAN IP.
7. Confirm that no local keyboard or monitor action is needed.

If Remmina only works after a local Ubuntu login, the remaining issue is
the GNOME remote-desktop session configuration, not the router.

## Routine use from Connecticut

1. Connect the laptop to the ASUS WireGuard tunnel.
2. Open Network Tools > Wake on LAN on the router and wake woodlawn.
3. Wait for boot, then connect Remmina to woodlawn's reserved LAN IP.
4. Shut woodlawn down normally when done. The router stays up.

## Gotchas

- Keep the PC PSU plugged in and switched on. A PSU or breaker outage
  prevents Wake-on-LAN.
- The ASUS router and home internet must stay up for remote access.
- If wake fails, recheck ErP Disabled, Power On By PCI-E Enabled, and
  `ethtool <interface>` showing `Wake-on: g`.
- Never commit the WireGuard profile, router credentials, RDP credentials,
  DDNS hostname, public IP, or woodlawn MAC address to git.
