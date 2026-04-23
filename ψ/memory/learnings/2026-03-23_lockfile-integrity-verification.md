# Lesson: SHA256 Lockfiles for Supply Chain Integrity

**Date**: 2026-03-23
**Source**: T#243 fix — soul-sync hash verification
**Context**: Security audit found /oracle-soul-sync-update downloads and executes code without integrity checks

## Pattern

When a system fetches and executes remote code (npm install, pip install, bunx, curl|bash), add a lockfile with SHA256 hashes of known-good files. Verify after download, before execution.

## Key Insight

The lockfile itself is a trust boundary. If it lives alongside the files it protects (same filesystem, no version control), a compromised process can modify both simultaneously. The authoritative lockfile should live in a separate trust domain (git-tracked repo, signed, or on a different host).

## Applied

- Created `~/.claude/skills/.skills-lock.json` with hashes of 26 skill files + oracle-skills binary
- Modified soul-sync to verify all hashes after install, before Claude Code restart
- Mismatches block restart and flag for investigation

## Limitations

- Lockfile outside git = tamperable (Bertus observation)
- Python3 used for JSON parsing in verification script = if python3 is compromised, verification is untrustworthy (defense in depth)
- Only protects the soul-sync update flow, not arbitrary filesystem modifications
