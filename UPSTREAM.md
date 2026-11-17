# Upstream sources and boundaries

The project repository does not vendor upstream sources.

## KAIT2EN

- Project: <https://github.com/kaiT2en/KaiT2en-Fedora>
- DKMS and Phase 6 recipes follow the `main` branch. Phase 7 uses the pinned
  Touch ID revision below so its bridge recipe does not drift with upstream.
- KAIT2EN is Fedora-focused; Arch packaging lives here.

### Phase 7 Touch ID source

- Commit: `e661ff21f4eeecc6208ee3ff60ad17f90dc9d249` (2026-11-15).
- Archive SHA-256:
  `e82c6911bcd99eb5f131941c601a33774f9cdc6bb53338cf99dcaf2c09cc4eac`.
- Used for `phase7/t2-services-common` and `phase7/t2-touchid`. Fetched at
  build time; not vendored here.
- Touch ID reaches BiometricKit over BridgeXPC on the internal CDC-NCM link.
  It does not use the `t2sep` mailbox or export fingerprint templates.

## T2-aware live media

- Project: <https://github.com/t2linux/archiso-t2>
- The live image instructions follow the `senpai` branch.

## Licensing

Third-party sources and dependencies retain their upstream licenses. Review
those terms before redistributing derived work.
