# OWRT Doctor ChatGPT Plugin

Component version: **v0.1.0**  
Core project baseline: **OWRT Doctor v0.2.x**

This directory adds a ChatGPT/Codex plugin layer to the existing OWRT Doctor project without changing the OpenWrt CLI/package behavior.

## Scope

- Stateless Streamable HTTP MCP endpoint at `/mcp`.
- Read-only diagnostic preparation and analysis.
- Understands native OWRT Doctor `[PASS]`, `[WARN]`, `[FAIL]` output plus common raw OpenWrt diagnostics.
- No direct SSH to user routers.
- No UCI writes, package installation, service restart, firewall mutation or reboot.

## Tools

- `owrt_doctor_capabilities`
- `prepare_openwrt_diagnostics`
- `analyze_openwrt_diagnostics`

## Run

```bash
cd plugins/owrt-doctor-chatgpt
npm install
npm run check
npm test
npm start
```

Local endpoints:

- Health: `http://127.0.0.1:8787/healthz`
- MCP: `http://127.0.0.1:8787/mcp`

Production publication requires a stable public HTTPS `/mcp` endpoint and registration in ChatGPT developer mode before the plugin package can reference the registered MCP server.
