---
name: seed-mempalace
description: Use once per project to bootstrap MemPalace memory with existing architectural decisions from git log and docs - one-time seeding so future sessions have context without re-scanning the codebase
---

# Seed MemPalace

## Overview

One-time action per project: extract key architectural decisions, design rationale, and known gotchas from the existing codebase / git history / docs, and write them to the project's MemPalace wing. After seeding, future Claude sessions on this project start with context instead of scanning everything from scratch.

**Each wing is an isolated project memory.** This skill does NOT merge decisions across projects. It populates one wing with one project's history.

**Type:** Architect (Opus)

## When to use

- First time working on an existing project with Claude
- When `docs/architecture/` is out of sync with code but you don't want a full `analyze-project` rewrite
- After a major refactor that should be captured as a decision record
- When switching to MemPalace-first workflow on an existing project

Do NOT use this skill on a project that was already seeded unless you explicitly want to add newer decisions (it will ask before duplicating).

## Process

### Step 0: Verify model

Check current model. If not Opus, switch: `/model opus`. Extracting good decisions requires judgement.

### Step 1: Identify the wing

1. Determine current project name from `pwd` or from `CLAUDE.md` / `.claude-plugin/plugin.json` / `package.json` / `pubspec.yaml`.

2. **Derive the canonical wing name** (mandatory normalization):
   - Start from `basename $(pwd)` (directory name only, not full path)
   - Lowercase it entirely
   - Replace spaces, underscores, dots with hyphens
   - If it doesn't start with a platform prefix, prepend one: `swift-`, `python-`, `flutter-`, `kotlin-`, `web-`, `go-`
   - Examples: `Sudoku` in `swift/` → `swift-sudoku` | `MyApp` → `python-myapp`
   - **Never** write to a wing with capital letters or wrong casing — this creates duplicate wings (e.g. `swift-Sudoku` vs `swift-sudoku`) that accumulate stale records in parallel.

3. Run `mempalace_list_wings`. Scan for any wing that looks like a wrong-case version of the canonical name. If found → warn the user:
   > "Found existing wing `<wrong-case>` that appears to be a stale duplicate of canonical `<correct-case>`. Records in the stale wing may reference paths that no longer exist. Using canonical wing for all writes."

4. If no matching wing exists → confirm canonical name with the user before creating.

### Step 2: Check existing records

1. Run `mempalace_search` within the wing with a broad query (e.g. "architecture") to see what's already there.
2. If the wing already has significant records → ask the user:
   - **Add only new decisions** (default) — seed only things not already captured
   - **Re-seed from scratch** — wipe relevant records first (rare, only if old records are wrong)
   - **Abort** — wing is healthy, no action needed

### Step 3: Gather architectural signals

Read these sources (in order of trust):

1. **`CLAUDE.md`** — explicit instructions, tech stack, non-obvious rules
2. **`docs/architecture/system.md`** — system overview (if exists)
3. **`docs/architecture/api.md`** — API contracts (if exists)
4. **`docs/architecture/adr/*.md`** — architectural decision records (if exists)
5. **`docs/product/prd.md`** — product goals and constraints (if exists)
6. **Package manifests** — `package.json`, `pubspec.yaml`, `requirements.txt`, `Package.swift`, `go.mod`, `build.gradle` — for stack decisions
7. **Git log** — `git log --oneline -100` for recent change themes; `git log --all --oneline --grep="feat\|refactor\|decision"` for notable commits
8. **Entry points and config** — `main.*`, `app.*`, `index.*`, `.env.example`, `docker-compose.yml`

Do NOT exhaustively read every source file. The goal is signal extraction, not code review.

### Step 4: Extract 10-20 key records

For each signal, decide:

**What to capture (yes):**
- Architecture decisions: "We use X instead of Y because Z"
- Stack choices with rationale
- Non-obvious patterns: "Auth flows through middleware M, not controller"
- Known gotchas and workarounds
- Historical bugs with their fix approach (as `problem` type)
- Integration constraints: "Third-party API X requires Y"
- Product milestones (as `milestone` type)
- Preferences: "Daisy prefers server-side validation here" (as `preference` type)

**What to skip (no):**
- Routine commits (formatting, dependency bumps, typos)
- Things trivially derivable from current code
- Temporary state (current in-progress tasks)
- Personal opinions without project impact

Cap at ~20 records for the first pass. Quality over quantity. More can be added later through normal work.

### Step 5: Write to MemPalace

For each extracted record, call `mempalace_add_drawer` with:

- **wing**: the project wing from Step 1
- **room**: appropriate room type (`decision`, `problem`, `milestone`, `preference`)
- **content**: verbatim structured text, e.g.:
  ```
  [WHAT] <one-line summary of the decision/fact>

  [WHY] <rationale — the reason the user or team chose this>

  [FILES] <key file paths that implement or reference this>

  [DATE] <approximate date, from git log or docs>
  ```
- **added_by**: `seed-mempalace`
- **source_file**: path to the source doc/code if relevant (optional)

Before adding each record, run `mempalace_check_duplicate` to avoid duplicating existing content.

For **relationship facts** (e.g. "module X depends on module Y", "decision D supersedes decision E"), additionally call `mempalace_kg_add` with `subject` / `predicate` / `object` — the knowledge graph stores triples, not content.

### Step 6: Verify searchability

Run 3-5 `mempalace_search` queries within the wing to confirm the new records surface for likely future queries. Example:
- Search for a tech stack term → should return the stack decision
- Search for an auth concept → should return auth-related records
- Search for the product name → should return milestone records

If records don't surface, rewrite their content with better keywords and re-add.

### Step 7: Update CLAUDE.md pointer

Add (or update) a line in the project's `CLAUDE.md` so future sessions know this wing is seeded:

```markdown
## Memory

This project has been seeded in MemPalace. Wing: `<wing-name>`.
Before scanning the codebase, search the wing: `mempalace_search wing=<wing-name>`.
Last seeded: YYYY-MM-DD.
```

### Step 8: Finish

Print architect report:

```
✓ Architect report — MemPalace seeding
- Wing: <name>
- Records added: <count>
  - Decisions: <count>
  - Problems: <count>
  - Milestones: <count>
  - Preferences: <count>
- Duplicates skipped: <count>
- Verification searches: <count>/<count> passed
- CLAUDE.md updated: yes/no

Future sessions on this project should start with:
  mempalace_search wing=<name> <task-related terms>

Re-seed only if major architecture changes happen.
```

## Notes

- **One wing per project.** Do NOT spread one project across multiple wings or merge wings.
- **Seed is one-time, not continuous.** Ongoing decisions should be written by other skills (add-feature, fix-bug) after each change, not by re-running this skill.
- **If unsure whether something is worth recording — skip it.** It's easier to add later than to remove noise.
