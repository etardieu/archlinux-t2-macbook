# Phase 7 — Touch ID

These recipes package the T2 CDC-NCM integration and fprintd bridge from a
pinned KAIT2EN Touch ID revision. The source is fetched at build time and is
not vendored here; see [UPSTREAM.md](../UPSTREAM.md).

Build the common package first, then the bridge:

```sh
cd phase7/t2-services-common
makepkg
cd ../t2-touchid
makepkg
```

If a local dependency is missing, `makepkg --nodeps` can build the archive;
dependency metadata is still recorded in the package.

The common recipe installs the NetworkManager and udev files for the internal
CDC-NCM link under `/usr/lib`, rewrites `/usr/sbin/ip` to `/usr/bin/ip` for Arch,
and omits the upstream suspend unit, migration helpers and lifecycle actions.
It does not overwrite local `/etc` configuration.

The Touch ID recipe installs the bridge, a systemd unit, an fprintd drop-in, a
D-Bus policy and `/etc/kait2en/t2-touchid.conf` (preserved on upgrade). It does
not enable the unit, edit PAM, or bind a fingerprint to a Linux account.

Biometrics stay enrolled in macOS and the T2. The bridge matches through
BridgeXPC on the CDC-NCM link; it does not use the T2 SEP mailbox module or
export templates. Keep password authentication available and review fallback
before enabling fingerprint login. These recipes have not been hardware-tested
here.
