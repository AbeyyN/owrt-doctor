import cors from "cors";
import express from "express";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { z } from "zod";

const SERVER_VERSION = "0.1.0";
const PORT = Number(process.env.PORT ?? 8787);
const MCP_PATH = "/mcp";

const severitySchema = z.enum(["info", "warning", "critical"]);
const findingSchema = z.object({
  id: z.string(),
  severity: severitySchema,
  title: z.string(),
  evidence: z.array(z.string()),
  recommendation: z.string(),
});

const safeCollector = String.raw`#!/bin/sh
# OWRT Doctor ChatGPT fallback collector v0.1.0
# READ-ONLY: no UCI writes, package installs, service restarts, reboots, or firewall changes.

redact() {
  sed -E \
    -e "s/((password|passwd|psk|key|token|secret|private_key|auth)[^=]*=).*/\\1'[REDACTED]'/Ig" \
    -e 's/(Authorization:).*/\\1 [REDACTED]/Ig'
}

section() { printf '\n===== %s =====\n' "$1"; }

section "BOARD"
ubus call system board 2>/dev/null || true
section "SYSTEM"
ubus call system info 2>/dev/null || true
uname -a 2>/dev/null || true
section "INTERFACES"
ubus call network.interface dump 2>/dev/null | redact || true
section "IPV4 ROUTES"
ip -4 route show 2>/dev/null || true
section "DNS"
cat /tmp/resolv.conf.d/resolv.conf.auto 2>/dev/null || true
cat /tmp/resolv.conf.auto 2>/dev/null || true
section "NETWORK UCI"
uci -q show network 2>/dev/null | redact || true
section "DHCP UCI"
uci -q show dhcp 2>/dev/null | redact || true
section "WIRELESS UCI"
uci -q show wireless 2>/dev/null | redact || true
section "FIREWALL ZONES"
uci -q show firewall 2>/dev/null | grep -E "(@zone|\\.name=|\\.network=|\\.input=|\\.output=|\\.forward=|@forwarding)" | redact || true
section "RECENT NETWORK LOGS"
logread 2>/dev/null | grep -Ei "dnsmasq|odhcp|netifd|wan|dhcp|pppoe|dns|wifi|wlan" | tail -n 250 | redact || true
printf '\n===== OWRT DOCTOR FALLBACK END =====\n'
`;

function lineEvidence(text, pattern, max = 4) {
  return text
    .split(/\r?\n/)
    .filter((line) => pattern.test(line))
    .slice(0, max)
    .map((line) => line.replace(/\s+/g, " ").trim().slice(0, 300));
}

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function firstMatch(text, regex) {
  const match = text.match(regex);
  return match?.[1]?.trim();
}

