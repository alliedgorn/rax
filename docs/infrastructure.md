# Den Infrastructure Documentation

**Last updated**: 2026-03-28 by Rax

## Server

| Item | Value |
|------|-------|
| Provider | DigitalOcean (Premium Intel) |
| OS | Ubuntu 24.04.3 LTS |
| Kernel | 6.8.0-106-generic |
| CPU | 8 cores (DO-Premium-Intel) |
| RAM | 16 GB |
| Disk | 435 GB (4% used) |
| Swap | 4 GB (/swapfile) |
| IP (anchor) | 168.144.37.242 |
| IP (reserved/static) | 146.190.7.245 |
| Hostname | gorn-oracle |

## Domain & DNS

| Item | Value |
|------|-------|
| Domain | denbook.online |
| Registrar | GoDaddy |
| DNS | Cloudflare (migrated 2026-03-27) |
| CDN/Proxy | Cloudflare (orange cloud, proxied) |
| SSL (Cloudflare edge) | Cloudflare Universal SSL |
| SSL (origin) | Let's Encrypt (valid Mar 17 – Jun 15, 2026) |
| SSL mode | Full (strict) |
| CF Zone ID | edfb5803457b43020246945840ec4d1c |
| CF Firewall | Block All Except Whitelist (the_den_whitelist) |

## DO Firewall

Name: Firewall (ID: cb4db438-ae2d-40e8-bce6-902a43d5b27b)

| Port | Protocol | Sources |
|------|----------|---------|
| 22 | TCP | 13.214.107.28, 43.226.230.166 (Gorn VPN IPs) |
| 80 | TCP | All Cloudflare IPv4 ranges (15 CIDRs) |
| 443 | TCP | Cloudflare IPv4 ranges + Gorn VPN IPs |
| 3000 | TCP | Gorn VPN IPs |
| 47778 | TCP | Gorn VPN IPs |

## Stack

| Component | Version | Port | Notes |
|-----------|---------|------|-------|
| Caddy | 2.11.2 | 80, 443 | Reverse proxy + TLS termination |
| Bun | 1.3.10 | 47778 | App runtime (Den Book / Oracle v2) |
| Meilisearch | 0.56.0 | 7700 (localhost) | Full-text search engine |
| SSH | OpenBSD | 22 | Remote access |

## Caddy Configuration

Location: `/etc/caddy/Caddyfile`

```
{
    servers {
        protocols h1
    }
}

denbook.online {
    tls /etc/letsencrypt/live/denbook.online/fullchain.pem /etc/letsencrypt/live/denbook.online/privkey.pem

    reverse_proxy 127.0.0.1:47778 {
        header_up X-Forwarded-Proto https
    }

    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        Referrer-Policy strict-origin-when-cross-origin
    }
}
```

Key decisions:
- `protocols h1` — HTTP/2 disabled due to WebSocket compatibility issues (fixed Day 13)
- `reverse_proxy 127.0.0.1:47778` — uses IPv4 explicitly (IPv6 `localhost` caused connection issues)
- `header_up X-Forwarded-Proto https` — ensures backend sees HTTPS for cookie Secure flag

## Services (systemd)

| Service | Status | Notes |
|---------|--------|-------|
| caddy | active | Reverse proxy |
| meilisearch | active | Search engine, master key in oracle-v2/.env |
| ssh | active | Remote access |

## Listening Ports

| Port | Service | Binding |
|------|---------|---------|
| 22 | SSH | 0.0.0.0 + [::] |
| 53 | systemd-resolved | 127.0.0.53 / 127.0.0.54 |
| 80 | Caddy (HTTP → HTTPS redirect) | * |
| 443 | Caddy (HTTPS) | * |
| 2019 | Caddy admin API | 127.0.0.1 |
| 7700 | Meilisearch | 127.0.0.1 |
| 47778 | Bun (Den Book) | 0.0.0.0 |

## Application

| Item | Value |
|------|-------|
| App | Oracle v2 (Den Book) |
| Location | /home/gorn/workspace/oracle-v2 |
| Runtime | Bun 1.3.10 |
| Database | SQLite (in oracle-v2) |
| Framework | Hono |
| Frontend | React (Vite) |

## Backup

| Item | Value |
|------|-------|
| Vault | the-den-vault (private GitHub repo) |
| Contents | Beast brain backups (ψ/ directories) |
| Location | /home/gorn/workspace/the-den-vault |

## Workspace Layout

```
/home/gorn/workspace/
├── oracle-v2/          # Main app (1.9G)
├── the-den-vault/      # Brain backups (14M)
├── supply-chain-tool/  # ChainGuard project (24M)
├── rax/                # This repo — infra
├── karo/               # Software engineering
├── gnarl/              # Tech research
├── bertus/             # Security
├── leonard/            # Kingdom leader
├── mara/               # Pack registry
├── zaghnal/            # Project management
├── dex/                # Design
├── quill/              # Design
├── pip/                # QA
├── snap/               # QA
├── talon/              # Security
├── nyx/                # Recon
├── vigil/              # PM
├── flint/              # Engineering
└── sable/              # Gorn's assistant
```

## Scheduled Maintenance

| Schedule | Interval | Description |
|----------|----------|-------------|
| #21 | 1h | System health check (disk, RAM, swap, load, Den Book uptime) |
| #429 | 7d | Weekly patch status report (scripts/patch-status.sh) |

## Known Issues / Pending

- Health check automation with alerts — proposed, not built
- Vault sync auto-discovery — sync.sh has hardcoded Beast list
- Monitoring + Telegram alerts — proposed, not built
- Cloudflare migration — completed 2026-03-27
