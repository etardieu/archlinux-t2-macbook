# Kernel patches

Optional source patches for the stock Arch `linux` kernel. They are not DKMS
modules: applying one means rebuilding and booting a patched kernel. Keep the
stock kernel as a bootable fallback.

## `acpica-pci-bus-number.patch`

Fixes a fixed ~20–28 s S3 resume stall seen on T2 MacBooks with Titan Ridge
Thunderbolt. While the PCI bridge leaves D3cold in its ACPI `_PS0`, ACPICA reads
the bridge's primary bus register as 0 and caches the Thunderbolt `PCI_Config`
region at bus 0. Mailbox commands then poll the wrong device and time out.

This is the Linux adaptation of <https://github.com/open-acpica/acpica/pull/1236>
(tracked in <https://github.com/t2linux/kernel/issues/30>). As of 2026-11-16 it
is not merged upstream; installing a newer stock kernel alone does not include
it. Unlike the D3cold udev workaround, it does not increase suspend drain.

Patch SHA-256:
`f563fb3119b632e46e7262be64424318ea6f997336e2289278230024485f4cfb`

Check that it still applies to the kernel source you are building:

```sh
cd /path/to/linux-source
patch -p1 --dry-run < /path/to/patches/acpica-pci-bus-number.patch
git apply --check -p1 /path/to/patches/acpica-pci-bus-number.patch
```

To build, add the patch to the Arch `linux` PKGBUILD `source=()` and its hash to
`sha256sums=()`, then build and install both `linux` and `linux-headers`. Rebuild
the KAIT2EN DKMS modules against the new vermagic. The patched kernel is not
the GRUB default; select it explicitly from Advanced options until resume is
validated.

Check the result after suspending and resuming a few times:

```sh
echo 1 | sudo tee /sys/power/pm_print_times
journalctl -b -k | grep -E 'suspend entry|suspend exit|ec interrupt unblocked'
```

The gap between the last CPU-offline message and user-space freezing (or S3
exit to the EC interrupt) should drop from tens of seconds to a few seconds.
Confirm Thunderbolt/USB-C and charging come back before relying on the patch.
