# Check Plugin Issue Trackers Before Deploying

**Date**: 2026-03-17
**Source**: rrr: rax

Built a custom Caddy binary with the caddy-dns/digitalocean plugin. The plugin had a known bug (strconv.Atoi parsing error) that prevented TXT record deletion. Every failed cert attempt left stale records that poisoned subsequent attempts. Two hours of debugging that 5 minutes of GitHub issue research would have prevented.

**Pattern**: Shiny plugin → deploy → discover known bug → debug → fallback to boring tool that works

**Rule**: Before adopting any plugin or dependency for infrastructure:
1. Check the GitHub issues for known bugs
2. Check last commit date (stale = risky)
3. If the boring tool (certbot, nginx) does the job, use it first

**Tags**: infrastructure, dependencies, due-diligence, ssl
