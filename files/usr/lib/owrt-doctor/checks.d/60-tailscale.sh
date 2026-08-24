#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if ! command -v tailscale >/dev/null 2>&1; then
	emit SKIP TS_CLIENT "Tailscale is not installed" "optional integration"
	exit 0
fi

if command -v pidof >/dev/null 2>&1 && pidof tailscaled >/dev/null 2>&1; then
	emit PASS TS_DAEMON "tailscaled is running" "process detected"
else
	emit WARN TS_DAEMON "tailscaled process not detected" "client exists but daemon may be stopped"
fi

if tailscale status >/dev/null 2>&1; then
	emit PASS TS_STATUS "Tailscale status is available" "client can query local daemon"
else
	emit WARN TS_STATUS "Tailscale status query failed" "run tailscale status manually"
fi
