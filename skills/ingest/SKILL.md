---
name: ingest
description: Use on an existing project to scan code once and produce both architecture docs and a MemPalace seed pass.
---

# Ingest

**Type:** Architect

## Overview

Single-pass project intake. Combines what `analyze-project` and `seed-mempalace` used to do separately. Two bash scripts produce the discovery JSON; Opus main does the narrative synthesis (architecture docs) and the decision extraction (MemPalace records). Both outputs derive from the same source-of-truth scan, so they cannot disagree.

Replaces (deprecates) `analyze-project` + `seed-mempalace`. Those still work but redirect to this skill.

## When to use

- First time you work on an existing project with Claude (run instead of `analyze-project`).
- After a major refactor when both the docs and the MemPalace need refresh.
- When the previous `analyze-project` output is stale and you want to re-seed MemPalace at the same time.

## When NOT to use

- Brand-new project from `init-project` — that already scaffolds `docs/architecture/` and there is no git history to seed from.
- Pure documentation-only updates — use `write-project-docs` instead.

## Process

### Step 0: Verify working directory

Apply the verify-working-directory contract from `<plugin>/skills/_shared/references/verify-pwd.md`: confirms `CLAUDE.md` exists, derives the canonical MemPalace wing name, warns on stale-wing duplicates, and establishes the mandatory path-validation rule for the rest of this skill's MemPalace reads.

If `CLAUDE.md` is missing → STOP and suggest `/vladyslav:attach-project` first to bootstrap the AI workflow shell.

### Step 1: Resolve plugin root

Glob `~/.claude/plugins/cache/vladyslav-marketplace/vladyslav/*/scripts/scan-architecture.sh` and take the directory two levels up. Fall back to `/Volumes/DevSSD/Development/vladyslav-skills` (development clone).

### Step 2: Scan the codebase

Run two scripts back-to-back. Each is deterministic, takes well under a second on a typical project, and emits JSON.

```bash
ARCH=$(<plugin-root>/scripts/scan-architecture.sh --pwd .)
SIGNALS=$(<plugin-root>/scripts/gather-seed-signals.sh --pwd .)
```

`ARCH` schema:

```json
{
  "stacks": {<from detect-stack.sh: ios/python/go/...>},
  "entry_points": [<paths>],
  "routes": {"framework": "fastapi|flask|express|go-stdlib|none", "handlers": [{method, path, file}, ...]},
  "schema_files": [<SQL migrations, Prisma, Drizzle, Alembic>],
  "deps": {<manifest path>: <summary string>},
  "doc_files": [<paths under docs/>]
}
```

`SIGNALS` schema:

```json
{
  "git": {
    "available":         true|false,
    "head_commit":       "<short sha>",
    "branch":            "<current branch>",
    "first_commit_date": "<YYYY-MM-DD>",
    "recent_themes":     [<last 30 non-merge commit subjects>],
    "decision_commits":  [<feat/refactor/fix/decision-prefixed subjects, up to 40>],
    "most_edited":       [{"path": "...", "edits": N}, ...]
  },
  "manifests":     {<path>: <summary string>},
  "existing_docs": [<paths under docs/>],
  "adr_files":     [<paths under docs/architecture/adr/ or docs/decisions/>],
  "claude_md":     {"exists": true|false, "size": <bytes>}
}
```

Together, `ARCH` answers *"what does the code look like now"*, `SIGNALS` answers *"what changed historically and what decisions exist already"*. The LLM combines them.

### Step 3: Check existing MemPalace state

Before writing seed records, search the current wing to avoid duplicates:

```
mempalace_search wing=<wing> "architecture"
mempalace_search wing=<wing> "decision"
mempalace_search wing=<wing> "stack"
```

Categorise existing records:
- **Empty wing (fresh seed):** proceed with full extraction in Step 5.
- **Wing has records but they look stale (older than 6 months, or paths in them no longer exist):** ask the user → re-seed from scratch, add only new, or skip seeding entirely.
- **Wing actively curated:** ask the user → add only new decisions discovered, or skip seeding.

Path-validation rule applies to every search result — drawers referencing non-existent paths are marked `[STALE]` and excluded.

### Step 4: Synthesise architecture docs

Using `ARCH`, write or update:

- **`docs/architecture/system.md`** — high-level narrative derived from `stacks`, `entry_points`, and the codebase layout. 2-4 paragraphs. Preserve any user-edited sections if the file already exists; merge rather than overwrite.
- **`docs/architecture/api.md`** — only if `routes.framework` is not `none`. Table of `method | path | handler-file` from `routes.handlers`. Group by feature area when possible.
- **`docs/architecture/db-schema.sql`** — only if `schema_files` is non-empty. Stitch the relevant SQL migrations / Prisma / Drizzle schemas into one consolidated reference. Preserve user-edited sections.

Do NOT touch:
- `docs/product/*` (that's `discover` / `init-project`'s job)
- `docs/plans/*`, `docs/testing/*`, `docs/release/*`, `docs/operations/*`, `docs/marketing/*` (these are not architecture)

