---
name: diagnose-openwrt
description: Diagnose OpenWrt connectivity, routing, DNS, DHCP, Wi-Fi and topology issues using OWRT Doctor output without making router changes.
---

# Diagnose OpenWrt with OWRT Doctor

Use this workflow when the user asks to troubleshoot an OpenWrt router or access point.

1. Establish the symptom: Internet down, DNS only, Wi-Fi only, DHCP/addressing, PPPoE/upstream, or topology/bridge issue.
2. Prefer an existing `owrt-doctor scan` output or sanitized OWRT Doctor bundle text. If unavailable, call `prepare_openwrt_diagnostics` and give the user the read-only collector instructions.
3. Never ask for passwords, PSKs, tokens, cookies, private keys or other credentials.
4. Call `analyze_openwrt_diagnostics` with the diagnostic text.
5. Explain the evidence and root-cause chain in this order where applicable: physical link → interface/protocol → route → DNS → DHCP/LAN → Wi-Fi/client.
6. Do not claim a repair or configuration change happened. The plugin is diagnostic-only.
7. If suggesting a future mutation, keep it small, reversible and explicit; distinguish it from what the plugin itself performed.
8. If data is insufficient, state exactly which read-only evidence is missing instead of guessing.
