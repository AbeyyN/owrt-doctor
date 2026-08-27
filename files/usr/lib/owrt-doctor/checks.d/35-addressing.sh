#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if [ -r /tmp/dhcp.leases ]; then
	dup_ip="$(awk 'NF >= 3 {count[$3]++} END {for (ip in count) if (count[ip] > 1) {print ip; exit}}' /tmp/dhcp.leases 2>/dev/null)"
	dup_mac="$(awk 'NF >= 3 {mac=tolower($2); if (seen[mac] != "" && seen[mac] != $3) {print mac; exit} seen[mac]=$3}' /tmp/dhcp.leases 2>/dev/null)"

	if [ -n "$dup_ip" ]; then
		emit WARN DHCP_DUPLICATES "Duplicate IP appears in DHCP lease database" "ip=$dup_ip"
	elif [ -n "$dup_mac" ]; then
		emit WARN DHCP_DUPLICATES "One DHCP client appears with multiple IP addresses" "mac=$dup_mac"
	else
		emit PASS DHCP_DUPLICATES "No duplicate DHCP lease addresses detected" "lease database clean"
	fi
else
	emit SKIP DHCP_DUPLICATES "Duplicate DHCP lease check unavailable" "/tmp/dhcp.leases missing or unreadable"
fi

if command -v uci >/dev/null 2>&1; then
	static_dup="$(uci -q show dhcp 2>/dev/null | awk -F= '/\.ip=/{gsub(/^\047|\047$/, "", $2); count[$2]++} END {for (ip in count) if (ip != "" && count[ip] > 1) {print ip; exit}}')"
	if [ -n "$static_dup" ]; then
		emit WARN DHCP_STATIC_DUP "Duplicate static DHCP address is configured" "ip=$static_dup"
	else
		emit PASS DHCP_STATIC_DUP "No duplicate static DHCP addresses detected" "UCI dhcp configuration"
	fi
else
	emit SKIP DHCP_STATIC_DUP "Static DHCP duplicate check unavailable" "uci missing"
fi
