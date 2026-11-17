# Phase 3 — connect and install Arch

Boot the Phase 2 USB. Identify the target partitions with `lsblk -fp` and
`blkid`. Confirm working Wi-Fi and partition identities before formatting;
`pacstrap` also needs Wi-Fi.

```sh
lsblk -fp
blkid
```

## Wi-Fi

If `iwd` started before the BCM4364 firmware loaded, install the firmware
bundled under `/root/t2/firmware`, then restart `iwd`:

```sh
install -d /usr/lib/firmware/brcm
install -m 0644 /root/t2/firmware/* /usr/lib/firmware/brcm/
dmesg | grep -iE 'brcmfmac|firmware'
systemctl restart iwd
```

Connect with `iwctl`, using the device shown by `device list`:

```text
iwctl
[iwd]# device list
[iwd]# station DEVICE scan
[iwd]# station DEVICE get-networks
[iwd]# station DEVICE connect YOUR_SSID
```

Confirm DHCP, routing, and DNS:

```sh
ip address
ip route
ping -c1 archlinux.org
```

The live image uses `systemd-networkd` and `systemd-resolved` for DHCP. Fix
Wi-Fi before continuing.

## Partitions and filesystems

Identify the shared EFI, macOS, swap, Linux `/boot`, and Linux root partitions.
Leave macOS and the shared EFI untouched; only swap, `/boot`, and root are
reformatted. Set the variables to the verified Linux partitions:

```sh
SWAP_PART=/dev/disk/by-id/REPLACE-with-your-swap-partition
BOOT_PART=/dev/disk/by-id/REPLACE-with-your-linux-boot-partition
ROOT_PART=/dev/disk/by-id/REPLACE-with-your-linux-root-partition
lsblk -fp "$SWAP_PART" "$BOOT_PART" "$ROOT_PART"
```

These commands erase those three partitions:

```sh
mkswap -L swap "$SWAP_PART"
mkfs.ext4 -L boot "$BOOT_PART"
mkfs.btrfs -L arch "$ROOT_PART"
```

Create and mount the Btrfs subvolumes:

```sh
mount "$ROOT_PART" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

OPTS=noatime,compress=zstd:3,ssd
mount -o "$OPTS,subvol=@" "$ROOT_PART" /mnt
mkdir -p /mnt/home /mnt/boot
mount -o "$OPTS,subvol=@home" "$ROOT_PART" /mnt/home
mount "$BOOT_PART" /mnt/boot
swapon "$SWAP_PART"
```

Leave the shared EFI partition untouched until Phase 4.

## Base system

Check the connection again, then install from Arch repositories:

```sh
ping -c1 archlinux.org
pacstrap -K /mnt \
  base linux linux-headers linux-firmware intel-ucode \
  btrfs-progs grub efibootmgr dkms base-devel git bc nano \
  networkmanager iwd bluez bluez-utils wireless-regdb \
  pipewire wireplumber alsa-ucm-conf
```

Add `cosmic-session cosmic-greeter` if you want COSMIC at first boot.

Generate and inspect the fstab:

```sh
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

It should contain root, home, swap, and `/boot`. The EFI entry is added in
Phase 4.

Copy the KAIT2EN source archive and module helper from the live image:

```sh
mkdir -p /mnt/root/t2
cp /root/t2/kait2en-main.tar.gz /mnt/root/t2/
cp /root/public/phase1/preflight.sh /mnt/root/t2/
```

Copy the firmware for use after reboot:

```sh
cp -a /root/t2/firmware /mnt/root/t2/
```

Enter the target:

```sh
arch-chroot /mnt
```

Continue with [Phase 4](../phase4/README.md). Build the modules for the
installed stock Arch kernel before rebooting.
