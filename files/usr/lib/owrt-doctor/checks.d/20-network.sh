#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if command -v ip >/dev/null 2>&1; then
	if ip route 2>/dev/null | grep -q '^default '; then
		route="$(ip route 2>/dev/null | awk '/^default / {print; exit}')"
		emit PASS NET_DEFAULT_ROUTE "Default route is present" "$route"
	else
		emit FAIL NET_DEFAULT_ROUTE "Default route is missing" "no IPv4 default route"
	fi
else
	emit SKIP NET_DEFAULT_ROUTE "Route check unavailable" "ip command missing"
fi

if command -v ubus >/dev/null 2>&1; then
	wan="$(ubus call network.interface.wan status 2>/dev/null)"
	if [ -n "$wan" ]; then
		if printf '%s\n' "$wan" | grep -Eq '"up"[[:space:]]*:[[:space:]]*true'; then
			emit PASS NET_WAN_STATUS "WAN interface reports up" "ubus network.interface.wan"
		else
			emit WARN NET_WAN_STATUS "WAN interface does not report up" "check interface naming or WAN state"
		fi
	else
		emit WARN NET_WAN_STATUS "WAN status is unavailable" "network.interface.wan not found"
	fi
else
	emit SKIP NET_WAN_STATUS "WAN status check unavailable" "ubus missing"
fi

if command -v ping >/dev/null 2>&1; then
	if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
		emit PASS NET_INET_RAW "Raw Internet reachability works" "1.1.1.1 reachable"
	else
		emit WARN NET_INET_RAW "Raw Internet reachability failed" "1.1.1.1 unreachable"
	fi
else
	emit SKIP NET_INET_RAW "Internet reachability check unavailable" "ping missing"
fi
