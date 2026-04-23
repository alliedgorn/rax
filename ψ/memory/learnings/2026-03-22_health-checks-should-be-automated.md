# Lesson: Health checks should be automated alerts, not LLM polling

**Date**: 2026-03-22
**Source**: Day 8 — 24h watchkeeper session

## Pattern

Running `free -h && uptime && df -h` every hour via scheduler trigger consumes LLM context for a task that a 5-line bash script on a cron job could handle. In 18 health checks across 24 hours, zero required intervention. The raccoon was tapping walls that never cracked.

## Better Pattern

- Cron job runs health check every hour
- Script only alerts (Telegram or forum post) if thresholds are crossed:
  - RAM > 12G (80%)
  - Disk > 80%
  - Load > 10 sustained
  - Swap > 1G
  - Den Book API non-200
- LLM context stays free for actual infrastructure work

## Status

Proposal — needs Gorn approval before implementing.
