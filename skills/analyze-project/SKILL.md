---
name: analyze-project
description: Deprecated in v3.3.0. Use /vladyslav:ingest instead (it runs analyze + seed-mempalace in one pass).
---

# Analyze Project — Deprecated

**Type:** Engineer (light)

## Status

**Deprecated in v3.3.0** (2026-05-11). Use [`/vladyslav:ingest`](../ingest/SKILL.md) instead.

`ingest` does everything this skill did (scan codebase → write `docs/architecture/system.md` / `api.md` / `db-schema.sql`) PLUS seeds MemPalace in the same pass. Running both `analyze-project` and `seed-mempalace` separately is twice the discovery cost for outputs that should agree but historically didn't.

This skill will be removed in v4.0.

## What to do

If a user types `/vladyslav:analyze-project`, redirect them:

```
ℹ /vladyslav:analyze-project is deprecated in v3.3.0.
  Use /vladyslav:ingest instead — same architecture docs, plus MemPalace
  records from a single source-of-truth scan pass.

  Want me to run /vladyslav:ingest now? (y/n)
```

If the user says yes → invoke `/vladyslav:ingest` via the standard Glob+Read pattern on its `SKILL.md` and follow it.

If the user says no → exit cleanly. Do NOT fall back to the old analyze-project behaviour (which was Heavy Engineer in v2.x and migrated to a `scan-architecture.sh`-driven flow in v3.2.0). The maintained code path is `ingest`.
