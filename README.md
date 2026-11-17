# Fedora + KAIT2EN to Arch on a T2 Mac

The starting point is a T2 MacBook running Fedora with KAIT2EN installed. The
goal is a native Arch system: stock Arch kernel, KAIT2EN DKMS modules, then
KAIT2EN userspace packaged with Arch `PKGBUILD`s.

Installation is typed at the console: no AI agent or automated installer.
Wi-Fi must work in the live environment for `pacstrap`.

## Route

1. **Test the modules** while Fedora still boots. Phase 1 checks KAIT2EN's
   current `main` branch against Arch's stock kernel.
2. **Build and boot a T2-aware Arch USB.** Phase 2 uses `archiso-t2` so the
   live system can use the built-in keyboard and trackpad.
3. **Install Arch manually over Wi-Fi.** Phase 3 partitions the Linux volumes
   and runs `pacstrap`.
4. **Build for the target.** Phase 4 configures the installed system and
   builds KAIT2EN DKMS modules in its chroot. Reboot after the boot checks pass.
5. **Finish the Arch port.** Phase 5 validates hardware; Phase 6 packages
   KAIT2EN userspace; Phase 7 covers optional extras.

The live USB boots a T2-aware `t2linux` kernel. The installed system uses
stock Arch `linux` plus KAIT2EN DKMS modules built for that kernel. Do not
install the `linux-t2` kernel alongside the KAIT2EN driver stack.

## Before starting

- Back up the Mac and identify the partitions you intend to replace.
- Keep the live USB, a keyboard, and a network fallback available.
- Bundle the KAIT2EN `main` branch archive, project files, and locally sourced
  firmware in the live ISO for Phases 3–4.
- The optional ACPICA S3 resume patch is documented in
  [patches/](patches/README.md); it requires rebuilding and booting a patched
  stock kernel.
- Source Apple/Broadcom firmware lawfully for your own machine. It is
  proprietary and is not included here.

## Pages

| Phase | Work |
|---|---|
| [1](phase1/README.md) | Optional DKMS build gate |
| [2](phase2/README.md) | Build the T2-aware Arch USB |
| [3](phase3/README.md) | Wi-Fi, partitions, and base install |
| [4](phase4/README.md) | Chroot, DKMS, initramfs, and bootloader |
| [5](phase5/README.md) | First-boot checks and networking |
| [6](phase6/README.md) | KAIT2EN userspace `PKGBUILD`s |
| [7](phase7/README.md) | Optional Touch ID packages |
| [Kernel patch](patches/README.md) | Optional ACPICA S3 resume fix |
| [Upstream](UPSTREAM.md) | Source branches and licensing |

This documentation targets T2 MacBooks; other models, upstream changes, and
later kernels may differ.

## License

This project is licensed under the GNU General Public License v3.0 or later
(`GPL-3.0-or-later`); see [`LICENSE`](LICENSE).

Third-party sources and packages retain their own upstream licenses. The
kernel patch under [`patches/`](patches/) is derived from ACPICA source and
remains under its upstream dual license, `BSD-3-Clause OR GPL-2.0`; see
[`patches/README.md`](patches/README.md).
