---
name: seed-mempalace
description: Deprecated in v3.3.0. Use /vladyslav:ingest instead (it runs analyze + seed-mempalace in one pass).
---

# Seed MemPalace — Deprecated

**Type:** Engineer (light)

## Status

**Deprecated in v3.3.0** (2026-05-11). Use [`/vladyslav:ingest`](../ingest/SKILL.md) instead.

`ingest` does everything this skill did (gather signals → extract decisions → write MemPalace records) PLUS produces architecture docs in the same pass. Running both `analyze-project` and `seed-mempalace` separately is twice the discovery cost for outputs that should agree but historically didn't.

This skill will be removed in v4.0.

## What to do

If a user types `/vladyslav:seed-mempalace`, redirect them:

```
ℹ /vladyslav:seed-mempalace is deprecated in v3.3.0.
  Use /vladyslav:ingest instead — same MemPalace seeding, plus
  architecture docs from a single source-of-truth scan pass.

  Want me to run /vladyslav:ingest now? (y/n)
```

If the user says yes → invoke `/vladyslav:ingest` via the standard Glob+Read pattern on its `SKILL.md` and follow it. Step 3 of `ingest` handles the "wing already seeded" case automatically — it will detect existing records and ask whether to add only new decisions or re-seed from scratch.

If the user says no → exit cleanly. Do NOT fall back to the old seed-mempalace behaviour. The maintained code path is `ingest`.