function redactDiagnosticText(input) {
  return input
    .replace(/((?:password|passwd|psk|token|secret|private[_-]?key|authorization)\s*[:=]\s*)([^\s'"\n]+)/gi, "$1[REDACTED]")
    .replace(/(Authorization:\s*)([^\r\n]+)/gi, "$1[REDACTED]");
}

function analyzeDiagnostics(input) {
  const text = redactDiagnosticText(input);
  const findings = [];

  const statusLines = [...text.matchAll(/^\s*\[(PASS|WARN|FAIL)\]\s*(.+)$/gim)].map((m) => ({
    status: m[1].toUpperCase(),
    message: m[2].trim(),
  }));
  const fails = statusLines.filter((x) => x.status === "FAIL");
  const warns = statusLines.filter((x) => x.status === "WARN");

  if (fails.length) {
    findings.push({
      id: "owrt-doctor-failures",
      severity: "critical",
      title: `${fails.length} OWRT Doctor FAIL result(s)`,
      evidence: fails.slice(0, 6).map((x) => `[FAIL] ${x.message}`),
      recommendation: "Resolve FAIL results from the network path outward: physical/upstream link, interface state, route, then DNS. Avoid unrelated configuration changes until the failing layer is identified.",
    });
  }

  if (warns.length) {
    findings.push({
      id: "owrt-doctor-warnings",
      severity: "warning",
      title: `${warns.length} OWRT Doctor WARN result(s)`,
      evidence: warns.slice(0, 6).map((x) => `[WARN] ${x.message}`),
      recommendation: "Review warnings after critical failures are resolved. Treat topology-specific warnings as informational when the detected topology intentionally omits a conventional WAN interface.",
    });
  }

  const defaultRoute = /(^|\n)default\s+via\s+/im.test(text) || /default route[^\n]*(?:pass|ok|present)/i.test(text);
  const routeSectionPresent = /=====\s*ipv4 routes\s*=====|=====\s*routes\s*=====|default route/i.test(text);
  if (routeSectionPresent && !defaultRoute && !statusLines.some((x) => /default route/i.test(x.message) && x.status === "PASS")) {
    findings.push({
      id: "missing-default-route",
      severity: "critical",
      title: "No usable IPv4 default route detected",
      evidence: lineEvidence(text, /default route|^default\s+/i),
      recommendation: "Verify the active upstream interface, protocol state, gateway and any intentional policy-routing design before changing DNS.",
    });
  }

  const dnsErrors = lineEvidence(text, /dnsmasq.*(?:failed|error|no servers|refused|timeout)|server misbehaving|temporary failure in name resolution/i, 6);
  if (dnsErrors.length) {
    findings.push({
      id: "dns-errors",
      severity: "warning",
      title: "DNS-related errors detected",
      evidence: dnsErrors,
      recommendation: "Check upstream resolver reachability and dnsmasq forwarding. If routing is also failing, repair routing first.",
    });
  }

  const pppoeErrors = lineEvidence(text, /ppp(?:oe|d).*(?:timeout|terminated|authentication failed|no response|lcp.*closed)/i, 6);
  if (pppoeErrors.length) {
    findings.push({
      id: "pppoe-failure",
      severity: "critical",
      title: "PPPoE session failure indicators detected",
      evidence: pppoeErrors,
      recommendation: "Verify link, ISP VLAN and PPPoE credentials/state. Do not rotate unrelated LAN or DNS settings while authentication/session establishment is failing.",
    });
  }

  const duplicateErrors = lineEvidence(text, /duplicate (?:address|ip)|address conflict|arp.*duplicate|duplicate.*dhcp/i, 6);
  if (duplicateErrors.length) {
    findings.push({
      id: "address-conflict",
      severity: "critical",
      title: "Possible duplicate IP or DHCP conflict detected",
      evidence: duplicateErrors,
      recommendation: "Identify competing address assignments or DHCP servers. Keep infrastructure static addresses outside the dynamic pool or use explicit reservations.",
    });
  }

  const wifiErrors = lineEvidence(text, /(?:hostapd|wlan|wifi).*(?:deauth|disassoc|failed|timeout|radar|dfs|no ack|beacon loss)/i, 6);
  if (wifiErrors.length) {
    findings.push({
      id: "wifi-instability",
      severity: "warning",
      title: "Wi-Fi instability indicators detected",
      evidence: wifiErrors,
      recommendation: "Correlate timestamps with the affected radio/client. Check DFS events, channel congestion, signal quality and roaming before touching WAN settings.",
    });
  }

  const model = firstMatch(text, /"model"\s*:\s*"([^"]+)"/i);
  const hostname = firstMatch(text, /"hostname"\s*:\s*"([^"]+)"/i);
  const kernel = firstMatch(text, /"kernel"\s*:\s*"([^"]+)"/i) || firstMatch(text, /Linux\s+\S+\s+([^\s]+)/i);
  const dnsServers = unique([...text.matchAll(/\bnameserver\s+((?:\d{1,3}\.){3}\d{1,3})\b/gi)].map((m) => m[1])).slice(0, 10);

  if (!findings.length) {
    findings.push({
      id: "no-obvious-fault",
      severity: "info",
      title: "No obvious fault matched the v0.1 rules",
      evidence: [],
      recommendation: "Describe the exact symptom and affected clients, and include a complete `owrt-doctor scan` output or sanitized support bundle text for contextual diagnosis.",
    });
  }

  const criticalCount = findings.filter((f) => f.severity === "critical").length;
  const warningCount = findings.filter((f) => f.severity === "warning").length;
  const source = /\bOWRT Doctor\b|\[(?:PASS|WARN|FAIL)\]/i.test(text)
    ? "owrt-doctor"
    : /\bOpenWrt\b|\bubus\b|\buci\b|\bdnsmasq\b/i.test(text)
      ? "openwrt-raw"
      : "unknown";

  return {
    source,
    summary: criticalCount
      ? `${criticalCount} critical and ${warningCount} warning finding group(s) detected.`
      : warningCount
        ? `${warningCount} warning finding group(s) detected; no critical rule matched.`
        : "No critical or warning rule matched the supplied diagnostics.",
    findings,
    detected: {
      ...(model ? { model } : {}),
      ...(hostname ? { hostname } : {}),
      ...(kernel ? { kernel } : {}),
      defaultRoute,
      dnsServers,
      owrtDoctorStatusCounts: {
        pass: statusLines.filter((x) => x.status === "PASS").length,
        warn: warns.length,
        fail: fails.length,
      },
    },
  };
}

