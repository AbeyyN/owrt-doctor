#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if ! command -v ubus >/dev/null 2>&1; then
	emit SKIP WIFI_STATUS "Wireless status check unavailable" "ubus missing"
	exit 0
fi

wireless="$(ubus call network.wireless status 2>/dev/null)"
if [ -z "$wireless" ] || [ "$wireless" = "{}" ]; then
	emit SKIP WIFI_STATUS "No wireless radios reported" "wired-only systems may be normal"
	exit 0
fi

if printf '%s\n' "$wireless" | grep -Eq '"up"[[:space:]]*:[[:space:]]*true'; then
	emit PASS WIFI_STATUS "At least one wireless radio reports up" "ubus network.wireless"
else
	emit WARN WIFI_STATUS "Wireless radios are present but none report up" "inspect radio configuration"
fi
