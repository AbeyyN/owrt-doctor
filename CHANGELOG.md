# Changelog

## [0.2.0] - 2026-08-27

### Added
- Topology Intelligence to classify conventional router, LAN-upstream, AP/bridge, wireless repeater/bridge and custom-upstream layouts.
- IPv6 health detection for global addressing and default-route availability.
- OpenWrt package-manager detection for both `apk` and `opkg` generations.
- Time-sync daemon health detection for `sysntpd`, `ntpd` and `chronyd`.
- Duplicate dynamic DHCP lease IP/client detection.
- Duplicate static DHCP address detection from UCI configuration.
- Architecture-independent package metadata (`PKGARCH:=all`) for shell-only package builds, including OpenWrt 25.12+ apk-based systems.

### Changed
- Bumped CLI and OpenWrt package version to 0.2.0.
- Expanded diagnostics beyond WAN-centric assumptions to describe the active topology explicitly.

## [0.1.1] - 2026-08-27

### Fixed
- Auto-detect the active upstream logical interface instead of assuming Internet always uses `network.interface.wan`.
- Correct false WAN warnings on AP, bridge and LAN-upstream OpenWrt topologies.

### Validated
- Real-device scan on OpenWrt 25.12.5 returned 13 pass, 0 warn, 0 fail and 1 optional skip.
- Support bundle generation completed successfully on OpenWrt 25.12.5.
- Privacy review confirmed no raw MAC address, email address or obvious SSID remained in the generated bundle.

## [0.1.0] - 2026-08-24

### Added
- Plugin-based diagnostics runner.
- System, network, DNS, DHCP, wireless, firewall and Tailscale checks.
- Privacy-focused sanitizer.
- Local support bundle generation.
- OpenWrt package Makefile.
- CI workflow and sanitizer tests.
- Contribution, security and roadmap documentation.