function createMcpServer() {
  const server = new McpServer(
    { name: "owrt-doctor-chatgpt", version: SERVER_VERSION },
    {
      instructions: [
        "OWRT Doctor is a read-only OpenWrt diagnostic assistant.",
        "Prefer existing `owrt-doctor scan` or sanitized bundle output when available.",
        "Never claim that a router configuration change was performed by this plugin.",
        "Never request passwords, Wi-Fi PSKs, tokens, cookies, private keys, or other secrets.",
        "Prioritize root cause before suggesting configuration changes.",
      ].join(" "),
    },
  );

  server.registerTool(
    "owrt_doctor_capabilities",
    {
      title: "Show OWRT Doctor capabilities",
      description: "Use when the user asks what OWRT Doctor can diagnose, its supported platform, current plugin version, or safety limits.",
      inputSchema: {},
      outputSchema: {
        pluginVersion: z.string(),
        coreBaseline: z.string(),
        supportedPlatforms: z.array(z.string()),
        mode: z.string(),
        limits: z.array(z.string()),
      },
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false },
    },
    async () => {
      const data = {
        pluginVersion: SERVER_VERSION,
        coreBaseline: "OWRT Doctor v0.2.x",
        supportedPlatforms: ["OpenWrt 24.10", "OpenWrt 25.12+"],
        mode: "Read-only diagnostics",
        limits: [
          "No direct SSH connection to user routers.",
          "No UCI writes, package installation, service restart, firewall mutation, or reboot.",
          "The plugin analyzes text explicitly supplied by the user.",
        ],
      };
      return { structuredContent: data, content: [{ type: "text", text: "OWRT Doctor ChatGPT plugin v0.1.0 provides read-only OpenWrt diagnostic analysis." }] };
    },
  );

  server.registerTool(
    "prepare_openwrt_diagnostics",
    {
      title: "Prepare OpenWrt diagnostics",
      description: "Use when a user wants safe commands to collect OpenWrt diagnostic data for OWRT Doctor. Returns preferred OWRT Doctor commands plus a read-only fallback collector script; it does not execute them.",
      inputSchema: {},
      outputSchema: {
        preferredCommands: z.array(z.string()),
        fallbackCollector: z.string(),
        safety: z.string(),
      },
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false },
    },
    async () => {
      const data = {
        preferredCommands: ["owrt-doctor scan", "owrt-doctor bundle"],
        fallbackCollector: safeCollector,
        safety: "Read-only collection only. Review output before sharing; do not include credentials or private keys.",
      };
      return {
        structuredContent: data,
        content: [{ type: "text", text: "Prepared read-only OpenWrt diagnostic collection commands. Prefer `owrt-doctor scan`; use the fallback collector only when OWRT Doctor is not installed." }],
      };
    },
  );

  server.registerTool(
    "analyze_openwrt_diagnostics",
    {
      title: "Analyze OpenWrt diagnostics",
      description: "Use when the user provides OWRT Doctor scan output, sanitized support-bundle text, or OpenWrt network logs/configuration and wants likely root causes with prioritized next steps.",
      inputSchema: { diagnostics: z.string().min(20).max(150000) },
      outputSchema: {
        source: z.string(),
        summary: z.string(),
        findings: z.array(findingSchema),
        detected: z.object({
          model: z.string().optional(),
          hostname: z.string().optional(),
          kernel: z.string().optional(),
          defaultRoute: z.boolean(),
          dnsServers: z.array(z.string()),
          owrtDoctorStatusCounts: z.object({ pass: z.number(), warn: z.number(), fail: z.number() }),
        }),
      },
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false },
    },
    async ({ diagnostics }) => {
      const result = analyzeDiagnostics(diagnostics);
      return {
        structuredContent: result,
        content: [{ type: "text", text: `${result.summary} Highest-priority finding: ${result.findings[0]?.title ?? "none"}.` }],
      };
    },
  );

  return server;
}

const app = express();
app.use(cors({ origin: true, exposedHeaders: ["Mcp-Session-Id"] }));
app.use(express.json({ limit: "512kb" }));

app.get("/", (_req, res) => {
  res.json({ name: "OWRT Doctor ChatGPT Plugin", version: SERVER_VERSION, status: "ok", mcp: MCP_PATH, mode: "read-only" });
});
app.get("/healthz", (_req, res) => res.type("text/plain").send("ok"));

app.all(MCP_PATH, async (req, res) => {
  const server = createMcpServer();
  const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
  res.on("close", () => {
    transport.close().catch(() => {});
    server.close().catch(() => {});
  });
  try {
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  } catch (error) {
    console.error("MCP request failed", error);
    if (!res.headersSent) {
      res.status(500).json({ jsonrpc: "2.0", error: { code: -32603, message: "Internal server error" }, id: null });
    }
  }
});

const httpServer = app.listen(PORT, "0.0.0.0", () => {
  console.log(`OWRT Doctor ChatGPT Plugin v${SERVER_VERSION} listening on :${PORT}${MCP_PATH}`);
});

function shutdown() {
  httpServer.close(() => process.exit(0));
}
process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
