---
date: 2026-03-20
source: Session observation — CPU load 13.25 during vite+tsc build
---

# Frontend builds cause CPU spikes on our droplet

When design changes ship (CSS, components), Karo rebuilds oracle-v2 frontend with `tsc -b` and `vite build`. On our 4-vCPU droplet, this causes:
- Load average spike to 13+ (from baseline ~1-2)
- CPU at 82%+ for 2-3 minutes
- `tsc` alone can hit 74% CPU

The spike is temporary (builds finish in ~2 minutes) and the system recovers. But if multiple Beasts trigger builds simultaneously, it could cause sluggishness for all sessions.

**Pattern**: Watch for build events after design/frontend changes. Check `ps aux --sort=-%cpu` if load spikes. Don't panic — builds finish fast.
