#!/bin/sh
emit() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; }

if [ -r /proc/uptime ]; then
	uptime_s="$(cut -d. -f1 /proc/uptime 2>/dev/null)"
	case "$uptime_s" in
		''|*[!0-9]*) emit WARN SYS_UPTIME "Unable to parse system uptime" "unexpected /proc/uptime" ;;
		*)
			if [ "$uptime_s" -lt 120 ]; then
				emit WARN SYS_UPTIME "System was recently booted" "${uptime_s}s"
			else
				emit PASS SYS_UPTIME "System uptime is healthy" "${uptime_s}s"
			fi ;;
	esac
else
	emit SKIP SYS_UPTIME "System uptime unavailable" "/proc/uptime missing"
fi

if command -v df >/dev/null 2>&1; then
	used="$(df -P / 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')"
	case "$used" in
		''|*[!0-9]*) emit WARN SYS_STORAGE "Unable to determine root filesystem usage" "" ;;
		*)
			if [ "$used" -ge 95 ]; then
				emit FAIL SYS_STORAGE "Root filesystem is critically full" "${used}% used"
			elif [ "$used" -ge 85 ]; then
				emit WARN SYS_STORAGE "Root filesystem is getting full" "${used}% used"
			else
				emit PASS SYS_STORAGE "Root filesystem usage is healthy" "${used}% used"
			fi ;;
	esac
else
	emit SKIP SYS_STORAGE "Filesystem usage check unavailable" "df missing"
fi

if [ -r /proc/meminfo ]; then
	mem_kb="$(awk '/^MemAvailable:/ {print $2; found=1; exit} /^MemFree:/ {fallback=$2} END {if (!found && fallback) print fallback}' /proc/meminfo 2>/dev/null | head -n1)"
	case "$mem_kb" in
		''|*[!0-9]*) emit WARN SYS_MEMORY "Unable to determine available memory" "" ;;
		*)
			mem_mb=$((mem_kb / 1024))
			if [ "$mem_mb" -lt 4 ]; then
				emit FAIL SYS_MEMORY "Available memory is critically low" "${mem_mb} MiB"
			elif [ "$mem_mb" -lt 12 ]; then
				emit WARN SYS_MEMORY "Available memory is low" "${mem_mb} MiB"
			else
				emit PASS SYS_MEMORY "Available memory is healthy" "${mem_mb} MiB"
			fi ;;
	esac
else
	emit SKIP SYS_MEMORY "Memory check unavailable" "/proc/meminfo missing"
fi

year="$(date +%Y 2>/dev/null)"
case "$year" in
	''|*[!0-9]*) emit WARN SYS_CLOCK "Unable to read system clock" "" ;;
	*)
		if [ "$year" -lt 2024 ]; then
			emit FAIL SYS_CLOCK "System clock appears invalid" "year=$year"
		else
			emit PASS SYS_CLOCK "System clock appears sane" "year=$year"
		fi ;;
esac
