# Cloudflare-DO Firewall IP Sync

**Author**: Rax
**Date**: 2026-03-28
**Status**: Architecture — pending Gorn approval
**Thread**: #320

## Purpose

Keep the DigitalOcean cloud firewall in sync with Cloudflare's published IP ranges. Prevents site outages if Cloudflare adds or changes edge IPs.

## Architecture

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Cloudflare  │     │   GCP Secret     │     │ DigitalOcean │
│  Public API  │     │   Manager        │     │ Firewall API │
│  (no auth)   │     │                  │     │              │
└──────┬───────┘     └────────┬─────────┘     └──────┬───────┘
       │                      │                      │
       │ GET /client/v4/ips   │ get do-firewall-token│
       │                      │                      │
       ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────┐
│                 cf-do-firewall-sync.sh                      │
│                                                             │
│  1. Fetch CF IPs (public, no auth)                          │
│  2. Sanity check (≥10 IPv4 ranges)                          │
│  3. Pull DO token from GCP Secret Manager                   │
│  4. Fetch current DO firewall rules                         │
│  5. Diff CF IPs vs firewall rules                           │
│  6. If changed: update firewall, log, alert                 │
│  7. If unchanged: log, exit                                 │
└─────────────────────────────────────────────────────────────┘
       │
       ▼
┌──────────────┐
│  Cron        │
│  Daily 04:00 │
│  UTC+7       │
└──────────────┘
```

## Components

### Script

- **Location**: `rax/scripts/cf-do-firewall-sync.sh`
- **Language**: Bash (curl + jq for JSON parsing)
- **Runs as**: gorn user via cron

### Credentials

| Secret | Stored in | Scope |
|--------|-----------|-------|
| DO API token | GCP Secret Manager (`do-firewall-token`) | Networking: Firewalls (read+write only) |
| CF API token | Not needed | Public endpoint, no auth required |
| GCP auth | Service account key file at `/etc/gcp/sa-key.json` | Secret Manager Secret Accessor only |

### GCP Setup (Gorn)

1. **GCP project**: Enable Secret Manager API
2. **Service account**: Create with role `roles/secretmanager.secretAccessor` only
3. **Key file**: Download JSON key → place at `/etc/gcp/sa-key.json` (chmod 600, owned by gorn)
4. **Secret**: Create `do-firewall-token` containing the DO API token
   ```
   gcloud secrets create do-firewall-token \
     --project=PROJECT_ID \
     --data-file=- <<< "TOKEN_VALUE"
   ```
5. **gcloud CLI**: Install on server if not present

### DO Token (Gorn)

- Generate at DigitalOcean → API → Tokens
- Scope: **Custom** → Networking: Firewalls (Read + Write)
- No other scopes needed

## Script Logic

```
1. AUTH
   - Export GOOGLE_APPLICATION_CREDENTIALS=/etc/gcp/sa-key.json
   - Fetch DO token: gcloud secrets versions access latest --secret=do-firewall-token

2. FETCH
   - CF IPs: GET https://api.cloudflare.com/client/v4/ips → .result.ipv4_cidrs[]
   - DO firewall: GET https://api.digitalocean.com/v2/firewalls/FIREWALL_ID

3. SANITY CHECK
   - CF must return ≥10 IPv4 ranges (currently 15). If fewer → abort, alert.
   - DO API must return 200. If error → abort, alert.

4. DIFF
   - Extract current port 80/443 source addresses from DO firewall
   - Compare with CF IPv4 list
   - If identical → log "no changes", exit 0

5. UPDATE (only if diff detected)
   - Build new inbound rules (preserve SSH, 3000, 47778 rules unchanged)
   - PUT updated firewall to DO API
   - Log: timestamp, old CIDRs, new CIDRs, diff
   - Alert: post to forum thread or Telegram

6. DRY-RUN MODE
   - Flag: --dry-run
   - Runs steps 1-4, shows what would change, does NOT apply
   - All first runs should use --dry-run
```

## Schedule

| Item | Value |
|------|-------|
| Frequency | Daily |
| Time | 04:00 UTC+7 (21:00 UTC) |
| Method | System cron (`crontab -e`) |
| Cron entry | `0 21 * * * /home/gorn/workspace/rax/scripts/cf-do-firewall-sync.sh >> /var/log/cf-do-sync.log 2>&1` |

## Safety

- **Sanity check**: Abort if CF returns fewer than 10 ranges (prevents lockout)
- **Idempotent**: Safe to run multiple times — no-op if no changes
- **Dry-run**: First runs and testing always use --dry-run
- **Preserve existing rules**: Only modifies CF IP entries on ports 80/443. SSH, 3000, 47778 rules untouched.
- **Audit log**: Every run logged with timestamp and result
- **No secrets on disk**: DO token fetched from GCP Secret Manager at runtime, never written to filesystem
- **GCP key rotation**: Rotate service account key quarterly (per Bertus recommendation)

## Alerting

On IP change detected:
- Post to forum thread #320 with diff
- Optional: Telegram notification to Gorn

## File Layout

```
rax/
├── scripts/
│   ├── cf-do-firewall-sync.sh    # Main script
│   └── patch-status.sh           # Existing
├── docs/
│   ├── infrastructure.md         # Existing
│   └── cf-do-firewall-sync.md    # This doc
```

## Dependencies

- `curl` (installed)
- `jq` (needs install: `apt install jq`)
- `gcloud` CLI (needs install)
- GCP service account key at `/etc/gcp/sa-key.json`
