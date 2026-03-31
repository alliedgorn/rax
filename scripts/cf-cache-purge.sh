#!/bin/bash
# Cloudflare cache purge script for denbook.online
# Reads CF API token from ~/.cf-token (not committed to git)
# Usage: bash scripts/cf-cache-purge.sh

set -euo pipefail

ZONE_ID="edfb5803457b43020246945840ec4d1c"
TOKEN_FILE="$HOME/.cf-token"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: CF API token not found at $TOKEN_FILE"
    echo "Create it with: echo 'your-cf-api-token' > ~/.cf-token && chmod 600 ~/.cf-token"
    exit 1
fi

CF_TOKEN=$(cat "$TOKEN_FILE" | tr -d '[:space:]')

echo "Purging Cloudflare cache for denbook.online..."
RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/purge_cache" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"purge_everything":true}')

SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success', False))" 2>/dev/null || echo "false")

if [ "$SUCCESS" = "True" ]; then
    echo "Cache purged successfully."
else
    echo "Cache purge failed:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 1
fi
