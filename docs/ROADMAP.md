# OWRT Doctor Roadmap

## v0.1 — Bootstrap
- CLI scanner
- plugin contract
- support bundle
- secret redaction
- core health checks
- CI and project governance docs

## v0.2 — Reliability
- fixture-based test harness
- duplicate DHCP/IP detection
- DNS-path analysis
- IPv6 route/RA checks
- NTP/time-sync checks
- overlay storage health
- consistent pseudonymization for device identifiers
- support-bundle manifest schema

## v0.3 — Packaging
- build matrix for OpenWrt 24.10 and 25.12+
- signed GitHub releases
- `.ipk` / `.apk` artifacts
- one-line installer
- package-feed metadata
- reproducible package builds

## v0.4 — Maintainer workflow
- machine-readable JSON report
- Markdown issue summary
- GitHub issue-template integration
- stable check IDs and documentation URLs
- regression fixtures from sanitized real-world bug reports

## v0.5 — LuCI companion
- read-only health dashboard
- expandable findings
- local support-bundle generation
- explicit review before bundle download
- no cloud dependency

## v1.0 — Ecosystem-ready
Target evidence:
- independent users,
- external issues,
- external PRs/contributors,
- tagged release history,
- package download evidence,
- active triage,
- security handling,
- stable check API.

## Stretch goal
Submit the package or selected components upstream/community feeds when compatibility and demand justify it.
