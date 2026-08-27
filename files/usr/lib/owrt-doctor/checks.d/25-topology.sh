#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

default_dev=""
default_logical=""
wan_up=0

if command -v ip >/dev/null 2>&1; then
	default_route="$(ip route 2>/dev/null | awk '/^default / {print; exit}')"
	if [ -n "$default_route" ]; then
		default_dev="$(printf '%s\n' "$default_route" | awk '{for (i=1; i<=NF; i++) if ($i == "dev" && (i+1) <= NF) {print $(i+1); exit}}')"
	fi
else
	default_route=""
fi

if command -v ubus >/dev/null 2>&1; then
	wan="$(ubus call network.interface.wan status 2>/dev/null)"
	if [ -n "$wan" ] && printf '%s\n' "$wan" | grep -Eq '"up"[[:space:]]*:[[:space:]]*true'; then
		wan_up=1
	fi

	if [ -n "$default_dev" ]; then
		for service in $(ubus list 'network.interface.*' 2>/dev/null); do
			logical="${service#network.interface.}"
			status="$(ubus call "$service" status 2>/dev/null)"
			[ -n "$status" ] || continue
			if printf '%s\n' "$status" | grep -Eq '"up"[[:space:]]*:[[:space:]]*true' && \
				printf '%s\n' "$status" | grep -Eq '"(l3_device|device)"[[:space:]]*:[[:space:]]*"'"$default_dev"'"'; then
				default_logical="$logical"
				break
			fi
		done
	fi
fi

sta_present=0
ap_present=0
lan_dhcp_ignore=""
if command -v uci >/dev/null 2>&1; then
	wireless_cfg="$(uci -q show wireless 2>/dev/null)"
	printf '%s\n' "$wireless_cfg" | grep -q "\.mode='sta'" && sta_present=1
	printf '%s\n' "$wireless_cfg" | grep -q "\.mode='ap'" && ap_present=1
	lan_dhcp_ignore="$(uci -q get dhcp.lan.ignore 2>/dev/null || true)"
fi

if [ "$wan_up" -eq 1 ]; then
	emit PASS NET_TOPOLOGY "Router topology detected" "mode=router upstream=wan"
elif [ "$default_logical" = "lan" ]; then
	if [ "$sta_present" -eq 1 ] && [ "$ap_present" -eq 1 ]; then
		emit PASS NET_TOPOLOGY "Wireless repeater/bridge topology detected" "mode=repeater-bridge upstream=lan device=$default_dev"
	elif [ "$lan_dhcp_ignore" = "1" ]; then
		emit PASS NET_TOPOLOGY "Access point/bridge topology detected" "mode=ap-bridge upstream=lan device=$default_dev"
	else
		emit PASS NET_TOPOLOGY "LAN-upstream topology detected" "mode=lan-upstream upstream=lan device=$default_dev"
	fi
elif [ -n "$default_logical" ]; then
	emit PASS NET_TOPOLOGY "Custom upstream topology detected" "mode=custom upstream=$default_logical device=$default_dev"
elif [ -n "$default_dev" ]; then
	emit WARN NET_TOPOLOGY "Default route exists but topology could not be classified" "device=$default_dev"
else
	emit WARN NET_TOPOLOGY "Topology could not be classified" "no mapped default-route interface"
fi

if command -v ip >/dev/null 2>&1; then
	ipv6_global="$(ip -6 addr show scope global 2>/dev/null | awk '/inet6 / {print $2; exit}')"
	ipv6_default="$(ip -6 route 2>/dev/null | awk '/^default / {print; exit}')"
	if [ -n "$ipv6_global" ] && [ -n "$ipv6_default" ]; then
		emit PASS NET_IPV6 "IPv6 addressing and default route are present" "address=$ipv6_global"
	elif [ -n "$ipv6_global" ]; then
		emit WARN NET_IPV6 "Global IPv6 address exists without a default IPv6 route" "address=$ipv6_global"
	elif [ -n "$ipv6_default" ]; then
		emit WARN NET_IPV6 "IPv6 default route exists without a global IPv6 address" "$ipv6_default"
	else
		emit SKIP NET_IPV6 "IPv6 is not configured" "no global IPv6 address or default route"
	fi
else
	emit SKIP NET_IPV6 "IPv6 check unavailable" "ip command missing"
fi
