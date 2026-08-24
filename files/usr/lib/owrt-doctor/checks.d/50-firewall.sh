#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if command -v fw4 >/dev/null 2>&1; then
	if fw4 check >/dev/null 2>&1; then
		emit PASS FW4_CHECK "Firewall configuration validates" "fw4 check passed"
	else
		emit FAIL FW4_CHECK "Firewall configuration validation failed" "fw4 check returned an error"
	fi
else
	emit SKIP FW4_CHECK "firewall4 validation unavailable" "fw4 missing"
fi

if [ -x /etc/init.d/firewall ]; then
	if /etc/init.d/firewall status >/dev/null 2>&1; then
		emit PASS FW_SERVICE "Firewall service is running" "service status healthy"
	else
		emit WARN FW_SERVICE "Firewall service does not report running" "inspect /etc/init.d/firewall"
	fi
else
	emit SKIP FW_SERVICE "Firewall service check unavailable" "init script missing"
fi
