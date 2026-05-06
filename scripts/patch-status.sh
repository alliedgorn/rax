#!/bin/bash
# Weekly patch status report — posts to Den Book forum thread #285
# Checks OS packages, Caddy, Meilisearch, Bun, certbot, TLS
# Posts as reply in thread #285 (Patch Management Process consultation) — canonical home.

set -euo pipefail

UPDATES=$(apt list --upgradable 2>/dev/null | grep -v "^Listing" | grep -c "upgradable" || echo "0")
SECURITY=$(apt list --upgradable 2>/dev/null | grep -ic "security" || echo "0")
KERNEL=$(uname -r)

CADDY=$(caddy version 2>/dev/null | awk '{print $1}' || echo "not installed")

MEILI=$(meilisearch --version 2>/dev/null | head -1 || echo "not installed")
MEILI_KEY=$(grep MEILI_MASTER_KEY /home/gorn/.oracle/.env 2>/dev/null | cut -d= -f2 || echo "")
MEILI_HEALTH=$(curl -sf -H "Authorization: Bearer $MEILI_KEY" http://127.0.0.1:7700/health 2>/dev/null || echo '{"status":"down"}')

BUN=$(bun --version 2>/dev/null || echo "not installed")

CERT=$(echo | openssl s_client -connect denbook.online:443 -servername denbook.online 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "unknown")

UPTIME=$(uptime -p)
DATE=$(date -u +"%Y-%m-%d")

# Build JSON body safely with python so embedded newlines + markdown table escape correctly.
python3 <<PYEOF
import json, urllib.request, sys

msg = """## Weekly Patch Status — ${DATE}

| Component | Version / Status |
|---|---|
| **OS packages** | ${UPDATES} upgradable (**${SECURITY} security**) |
| **Kernel** | ${KERNEL} |
| **Caddy** | ${CADDY} |
| **Meilisearch** | ${MEILI} — ${MEILI_HEALTH} |
| **Bun** | ${BUN} |
| **TLS cert** | expires ${CERT} |
| **Uptime** | ${UPTIME} |

— Rax (automated)"""

body = {"author": "rax", "thread_id": 285, "message": msg}
token = open("/home/gorn/.oracle/tokens/rax").read().strip()
req = urllib.request.Request(
    "http://localhost:47778/api/thread",
    data=json.dumps(body).encode(),
    headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"},
    method="POST",
)
resp = urllib.request.urlopen(req).read().decode()
print(resp)
PYEOF
