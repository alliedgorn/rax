#!/bin/bash
# trim-usage.sh — Keep only the last 90 days of ~/.claude/usage.jsonl
# Runs weekly via cron. Safe to run anytime — idempotent.

set -euo pipefail

USAGE_FILE="${HOME}/.claude/usage.jsonl"
DAYS=90

if [ ! -f "$USAGE_FILE" ]; then
    echo "No usage.jsonl found at $USAGE_FILE"
    exit 0
fi

BEFORE=$(wc -l < "$USAGE_FILE")

python3 -c "
import json, sys
from datetime import datetime, timedelta

cutoff = (datetime.utcnow() - timedelta(days=${DAYS})).isoformat() + 'Z'
path = '${USAGE_FILE}'

with open(path) as f:
    lines = f.readlines()

kept = [l for l in lines if json.loads(l).get('ts', '') >= cutoff]

with open(path, 'w') as f:
    f.writelines(kept)

print(f'Trimmed: {len(lines)} -> {len(kept)} lines ({len(lines) - len(kept)} removed, cutoff {cutoff[:10]})')
"
