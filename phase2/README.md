# Phase 2 — build the T2-aware Arch USB

Clone the `senpai` branch of
[`archiso-t2`](https://github.com/t2linux/archiso-t2) on Fedora:

```sh
git clone --branch senpai --single-branch https://github.com/t2linux/archiso-t2
cd archiso-t2
```

Download the current KAIT2EN `main` branch archive:

```sh
archive="$HOME/kait2en-main.tar.gz"
curl -fL "https://codeload.github.com/kaiT2en/KaiT2en-Fedora/tar.gz/refs/heads/main" \
  -o "$archive"
```

Stage the project, archive, and your locally sourced firmware under the ISO's
`/root`:

```sh
PROJECT_DIR=/path/to/archlinux-t2-macbook
FIRMWARE_DIR=/path/to/your/firmware
ROOTFS="$PWD/archiso/airootfs/root"

mkdir -p "$ROOTFS/public" "$ROOTFS/t2/firmware"
git -C "$PROJECT_DIR" archive --format=tar HEAD |
  tar -C "$ROOTFS/public" -xf -
install -m 0644 "$archive" "$ROOTFS/t2/kait2en-main.tar.gz"
cp -a "$FIRMWARE_DIR/." "$ROOTFS/t2/firmware/"
```

Build the image in a privileged Arch container:

```sh
sudo podman run --rm --privileged --security-opt label=disable \
  -v "$PWD:/work:z" -w /work \
  docker.io/library/archlinux:latest \
  bash -lc 'pacman -Syu --noconfirm &&
    pacman -S --noconfirm --needed archiso wget grub &&
    mkarchiso -v archiso'
```

The ISO contains your proprietary firmware; keep it local and do not
redistribute it. Identify the whole USB device before writing; `dd` erases it:

```sh
lsblk -dpno NAME,SIZE,MODEL,TRAN
sudo dd if=archiso/out/REPLACE-with-built-image.iso \
  of=/dev/disk/by-id/REPLACE-with-whole-USB-device \
  bs=4M status=progress conv=fsync
sync
```

Boot the USB from the Mac's startup picker. The project, source archive, and
firmware are available under `/root`.
