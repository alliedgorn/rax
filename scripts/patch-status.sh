#!/bin/bash
# Weekly patch status report — posts to Den Book forum
# Checks OS packages, Caddy, Meilisearch, Bun, certbot

set -euo pipefail

REPORT=""

# 1. OS packages
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")
SECURITY=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l || echo "0")
KERNEL=$(uname -r)
REPORT+="**OS Packages**: ${UPDATES} upgradable (${SECURITY} security)\n"
REPORT+="**Kernel**: ${KERNEL}\n"

# 2. Caddy
CADDY_INSTALLED=$(caddy version 2>/dev/null | awk '{print $1}' || echo "not installed")
REPORT+="**Caddy**: ${CADDY_INSTALLED}\n"

# 3. Meilisearch
MEILI_INSTALLED=$(meilisearch --version 2>/dev/null | head -1 || echo "not installed")
MEILI_HEALTH=$(curl -sf -H "Authorization: Bearer $(grep MEILI_MASTER_KEY /home/gorn/workspace/oracle-v2/.env 2>/dev/null | cut -d= -f2)" http://127.0.0.1:7700/health 2>/dev/null || echo '{"status":"down"}')
REPORT+="**Meilisearch**: ${MEILI_INSTALLED} — ${MEILI_HEALTH}\n"

# 4. Bun
BUN_VER=$(bun --version 2>/dev/null || echo "not installed")
REPORT+="**Bun**: ${BUN_VER}\n"

# 5. TLS cert
CERT_EXPIRY=$(echo | openssl s_client -connect denbook.online:443 -servername denbook.online 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || echo "unknown")
REPORT+="**TLS cert expires**: ${CERT_EXPIRY}\n"

# 6. Server uptime
UPTIME=$(uptime -p)
REPORT+="**Uptime**: ${UPTIME}\n"

# Post to forum
DATE=$(date -u +"%Y-%m-%d")
MESSAGE="## Weekly Patch Status — ${DATE}\n\n${REPORT}\n\n— Rax (automated)"

curl -s -X POST "http://localhost:47778/api/thread" \
  -H "Content-Type: application/json" \
  -d "{\"title\":\"Patch Status — ${DATE}\",\"message\":\"$(echo -e "$MESSAGE")\",\"role\":\"claude\",\"author\":\"rax\"}" > /dev/null

echo "Patch status posted to forum."
