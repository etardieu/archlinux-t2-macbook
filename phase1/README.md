# Phase 1 — DKMS build gate

Before changing partitions, test the current KAIT2EN `main` branch against
Arch's stock kernel in a disposable Arch container. The check needs internet
access; Phase 5 tests the hardware.

From the project directory:

```sh
podman run --rm \
  -v "$PWD:/work:z" \
  -w /work \
  docker.io/library/archlinux:latest \
  bash /work/phase1/preflight.sh
```

The report is `phase1-report.txt`; keep it local. A previous run built 12
modules for Arch `linux 7.3.4-arch1-1`; results may change with upstream.
