#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

default_route=""
default_dev=""

if command -v ip >/dev/null 2>&1; then
	default_route="$(ip route 2>/dev/null | awk '/^default / {print; exit}')"
	if [ -n "$default_route" ]; then
		default_dev="$(printf '%s\n' "$default_route" | awk '{for (i=1; i<=NF; i++) if ($i == "dev" && (i+1) <= NF) {print $(i+1); exit}}')"
		emit PASS NET_DEFAULT_ROUTE "Default route is present" "$default_route"
	else
		emit FAIL NET_DEFAULT_ROUTE "Default route is missing" "no IPv4 default route"
	fi
else
	emit SKIP NET_DEFAULT_ROUTE "Route check unavailable" "ip command missing"
fi

if command -v ubus >/dev/null 2>&1; then
	wan="$(ubus call network.interface.wan status 2>/dev/null)"
	if [ -n "$wan" ] && printf '%s\n' "$wan" | grep -Eq '"up"[[:space:]]*:[[:space:]]*true'; then
		emit PASS NET_WAN_STATUS "WAN interface reports up" "logical=wan"
	elif [ -n "$default_dev" ]; then
		upstream=""
		for service in $(ubus list 'network.interface.*' 2>/dev/null); do
			logical="${service#network.interface.}"
			status="$(ubus call "$service" status 2>/dev/null)"
			[ -n "$status" ] || continue

			if printf '%s\n' "$status" | grep -Eq '"up"[[:space:]]*:[[:space:]]*true' && \
				printf '%s\n' "$status" | grep -Eq '"(l3_device|device)"[[:space:]]*:[[:space:]]*"'"$default_dev"'"'; then
				upstream="$logical"
				break
			fi
		done

		if [ -n "$upstream" ]; then
			emit PASS NET_WAN_STATUS "Upstream path is active" "logical=$upstream device=$default_dev"
		elif [ -n "$wan" ]; then
			emit WARN NET_WAN_STATUS "WAN interface is down and upstream interface could not be mapped" "default device=$default_dev"
		else
			emit WARN NET_WAN_STATUS "WAN status is unavailable and upstream interface could not be mapped" "default device=$default_dev"
		fi
	elif [ -n "$wan" ]; then
		emit WARN NET_WAN_STATUS "WAN interface does not report up" "no active default-route device detected"
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
