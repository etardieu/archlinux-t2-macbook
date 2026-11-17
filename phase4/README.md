# Phase 4 — configure and build

In the target chroot from [Phase 3](../phase3/README.md), configure the
system, build DKMS modules for its stock Arch kernel, then prepare the boot.

## 1. Give the system its own name and locale

```sh
ln -sf /usr/share/zoneinfo/Area/Location /etc/localtime
hwclock --systohc
```

Edit `/etc/locale.gen`, uncomment the UTF-8 locale you want, then run:

```sh
locale-gen
```

Write `/etc/locale.conf` with that same locale, for example:

```text
LANG=en_US.UTF-8
```

Set `/etc/hostname`, create a user, and configure sudo:

```sh
useradd -m -G wheel -s /bin/bash REPLACE-with-your-login
passwd REPLACE-with-your-login
```

Run `EDITOR=nano visudo` and uncomment the rule that allows the `wheel` group
to use sudo. Replace `/etc/hostname` with a short name of your choice.

## 2. Install the kernel command line and driver blacklists

Set `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub` to:

```text
intel_iommu=on iommu=pt i915.enable_guc=2 pm_async=off brcmfmac.p2pon=0 pci=noaer mem_sleep_default=deep initcall_blacklist=cmos_init,magicmouse_driver_init module_blacklist=applesmc,macsmc,hid_apple,hid_magicmouse,appletbdrm,apple_bce,apple_gmux,sbs,apple_mfi_fastcharge
```

Defer PCIe power-saving flags until the baseline is stable. Add the driver
blacklists to `/etc/modprobe.d/t2-driver-conflicts.conf`:

```conf
install acpi_tad /bin/true
install applesmc /bin/true
install macsmc /bin/true
install hid_apple /bin/true
install hid_appletb_bl /bin/true
install hid_appletb_kbd /bin/true
install hid_magicmouse /bin/true
install appletbdrm /bin/true
install apple_bce /bin/true
install apple_mfi_fastcharge /bin/true
install apple_gmux /bin/true
install sbs /bin/true
```

Set `MODULES` in `/etc/mkinitcpio.conf` to include:

```text
apple-t2-bridge apple-t2-vhci-hcd hid_t2magicmouse t2_precision_trackpad
t2touchbar_bl t2touchbar_kbd t2bdrm
```

Keep the `modconf` and `keyboard` hooks.

## 3. Build the DKMS modules

Read `phase1/preflight.sh`; it stages and builds modules from the prepared
source tree.

Extract the KAIT2EN source archive that Phase 3 copied into `/root/t2/`:

```sh
mkdir -p /root/kait2en
tar -xzf /root/t2/kait2en-*.tar.gz \
  -C /root/kait2en --strip-components=1
test -d /root/kait2en/modules
```

Run the build gate with package installation and upgrades disabled:

```sh
PACKAGE_UPGRADE=0 INSTALL_PACKAGES=0 \
  REPO=/root/kait2en \
  REPORT=/root/phase1-report.txt \
  bash /root/t2/preflight.sh
```

Check the report, installed module state, and kernel version:

```sh
dkms status
find /usr/lib/modules/*/updates -name '*.ko*' -print
```

## 4. Prepare the initramfs and bootloader

Regenerate all initramfs images only after the module build and `MODULES`
configuration are correct:

```sh
mkinitcpio -P
```

Mount the shared EFI partition at `/boot/efi`:

```sh
mkdir -p /boot/efi
EFI_PART=/dev/disk/by-id/REPLACE-with-your-shared-efi-partition
mount "$EFI_PART" /boot/efi
```

Add its UUID to `/etc/fstab`, then install GRUB into the shared EFI partition
and write its configuration:

```sh
EFI_UUID=$(blkid -s UUID -o value "$EFI_PART")
printf 'UUID=%s /boot/efi vfat umask=0077 0 2\n' "$EFI_UUID" >> /etc/fstab
grub-install --target=x86_64-efi --efi-directory=/boot/efi \
  --bootloader-id=Arch --removable
grub-mkconfig -o /boot/grub/grub.cfg
```

Keep the existing macOS boot path. Verify the mount, generated configuration,
kernel, initramfs, and modules:

```sh
findmnt /boot /boot/efi
ls -l /boot/vmlinuz-linux /boot/initramfs-linux.img
grep '^MODULES=' /etc/mkinitcpio.conf
dkms status
```

## NetworkManager

Configure NetworkManager to use iwd by creating
`/etc/NetworkManager/conf.d/wifi_backend.conf`:

```ini
[device]
wifi.backend=iwd
```

Enable NetworkManager. It starts and manages iwd for this backend:

```sh
systemctl enable NetworkManager.service
```

Phase 5 covers the live-to-installed network handoff. Install locally sourced
firmware staged by Phase 3 with:

```sh
install -d /usr/lib/firmware/brcm
install -m 0644 /root/t2/firmware/* /usr/lib/firmware/brcm/
```

Enable Bluetooth:

```sh
systemctl enable bluetooth.service
```

For COSMIC, add `cosmic-session` and `cosmic-greeter` to the Phase 3
`pacstrap` command.

Reboot after all checks and setup pass. Repair failures from the chroot or live
USB.
