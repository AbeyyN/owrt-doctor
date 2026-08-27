#!/bin/sh
set -eu

ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
DOCTOR="$ROOT/files/usr/bin/owrt-doctor"
fail=0

assert_not_contains() {
	haystack="$1"; needle="$2"; name="$3"
	if printf '%s\n' "$haystack" | grep -Fq "$needle"; then
		echo "FAIL: $name"; fail=$((fail + 1))
	else
		echo "PASS: $name"
	fi
}

assert_contains() {
	haystack="$1"; needle="$2"; name="$3"
	if printf '%s\n' "$haystack" | grep -Fq "$needle"; then
		echo "PASS: $name"
	else
		echo "FAIL: $name"; fail=$((fail + 1))
	fi
}

sample="wireless.radio0.key='supersecret'
wireless.default_radio0.ssid='MyHomeWifi'
peer=AA:BB:CC:DD:EE:FF
email=person@example.com
network.lan.ipaddr='192.168.1.1'"

sanitized="$(printf '%s\n' "$sample" | sh "$DOCTOR" sanitize)"

assert_not_contains "$sanitized" "supersecret" "redacts UCI key"
assert_not_contains "$sanitized" "MyHomeWifi" "redacts SSID"
assert_not_contains "$sanitized" "AA:BB:CC:DD:EE:FF" "redacts MAC address"
assert_not_contains "$sanitized" "person@example.com" "redacts email-like identifier"
assert_contains "$sanitized" "192.168.1.1" "retains useful private IP context"
assert_contains "$(sh "$DOCTOR" version)" "0.1.1" "reports version"

if [ "$fail" -ne 0 ]; then
	echo "$fail test(s) failed"
	exit 1
fi
echo "All tests passed"
