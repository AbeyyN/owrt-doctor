#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if command -v apk >/dev/null 2>&1; then
	emit PASS SYS_PKG_MGR "OpenWrt package manager detected" "manager=apk"
elif command -v opkg >/dev/null 2>&1; then
	emit PASS SYS_PKG_MGR "OpenWrt package manager detected" "manager=opkg"
else
	emit SKIP SYS_PKG_MGR "Package manager not detected" "neither apk nor opkg found"
fi

ntp_process=""
for proc in sysntpd ntpd chronyd; do
	if command -v pidof >/dev/null 2>&1 && pidof "$proc" >/dev/null 2>&1; then
		ntp_process="$proc"
		break
	fi
done

if [ -n "$ntp_process" ]; then
	emit PASS SYS_NTP "Time synchronization daemon is running" "process=$ntp_process"
elif command -v uci >/dev/null 2>&1 && uci -q show system 2>/dev/null | grep -q '\.server='; then
	emit WARN SYS_NTP "NTP servers are configured but no known sync daemon was detected" "checked=sysntpd,ntpd,chronyd"
else
	emit SKIP SYS_NTP "NTP daemon status unavailable" "no known time-sync daemon detected"
fi
