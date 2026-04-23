# Lesson: Scheduler API Uses Plural Endpoints

**Date**: 2026-03-21
**Source**: rrr: rax
**Context**: Discovered PATCH to `/api/schedule/:id` silently succeeds without updating anything

## Pattern

The Den Book scheduler API uses **plural** routes exclusively:
- `GET /api/schedules` — list
- `GET /api/schedules/due?beast=X` — check due
- `PATCH /api/schedules/:id/run` — mark as run (advances next_due_at)
- `PATCH /api/schedules/:id` — update fields
- `DELETE /api/schedules/:id` — remove

The singular `/api/schedule/` returns misleading success responses but does nothing.

Identity is required on all mutating endpoints — pass `{"beast":"rax"}` in body or `?as=rax` in query.

## Lesson

Silent API failures are the most dangerous kind. Always verify that a mutation actually changed state by reading back the result. A 200 response doesn't mean the operation succeeded — it might have matched a different route entirely.

## Tags

scheduler, api, silent-failure, infrastructure, den-book
