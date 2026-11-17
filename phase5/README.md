# Phase 5 — first boot

Check input, Touch Bar, audio, fans, battery, suspend, brightness, Bluetooth,
and Thunderbolt one at a time.

## NetworkManager

The live ISO uses preconfigured `systemd-networkd` for DHCP; that setup is not
copied into the installed system. NetworkManager uses an internal DHCP client
by default ([ArchWiki](https://wiki.archlinux.org/title/NetworkManager#DHCP_client)).
In the first install it failed to obtain an address, so verify the target:

```sh
systemctl status NetworkManager
nmcli device status
journalctl -b -u NetworkManager --no-pager
grep -R '^[[:space:]]*dhcp=' /etc/NetworkManager
ip address
ip route
```

If Wi-Fi is missing, check firmware and driver, then restart NetworkManager
and scan:

```sh
ls /usr/lib/firmware/brcm/
sudo systemctl restart NetworkManager
nmcli radio wifi on
nmcli device wifi rescan
nmcli device wifi list
```

NetworkManager manages the iwd backend configured in Phase 4. Do not enable
`iwd.service` or `systemd-networkd` to manage the same interface. Install
`dhcpcd` only if NetworkManager is explicitly configured to use it.

The live-ISO firmware timing issue is covered in [Phase 3](../phase3/README.md).

## Hardware

Record results for:

- keyboard, trackpad, and Touch Bar;
- Wi-Fi and Bluetooth;
- speakers, microphone, and headphones;
- fans, battery, and charge behavior;
- suspend/resume and brightness;
- graphical login and Thunderbolt devices, if used.

### S3 resume stall

A fixed long pause after CPU offlining during resume is an ACPICA PCI bus number
bug. The fix is an optional kernel patch; see
[patches/README.md](../patches/README.md). The stock kernel does not include it,
and the patched kernel must be booted explicitly.

Useful evidence:

```sh
uname -r
dkms status
lsmod
journalctl -b --no-pager | grep -iE 't2|brcm|bluetooth|firmware|error'
```

If input or modules fail, boot the T2-aware USB and follow
[Phase 4](../phase4/README.md).
