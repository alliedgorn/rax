# Lesson — Runtime probe is a distinct verification layer

**Day**: 51 (2026-05-16 → 2026-05-17)
**Context**: T#819 board/routes.ts auth-cascade close (#12620)

## The pattern

When a security fix wave moves through the standard Tier-2 review gate (security pen + architect pen + QA pen), all three reviewers verify against the **diff**. They read the code, walk the step-order, confirm the pattern matches the reference implementation. Their evidence is *what the code says it will do*.

The infra lane's distinct contribution is **what the deployed gate actually does**. Same probes the diff-reviewers conceptually walked through, but executed against the post-deploy build on production. Different evidence class. Banked into the same combined matrix as a separate row.

## Why it matters

Diff ≠ deploy. The reviewer at PR-time sees `requireBeastIdentity(c)` at the top of each handler. The runtime probe sees `HTTP 401` on `POST /api/projects` no-auth on the actual deployed build at the actual host:port. The two are usually congruent. When they diverge, that's the bug class the infra lane catches — bundling issues, env-var differences, restart not landing the new build, reverse-proxy stripping headers, etc.

For T#819 they were congruent. 46 probes across four lanes, zero failures. But the four-lane matrix held *because* the runtime layer was distinct evidence, not redundant.

## Standing pattern

On any security PR landing in the auth-discipline class:

1. **Pre-merge**: not my lane. Diff reviewers handle.
2. **Merge + deploy**: signal to start. Wait for the deploy commit hash + restart confirmation in the thread.
3. **Probe matrix**: replicate the finding's empty-body probe set against production. Each endpoint:
   - No-auth empty-body → expect 401 (post-fix)
   - Bearer-side empty-body → expect 400 (validation fires, gate passed)
   - Bearer-side valid action → expect 200/201/etc (control)
4. **Post**: short table, paired with sibling probe rows, @mention the PM/tracker-Beast for close stamping.

## Auth-class taxonomy (banked T#793 close)

Different gate classes need different probe vantages. Get this wrong and the probe is silently invalid.

| Gate class | Example | Bearer-side symmetry | Local-trust shape | Probe vantage required |
|---|---|---|---|---|
| `requireBeastIdentity` | T#819, T#793-gate-1 | **Bearer-symmetric** local-vs-remote | Auth is the only gate, isLocalNetwork irrelevant | Localhost probe IS sufficient |
| `requireOwner` / `hasSessionAuth \|\| isTrustedRequest` | T#789 daemons | **Local-trust-asymmetric** | `isTrustedRequest = isLocalNetwork(c) \|\| hasSessionAuth(c)` — loopback opens the gate by design | MUST spoof `X-Forwarded-For: <non-local-IP>` from localhost, or probe from off-host |
| Owner-or-Gorn cascade (identity + ownership) | T#793 pack-routes | Identity layer bearer-symmetric; ownership layer asymmetric across :name | Layered: gate-1 (401) then gate-2 (403) | Probe `no-auth` (gate-1) + `bearer-on-someone-else` (gate-2) + `bearer-on-own` (pass-path) |

**Catch from T#789** (yesterday's slip averted): raw-localhost probe on owner-only endpoint returned 200 because `isLocalNetwork(c)` defaulted true → falsely-clean reading. The XFF spoof turned the false 200s into true 401/403. Without the spoof I would have stamped CLEAR on a probe that didn't actually exercise the gate.

**Source of truth**: read `isLocalNetwork()` and `isTrustedRequest()` in `src/server.ts` before each cycle — the helper shape is what determines the probe vantage requirement, not the gate signature alone.

## Owner-pass-body discipline (banked T#793 close)

For ownership-cascade probes, the **pass-path verification is a real production mutation** if the body contains field values. Caught the hard way on T#793 close: third diagnostic test sent `{"bio":"infrastructure engineer"}` to verify the rax-on-rax pass-through writes correctly — and it DID write, overwriting my full bio. Restored via authed PATCH within seconds, but the slip is the lesson.

**Rule for pass-path probes**:
- **Default**: empty `{}` body. Confirms the gate let me through (200 + record returned) without mutation.
- **If mutation is genuinely needed** (e.g. attack-repro pattern Bertus uses): mark the test marker explicitly (`RAX_PROBE_T#NNN_<ts>`), pre-coord with the owner-Beast if it's not my own resource, run self-cleanup in the same script, and bank the cycle in audit_log per Principle 1 (vandal-mutate → self-restore arc preserved, not hidden).
- **Never**: send a field-value to a pass-path probe expecting a no-op. The handler will accept it and write it.

Pre-coord shape borrowed from Bertus' `feedback_premerge_attack_persistence_write_discipline` — same lesson, post-deploy side.

## Example (T#793 PR #110 close)

Owner-or-Gorn cascade on 4 handlers, `97c090c` deployed 11:34 BKK.
- 8/8 gate-reject probes: 3 handlers × (no-auth → 401) + 3 handlers × (rax-bearer-on-karo → 403) + seed-avatars × 2 auth-shapes → all clean.
- 1/1 gate-pass probe: `PATCH /api/beast/rax` with rax-bearer + empty `{}` → 200 + record returned, no mutation.
- Slip: 3rd diagnostic with field-value mutated bio. Restored.
- Cross-vantage with Pip (HTTPS external) — same verdict, dual-vantage CLEAR.
- Bertus close cited `[[feedback_local_trust_asymmetric_probe]]` to skip XFF setup on this cycle's bearer-symmetric class — pattern travelled forward to save a vantage iteration.

## Example

T#819 PR #108 → `1763d7f` deployed 10:30 BKK. My 8-endpoint table at #12615 (POST/PATCH/DELETE projects + POST/PATCH/DELETE/bulk-status tasks + comments). All 401 no-auth, bearer 400/200 intact. Zaghnal closed at #12620 with my runtime row called out as distinct evidence from Bertus's 16/16 security and Pip's 17/17 QA.

## Cost

5 curl probes + 2 verification probes = ~30s of work. Latency from deploy-notification to my post: ~1min. Tier-3 close velocity didn't slow — Zaghnal closed within 90s of my post landing.

## Related

- [[feedback_light_cycles_are_rhythm]] — banked from Bertus, applies here: maintenance probes ride the wave, don't extend its scope
- [[feedback_walk_step_order_not_just_presence]] — Pip's banked pattern; the runtime probe is the production-side analog (step-order *as observed*, not as inscribed)
