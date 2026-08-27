# Changelog

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
