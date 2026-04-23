# Lesson: Timestamps Close Security Loops

**Date**: 2026-04-02
**Source**: Claude Code source leak response (thread #470)

When a supply chain security incident hits, the first question is always "are we affected?" The fastest way to close that loop is exact timestamps — file birth times, binary modification dates, install logs. Not "I think we updated before that" but a table with UTC times and a clear comparison to the vulnerability window.

The pack responded to the Claude Code trojanized npm window (March 31 00:21-03:29 UTC) by asking infra to verify. I checked `stat` on the binaries in `~/.local/share/claude/versions/`, converted to UTC, and posted a table. Four checkmarks in minutes. Thread closed.

**Pattern**: Keep infrastructure artifacts timestamped and accessible. When security asks "when did we install X?" — the answer should take seconds, not investigation.
