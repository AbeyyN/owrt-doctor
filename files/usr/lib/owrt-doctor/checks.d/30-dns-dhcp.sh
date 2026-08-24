#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if command -v nslookup >/dev/null 2>&1; then
	if nslookup openwrt.org >/dev/null 2>&1; then
		emit PASS DNS_RESOLVE "DNS resolution works" "openwrt.org resolved"
	else
		emit WARN DNS_RESOLVE "DNS resolution failed" "openwrt.org did not resolve"
	fi
else
	emit SKIP DNS_RESOLVE "DNS resolution check unavailable" "nslookup missing"
fi

if command -v pidof >/dev/null 2>&1; then
	if pidof dnsmasq >/dev/null 2>&1; then
		emit PASS DHCP_DNSMASQ "dnsmasq is running" "process detected"
	else
		emit WARN DHCP_DNSMASQ "dnsmasq process not detected" "may be normal with a different DHCP/DNS stack"
	fi
else
	emit SKIP DHCP_DNSMASQ "dnsmasq process check unavailable" "pidof missing"
fi

if [ -r /tmp/dhcp.leases ]; then
	leases="$(awk 'NF >= 4 {n++} END {print n+0}' /tmp/dhcp.leases 2>/dev/null)"
	emit PASS DHCP_LEASES "DHCP lease database is readable" "${leases} lease(s)"
else
	emit SKIP DHCP_LEASES "DHCP lease database is unavailable" "/tmp/dhcp.leases missing or unreadable"
fi
