# OWRT Doctor

**OWRT Doctor** is a lightweight, privacy-first diagnostics toolkit for OpenWrt.

It combines repeatable health checks, clear PASS/WARN/FAIL results, extensible check plugins, privacy-safe redaction, and a one-command support bundle that can be attached to bug reports.

The project intentionally avoids telemetry and does **not** upload anything automatically.

## Why this exists

Troubleshooting OpenWrt often means collecting information from many places: `ubus`, `uci`, routes, DHCP leases, DNS, firewall state, wireless status, logs, and optional overlay-network tools.

OWRT Doctor turns that into a reproducible workflow:

```sh
owrt-doctor scan
owrt-doctor bundle
```

## Current status

**v0.2.0 — Topology Intelligence**

Checks include:

- system uptime, free memory, root filesystem usage and clock sanity,
- OpenWrt package-manager generation (`apk` or `opkg`),
- time-sync daemon health,
- default route and active upstream interface,
- topology classification for router, LAN-upstream, AP/bridge, repeater/bridge and custom-upstream layouts,
- IPv6 global-address/default-route health,
- raw Internet reachability and DNS resolution,
- dnsmasq and DHCP lease visibility,
- duplicate dynamic and static DHCP address detection,
- wireless status,
- firewall4 validation,
- optional Tailscale daemon/status checks.

## Commands

```text
owrt-doctor scan
owrt-doctor bundle [OUTPUT.tar.gz]
owrt-doctor sanitize
owrt-doctor version
owrt-doctor help
```

### Scan

```sh
owrt-doctor scan
```

Exit codes:

- `0`: no warnings or failures
- `1`: at least one warning, no failures
- `2`: at least one failure

### Privacy-safe support bundle

```sh
owrt-doctor bundle
```

The bundle is created locally under `/tmp` by default. It contains diagnostic output, sanitized UCI configuration, recent logs and a doctor report.

OWRT Doctor redacts common secret-bearing fields, Wi-Fi SSIDs, MAC addresses and email-like identifiers before writing the bundle.

**Nothing is uploaded automatically.**

## Direct test install

```sh
scp -r files/usr/* root@192.168.1.1:/usr/
ssh root@192.168.1.1 'chmod +x /usr/bin/owrt-doctor /usr/lib/owrt-doctor/checks.d/*.sh'
ssh root@192.168.1.1 'owrt-doctor scan'
```

## Build as an OpenWrt package

Place the repository under an OpenWrt build tree:

```sh
git clone https://github.com/AbeyyN/owrt-doctor.git package/owrt-doctor
make menuconfig
```

Select:

```text
Utilities -> owrt-doctor
```

Then build:

```sh
make package/owrt-doctor/compile V=s
```

The package is architecture-independent (`PKGARCH:=all`). On OpenWrt generations using `opkg`, the build system emits the corresponding package format; on OpenWrt 25.12+ apk-based builds, the OpenWrt build system handles apk packaging.

## Compatibility target

- OpenWrt 24.10
- OpenWrt 25.12+
- BusyBox `ash`
- `opkg` and `apk` generations

## Project goals

1. Keep the core tiny and auditable.
2. Never collect secrets intentionally.
3. Make diagnostics reproducible.
4. Make checks easy to extend.
5. Reduce issue-triage time for OpenWrt-related projects.
6. Work toward inclusion in community package feeds.

## Non-goals

- replacing LuCI,
- remote administration,
- cloud telemetry,
- automated destructive remediation,
- collecting Wi-Fi passwords, private keys or tokens.

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and [docs/ROADMAP.md](docs/ROADMAP.md).

## License

MIT.