If `claude_md.exists` is false → also write a minimal `CLAUDE.md` with the Source-of-Truth table pointing at the docs you just wrote. If it already exists, leave it alone (it's a high-touch user document — don't blast it).

### Step 5: Extract MemPalace records

Using `ARCH` + `SIGNALS` together, identify 10–20 records worth seeding. Apply `<plugin>/skills/_shared/references/mempalace-record.md` for shape and room-type rules. Quality over quantity — re-seedability matters.

**What to capture:**

- **Architecture decisions** (room: `decision`) — derived from `manifests`, framework choice (`routes.framework`), schema decisions (`schema_files`), notable patterns from `most_edited` files.
- **Stack choices with rationale** (`decision`) — when `manifests` reveal a deliberate choice (FastAPI over Flask, Drizzle over Prisma, etc.). If the rationale isn't documented, write the choice as `[WHAT]` and leave `[WHY]` blank with a `<unknown — confirm with team>` placeholder.
- **Recurring bug themes** (room: `problem`) — `signals.decision_commits` filtered to `fix:` prefixes. One drawer per recurring class, not per individual fix.
- **Product milestones** (room: `milestone`) — release-like commit subjects (e.g. `release: v...`) and the first-commit date.
- **Existing ADRs** (room: `decision`) — for each path in `signals.adr_files`, write a short pointer drawer so future searches surface them.

**What to skip:**

- Routine commits (formatting, dependency bumps, typos)
- Things trivially derivable from the current code (no value over re-scanning)
- Temporary state
- Anything older than the `first_commit_date` makes no sense to write

Before each `mempalace_add_drawer`, run `mempalace_check_duplicate` to avoid pollution. For relationship facts (`module X depends on Y`, `decision D supersedes E`), also call `mempalace_kg_add` with `subject`/`predicate`/`object`.

### Step 6: Verify searchability

Run 3–5 `mempalace_search` queries within the wing to confirm the new records surface for likely future queries. Example:

- Stack term → returns the framework choice
- An auth-related concept → returns auth-related records
- The project name → returns milestone records

If a record does not surface for an obvious query, rewrite its content with better keywords (the `[WHAT]` line is what the search indexes most heavily) and re-add.

### Step 7: Update CLAUDE.md pointer

If a `## Memory` section is absent, append:

```markdown
## Memory

This project has been ingested into MemPalace. Wing: `<wing-name>`.
Before scanning the codebase, search the wing: `mempalace_search wing=<wing-name>`.
Last ingested: <YYYY-MM-DD>.
```

If a `## Memory` section already exists, update the `Last ingested:` date in place.

### Step 8: Architect report

```
✓ Architect report — Ingest
- Project: <name>
- Wing: <wing-name>
- Detected stacks: <list from ARCH.stacks>
- Routes detected: <count> across <framework>
- Schema files: <count>

Architecture docs:
  - docs/architecture/system.md       <created | merged | unchanged>
  - docs/architecture/api.md          <if backend present>
  - docs/architecture/db-schema.sql   <if schemas present>

MemPalace records:
  - Decisions added: <count>
  - Problems added: <count>
  - Milestones added: <count>
  - Duplicates skipped: <count>
  - Verification searches passed: <count>/<count>

CLAUDE.md memory pointer: <added | updated | unchanged>

Next steps:
- /vladyslav:add-feature  — build new features with both architecture docs and MemPalace context now ready
- /vladyslav:design-sync  — if UI work is upcoming
- /vladyslav:discover     — only if docs/product/start-project.md is incomplete (rare on an existing project)
```

---

## Why this is an Architect skill

- **Synthesis is genuine LLM work.** Combining `ARCH` and `SIGNALS` into a narrative `docs/architecture/system.md` requires reading the structured data, identifying the load-bearing patterns, and writing in human prose. No bash script can substitute.
- **Decision extraction requires judgement.** "Is this commit a real architectural decision, or just a bug fix?" — that's semantic. The script supplies the candidate pool (`signals.decision_commits`); the LLM curates.
- **The two bash scripts (`scan-architecture.sh` and `gather-seed-signals.sh`) do all the I/O.** The LLM doesn't read files directly — it reads the JSON. That's the leverage.

## Output files

- `docs/architecture/system.md`
- `docs/architecture/api.md` (backend only)
- `docs/architecture/db-schema.sql` (schemas only)
- `CLAUDE.md` — only if missing; never overwritten
- MemPalace records in the project's wing
- (Optional) one new entry in `swift-calories` wing — only if a new Apple-pattern decision is discovered (rare; mostly `discover-apple-check`'s job)

## Migration from analyze-project / seed-mempalace

If you previously ran `analyze-project`, the output overlaps. `ingest` will preserve user-edited sections and merge new findings. If you previously ran `seed-mempalace`, the wing is already populated; Step 3 will detect this and ask whether to add only new records or re-seed from scratch.

The old skills now redirect here. They will be fully removed in v4.0.
