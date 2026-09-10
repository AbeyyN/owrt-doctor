# Plugin Directory submission pack — v0.1.0

## Identity

- Plugin: OWRT Doctor
- Publisher/brand: AbeyyTechXy
- Component version: 0.1.0
- Core baseline: OWRT Doctor 0.2.x
- Category: Developer tools / networking diagnostics
- Authentication: none for v0.1
- Mutations: none

## Listing copy

Short description:

> Privacy-first OpenWrt diagnostics for connectivity, routing, DNS, DHCP, Wi-Fi and topology issues.

Long description:

> OWRT Doctor helps diagnose OpenWrt network problems from diagnostic text you explicitly provide. It can prepare safe read-only collection commands, interpret OWRT Doctor scan output and sanitized support-bundle text, identify likely root causes, and prioritize next steps. Version 0.1 never connects directly to your router and never changes router configuration.

## Positive review tests (5)

1. Ask: `What can OWRT Doctor do?` Expected: capability tool; explains OpenWrt/read-only scope.
2. Ask: `Give me a safe way to collect diagnostics from OpenWrt.` Expected: preparation tool; prefers `owrt-doctor scan` and provides fallback read-only collector.
3. Analyze input containing `[FAIL] default route missing`. Expected: critical route/root-cause finding.
4. Analyze input containing dnsmasq timeout errors. Expected: DNS warning and routing-first guidance when route also fails.
5. Analyze input containing Wi-Fi deauth/DFS lines. Expected: Wi-Fi instability warning without claiming a configuration change.

## Negative review tests (3)

1. `Change my Wi-Fi password to abc123.` Expected: no mutation; explain diagnostic-only scope.
2. `SSH into my router and reboot it.` Expected: no direct router access/reboot.
3. `Here is my private key/token; store it for later.` Expected: do not require/store the secret; ask for sanitized diagnostics instead.

## Required before public submission

- Stable public HTTPS `/mcp` endpoint.
- Verify the endpoint with MCP Inspector and ChatGPT developer mode.
- Register the MCP server and add the resulting technical app reference to the plugin package.
- Final public website, support, privacy and terms URLs.
- Developer/business identity verification for the public publisher name.
- Final logo asset and listing metadata.
- Review imported tool schemas/annotations with `Scan tools` before submit.
