# Phase 6 — small Arch packages, one at a time

After the stock Arch kernel and KAIT2EN DKMS modules pass the Phase 5 checks,
build these Arch packages for KAIT2EN userspace.

The PKGBUILDs replace KAIT2EN's Fedora installers and install services
disabled. Review each service's defaults and rollback before enabling it.

## Recipes in this notebook

| Package | What it adds | Caution |
|---|---|---|
| `t2-kbd-backlight` | Keyboard backlight idle service | Check the UPower interface and suspend behavior |
| `t2-smc-control` | SMC telemetry and battery tools | Keep gauge service optional |
| `t2-fan-control` | Fan curve control | Review its default automatic-control setting before enabling |
| `t2-zone-power` | CPU/iGPU power limits | Leave disabled until thermal behavior is checked |
| `t2-alsa-ucm` | Apple T2 ALSA profiles | Install before the DSP graph |
| `t2-dsp` | PipeWire/WirePlumber DSP profiles | Requires its plugins; activate the model profile deliberately |
| `t2-rtc-sync` | Write synchronized time to the T2 RTC | Enable only after a time source is configured |
| `t2-macos-mount` | Read-only mounts for readable APFS volumes | Requires the APFS module; unit stays disabled |

Build a recipe by hand from its directory:

```sh
cd phase6/t2-kbd-backlight
makepkg
```

Inspect the package archive, then install it with `pacman -U`. See the recipe
comments for service and configuration behavior.

The optional macOS mount udev rule is separate from the package. The helper
mounts readable APFS volumes read-only.

Recipes build from the current KAIT2EN `main` branch; see
[`UPSTREAM.md`](../UPSTREAM.md).
