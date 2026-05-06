#!/usr/bin/env bash
# capacity-report.sh — 15-day capacity analysis for Gorn
# Pulls sar data, calculates trends, outputs a TG-ready report
# Usage: bash scripts/capacity-report.sh

set -uo pipefail

echo "=== CAPACITY ANALYSIS — $(date -u +'%Y-%m-%d %H:%M UTC') ==="
echo

# --- Disk ---
echo "## Disk"
df -h / | tail -1 | awk '{printf "Used: %s / %s (%s)\nAvailable: %s\n", $3, $2, $5, $4}'
# Growth: compare current usage to 15 days ago if du log exists
echo

# --- RAM ---
echo "## Memory"
free -h | awk 'NR==2{printf "Total: %s | Used: %s | Available: %s\n", $2, $3, $7}'
free -h | awk 'NR==3{printf "Swap: %s used / %s total\n", $3, $2}'
echo

# --- CPU (sar daily averages, last 15 days) ---
echo "## CPU Trend (daily avg, last 15 days)"
printf "%-12s %8s %8s %8s\n" "Date" "User%" "Sys%" "Idle%"
for i in $(seq 14 -1 0); do
    DATE=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
    DAY=$(date -d "$i days ago" +%d 2>/dev/null)
    # Try both sa${DAY} and sa${YYYYMMDD} (-D format)
    FILE="/var/log/sysstat/sa${DAY}"
    FILED="/var/log/sysstat/sa$(date -d "$i days ago" +%Y%m%d 2>/dev/null)"
    TARGET=""
    [ -f "$FILE" ] && TARGET="$FILE"
    [ -f "$FILED" ] && TARGET="$FILED"
    if [ -n "$TARGET" ]; then
        sar -u -f "$TARGET" 2>/dev/null | grep "Average" | awk -v d="$DATE" '{printf "%-12s %8s %8s %8s\n", d, $3, $5, $8}'
    fi
done
echo

# --- Memory trend ---
echo "## Memory Trend (daily avg %used, last 15 days)"
printf "%-12s %8s %8s\n" "Date" "Mem%" "Swap%"
for i in $(seq 14 -1 0); do
    DATE=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
    DAY=$(date -d "$i days ago" +%d 2>/dev/null)
    FILE="/var/log/sysstat/sa${DAY}"
    FILED="/var/log/sysstat/sa$(date -d "$i days ago" +%Y%m%d 2>/dev/null)"
    TARGET=""
    [ -f "$FILE" ] && TARGET="$FILE"
    [ -f "$FILED" ] && TARGET="$FILED"
    if [ -n "$TARGET" ]; then
        MEM=$(sar -r -f "$TARGET" 2>/dev/null | grep "Average" | awk '{print $5}')
        SWAP=$(sar -S -f "$TARGET" 2>/dev/null | grep "Average" | awk '{print $4}')
        printf "%-12s %8s %8s\n" "$DATE" "$MEM" "$SWAP"
    fi
done
echo

# --- Load trend ---
echo "## Load Trend (daily avg load1, last 15 days)"
printf "%-12s %8s\n" "Date" "Load1"
for i in $(seq 14 -1 0); do
    DATE=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null)
    DAY=$(date -d "$i days ago" +%d 2>/dev/null)
    FILE="/var/log/sysstat/sa${DAY}"
    FILED="/var/log/sysstat/sa$(date -d "$i days ago" +%Y%m%d 2>/dev/null)"
    TARGET=""
    [ -f "$FILE" ] && TARGET="$FILE"
    [ -f "$FILED" ] && TARGET="$FILED"
    if [ -n "$TARGET" ]; then
        sar -q -f "$TARGET" 2>/dev/null | grep "Average" | awk -v d="$DATE" '{printf "%-12s %8s\n", d, $4}'
    fi
done
echo

# --- Top processes ---
echo "## Top 5 Processes (by memory)"
ps --sort=-%mem -eo pid,user,%mem,%cpu,rss,comm | head -6
echo

# --- Den Book ---
echo "## Den Book Health"
RESP=$(curl -s -o /dev/null -w "%{http_code} %{time_total}s" http://localhost:47778/api/health 2>/dev/null)
echo "Status: $RESP"
echo

# --- Projections ---
echo "## Projections"
DISK_USED=$(df / | tail -1 | awk '{print $3}')
DISK_TOTAL=$(df / | tail -1 | awk '{print $2}')
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
DISK_80_REMAINING=$(( (DISK_TOTAL * 80 / 100 - DISK_USED) / 1024 / 1024 ))
echo "Disk headroom to 80%: ~${DISK_80_REMAINING}GB"
echo "Uptime: $(uptime -p)"
echo
echo "=== END ==="
