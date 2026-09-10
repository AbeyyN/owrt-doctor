import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { setTimeout as sleep } from "node:timers/promises";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const port = 18787;
const base = `http://127.0.0.1:${port}`;
const proc = spawn(process.execPath, ["server.js"], {
  cwd: new URL("..", import.meta.url),
  env: { ...process.env, PORT: String(port) },
  stdio: ["ignore", "pipe", "pipe"],
});

async function waitForHealth() {
  for (let i = 0; i < 50; i += 1) {
    try {
      const r = await fetch(`${base}/healthz`);
      if (r.ok && (await r.text()) === "ok") return;
    } catch {}
    await sleep(100);
  }
  throw new Error("server health check timed out");
}

try {
  await waitForHealth();
  const client = new Client({ name: "owrt-doctor-smoke", version: "0.1.0" });
  const transport = new StreamableHTTPClientTransport(new URL(`${base}/mcp`));
  await client.connect(transport);

  const listed = await client.listTools();
  const names = listed.tools.map((tool) => tool.name).sort();
  assert.deepEqual(names, ["analyze_openwrt_diagnostics", "owrt_doctor_capabilities", "prepare_openwrt_diagnostics"]);

  const caps = await client.callTool({ name: "owrt_doctor_capabilities", arguments: {} });
  assert.equal(caps.structuredContent.pluginVersion, "0.1.0");
  assert.equal(caps.structuredContent.mode, "Read-only diagnostics");

  const analysis = await client.callTool({
    name: "analyze_openwrt_diagnostics",
    arguments: {
      diagnostics: "OWRT Doctor v0.2.0\n[PASS] system uptime ok\n[FAIL] default route missing\n===== IPV4 ROUTES =====\n192.168.1.0/24 dev br-lan scope link\n",
    },
  });
  assert.ok(analysis.structuredContent.findings.some((f) => f.severity === "critical"));
  assert.equal(analysis.structuredContent.detected.owrtDoctorStatusCounts.fail, 1);

  const prep = await client.callTool({ name: "prepare_openwrt_diagnostics", arguments: {} });
  assert.ok(prep.structuredContent.fallbackCollector.includes("READ-ONLY"));
  assert.ok(!prep.structuredContent.fallbackCollector.includes("uci set"));

  await client.close();
  console.log("MCP_SMOKE_OK");
} finally {
  proc.kill("SIGTERM");
}
