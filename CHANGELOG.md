# Changelog

## v4.1.0 — 2026-05-15

New `save` skill for saving semantic knowledge to MemPalace on demand — without compaction, without task-state framing.

### Added

- **`vladyslav:save`** (`skills/save/SKILL.md`, `commands/save.md`) — Engineer (light) skill. Saves a single knowledge record (decision / preference / milestone / problem) to MemPalace for the current project wing. Duplicate-checks before writing. Triggered by `/vladyslav:save`, "save to MemPalace", "remember this", "запам'ятай це".

  Complements `compact-save`: `compact-save` captures *task state before compaction* (structured YAML: task/files/next); `save` captures *semantic knowledge at any time* (decisions, preferences, milestones).

### Changed

- `README.md`, `SkillsManual.md`, `docs/diagrams/skill-flows.md` — updated to include `save` in all relevant sections.

---

## v4.0.1 — 2026-05-11

Pure-docs patch closing the two TODOs deferred from v4.0.0. No code or skill behaviour changes.

### Changed — `SkillsManual.md`

- **Example 1 (chess-duel) refreshed** — removed the v1.x `/model opus` manual switching artifacts:
  - Step 1 label: `(Engineer Sonnet)` → `(Engineer light — bash-driven, v3.0+)`. Body now mentions `scripts/scaffold-project.sh` and ~1-second runtime.
  - Step 3 label: `(Architect Opus). Перемикаєш: /model opus` → `(Architect, в тій самій сесії)`.
  - Step 4 label: `(Architect Opus)` → `(Architect)`.
- **New "Helper scripts" section** added near the end (before the footer). Groups all 15 scripts into three buckets: Discovery/detection (7), Scaffolding (4), Verification/reporting (4). Cross-links to `docs/architecture/system.md` as the canonical reference.

### Migration

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…or skip — v4.0.1 only changes documentation. Runtime is identical to v4.0.0.

---

## v4.0.0 — 2026-05-11

**BREAKING.** Removes the deprecated `analyze-project` and `seed-mempalace` skills (introduced as stubs in v3.3.0 when `ingest` superseded them). All cross-references across SKILL.md, docs, diagrams, README, and SkillsManual cleaned up. SkillsManual deep-refreshed to v3.x/v4.0 reality.

### Removed (BREAKING)

- `skills/analyze-project/` — entire directory deleted
- `skills/seed-mempalace/` — entire directory deleted
- `commands/analyze-project.md` — deleted
- `commands/seed-mempalace.md` — deleted

Users on automation calling these slash commands will see "command not found" after `/plugin update`. Migrate to `/vladyslav:ingest` — it produces both outputs (architecture docs + MemPalace records) from a single source-of-truth scan.

### Changed (cross-reference cleanup)

14 files updated to remove or replace stale references:

- `README.md` — "Deprecated" table removed; MemPalace skill list updated; Architect table dropped both, added `swiftui-pro` and `ingest`; Existing-project workflow now `attach-project → ingest → add-feature`; New-project workflow now `init-project → discover → add-feature → ...`; Superpowers integration table updated.
- `CLAUDE.md` — MemPalace-requiring skills list: `seed-mempalace` → `ingest`.
- `docs/architecture/system.md` — Architect examples cleaned of deprecation note; `scan-architecture.sh` row updated; `verify-pwd.md` consumers list updated; script count 13→15.
- `docs/diagrams/skill-flows.md` — skill count 18→16; `analyze-project` and `seed-mempalace` flowchart blocks deleted; new `ingest` flowchart added; `attach-project` done-node updated to `→ /ingest`.
- `docs/diagrams/skills-ecosystem.md` — count 18→16; replaced two old nodes with `ingest`.
- `docs/diagrams/workflows.md` — New Project flow uses `/ingest`; Existing Project flow collapsed from `seed-mempalace + analyze-project` two-step to single `ingest` step.
- `skills/attach-project/SKILL.md` — `Next:` line: `analyze-project` → `ingest`.
- `skills/discover-apple-check/SKILL.md` — option 1 in the no-records warning updated.
- `skills/help/SKILL.md` — full catalogue rewrite to v3.x taxonomy.
- `skills/ingest/SKILL.md` — Overview no longer says "Replaces (deprecates)"; "When to use" cleaned; old "Migration from analyze-project / seed-mempalace" section replaced with "Re-running ingest on a previously-seeded project" (the merge/re-seed flow handled in Step 3).
- `skills/write-project-docs/SKILL.md` — required-input fallback prompt: `analyze-project` → `ingest`.
- `skills/_shared/references/mempalace-record.md` — "Used by" list updated.
- `skills/_shared/references/verify-pwd.md` — consumer list updated; `attach-project` skip reason improved.
- `examples/mcp-config.example.json` — comment string updated.

### SkillsManual.md — deep refresh

Targeted updates to ~10 sections of the manual:

- Prerequisites + MemPalace list — replaced `seed-mempalace` with `ingest`; removed `analyze-project` from "works without MemPalace" list.
- "Приєднання Claude" section — two old entries replaced with single `ingest` entry.
- "Документування проекту" — references updated.
- Scenario A (new project) and Scenario B (existing project) — workflows updated; steps renumbered as `analyze-project` + `seed-mempalace` collapsed.
- Example 2 (python-tax) — steps 1-3 rewritten to use `ingest`.
- "Always requires explicit call" list — updated.
- Full skill list table — `analyze-project` + `seed-mempalace` rows removed; `ingest` row added (Architect 🧠).
- Taxonomy summary — counts updated: Architect 8 skills, Engineer bash-driven 3, Engineer Opus inline 5.
- Footer — `v4.0.0` note added.

Still TODO (low priority, deferred to v4.0.1):
- Example 1 (chess-duel) in SkillsManual still uses `/model opus|sonnet` manual switching (v1.x artifact). Rewriting it requires non-trivial narrative changes, kept for later.
- A dedicated "Helper Scripts" subsection in SkillsManual was NOT added (the canonical reference for scripts lives in `docs/architecture/system.md`).

### Final state

- **16 active skills** (was 18 in v3.3.0 with two deprecated stubs)
- **15 helper scripts** in `scripts/`
- **0 lint failures** across all 16 SKILL.md files
- All v2.x dispatch boilerplate eliminated; all Heavy Engineer skills migrated to Light Engineer (bash or Opus inline)

### Migration

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…and restart Claude. If your automation called `/vladyslav:analyze-project` or `/vladyslav:seed-mempalace`, replace with `/vladyslav:ingest`.

---

## v3.3.0 — 2026-05-11

`ingest` unification — collapse `analyze-project` + `seed-mempalace` into a single Architect skill that runs both bash scans once and produces architecture docs AND MemPalace seed records from the same source-of-truth pass.

### Added

- **`scripts/gather-seed-signals.sh`** (~200 lines) — companion to `scan-architecture.sh`. Collects git signals (head commit, branch, first commit date, last 30 commit subjects, decision-prefixed commits, top-10 most-edited files), package manifest summaries, existing `docs/**.md` paths, ADR file paths, and `CLAUDE.md` presence/size. Emits JSON. Paired with `scan-architecture.sh` these two scripts produce everything an LLM needs to write architecture docs AND seed MemPalace.
- **`skills/ingest/SKILL.md`** (~210 lines, Architect type) — single-pass intake for existing projects:
  1. Verify pwd + wing (via `_shared/verify-pwd.md`)
  2. Run `scan-architecture.sh` → ARCH JSON
  3. Run `gather-seed-signals.sh` → SIGNALS JSON
  4. Check existing MemPalace state (empty / stale / curated) and ask user policy
  5. Write `docs/architecture/{system,api,db-schema.sql}.md` (preserving user-edited sections)
  6. Extract 10–20 MemPalace records (decisions / problems / milestones)
  7. Verify searchability + update `CLAUDE.md` `## Memory` pointer
  8. Architect report
- **`commands/ingest.md`** — v2.3.2+ Glob+Read dispatch pattern.

Total `scripts/` helpers now: **14**.
Total skills: **18** (added `ingest`).

### Deprecated

- **`skills/analyze-project/SKILL.md`** — 95 → 32 lines. Now a deprecation stub that prompts the user to run `/vladyslav:ingest` instead. Removal scheduled for v4.0.
- **`skills/seed-mempalace/SKILL.md`** — 154 → 32 lines. Same deprecation pattern. Removal scheduled for v4.0.

Both deprecation stubs still register their slash commands so existing references to `/vladyslav:analyze-project` and `/vladyslav:seed-mempalace` don't break — they redirect with a one-line prompt.

### Strategic rationale

The two old skills both started with a discovery pass over the same inputs (git log, package manifests, existing docs, file tree). Running them in sequence meant two separate scans and two LLM passes — and the outputs sometimes told slightly different stories about the same codebase. v3.2.0's `scan-architecture.sh` already extracted the architecture-discovery half into bash. v3.3.0 adds the symmetric `gather-seed-signals.sh` and uses both to drive a single Architect skill, so the two outputs are forced to agree.

Performance: discovery is now ~0.5s for `scan-architecture.sh` + ~0.5s for `gather-seed-signals.sh` = ~1s of bash, vs. two separate Sonnet-dispatched runs of file globbing in v2.x.

### Migration

After merging develop → main:

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…and restart your Claude session.

- New project intake: `/vladyslav:ingest` instead of `/vladyslav:analyze-project` + `/vladyslav:seed-mempalace`.
- Old commands still work but redirect. Existing automation that calls them will keep working until v4.0.

---

## v3.2.1 — 2026-05-11

Pure-docs release synchronising documentation to the v3.0/3.1/3.2 reality. No code or skill behaviour changes.

### Changed

- **`docs/architecture/system.md`** — rewritten end-to-end. Added new `Skill Taxonomy` section documenting the three patterns (Architect / Engineer light bash-driven / Engineer light Opus inline) and the deprecated Heavy Engineer. Updated the `Helper Scripts` table from 9 entries to all 13 active scripts (added `scaffold-project.sh`, `attach-project.sh`, `pre-release-checks.sh`, `extract-tokens.sh`, `scan-architecture.sh`). Added `Slash-command dispatch (v2.3.2+)` section explaining the Glob+Read bypass. Marked the four currently-unused `_shared/references/` files as reserved-for-future-use.
- **`README.md`** — replaced the v2.0 "One-Terminal Workflow" table with v3.x classification (Architect 9 / Engineer light bash 3 / Engineer light Opus 5). Added a deprecation note for Heavy Engineer. Updated the Skills table to group skills by pattern with their consuming script.
- **`docs/diagrams/skill-flows.md`** — `init-project` and `attach-project` diagrams now show the v3.x Light Engineer flow (Pre-flight → resolve plugin root → run bash script → parse JSON → summary) instead of the old Heavy Engineer Sonnet dispatch.
- **`docs/diagrams/add-feature-flow.md`** — last v2.x reference ("next Sonnet prompt") replaced with "next-step suggestion" since the two-terminal workflow is gone since v2.0.

### Verified clean (no v2.x stale references)

- `docs/diagrams/fix-bug-flow.md`
- `docs/diagrams/skills-ecosystem.md`
- `docs/diagrams/workflows.md`
- `SkillsManual.md` (Heavy Engineer / Sonnet subagent terms not present)

### Not changed

- No `SKILL.md` files touched.
- No `scripts/` files touched.
- No new behaviour, no version of any helper changed.

### Migration

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…or skip entirely. v3.2.1 only changes documentation — runtime is identical to v3.2.0.

---

## v3.2.0 — 2026-05-11

Targeted architectural cleanup of the 11 remaining (non-v3.0/v3.1) skills, driven by a fresh architect review that identified hidden deterministic work in `design-sync` and `analyze-project` plus a 6-skill duplication of the `_shared/verify-pwd.md` block.

### Added

- **`scripts/extract-tokens.sh`** (~370 lines) — per-platform design-token extractor for `design-sync`. Auto-detects platform via `detect-stack.sh`, then parses iOS `Assets.xcassets/.colorset/Contents.json` + Swift `Color(hex:)` / `Color(red:)` inline literals + SwiftUI `.font(.system(...))` + SF Symbols + `.padding(N)` (iOS); CSS variables + inline hex + `tailwind.config` (web); Android `colors.xml` (Kotlin). Emits JSON with colors / typography / icons / spacing arrays sorted by usage count. The LLM's job in `design-sync` becomes purely judgemental (drift vs canonical), not mechanical grep.
- **`scripts/scan-architecture.sh`** (~280 lines) — architecture inventory scanner for `analyze-project`. Emits JSON of `{stacks, entry_points, routes, schema_files, deps, doc_files}`. Detects routes for FastAPI, Flask, Express, and Go stdlib 1.22+. Detects schemas for SQL migrations, Prisma, Drizzle, Alembic.

Total `scripts/` helpers now: **13**.

### Changed

**Six skills now reference `_shared/references/verify-pwd.md`** instead of inlining the 11-22-line wing-derivation + path-validation block:
- `add-feature` (Step 0.1) — 295 → 278 lines (kept skill-specific "extract project name from CLAUDE.md")
- `fix-bug` (Step 0) — 118 → 104 lines
- `discover` (Step 1) — 141 → 146 lines (verify-pwd ref + section-status.sh wiring +5 net)
- `design-sync` (Step 0) — 292 → 247 lines (-45, also dedup of duplicated drift steps after extract-tokens wiring)
- `design-page` (Step 0) — 211 → 210 lines
- `seed-mempalace` (Step 1) — 164 → 154 lines (kept skill-specific multi-source project-name fallback)

**`design-sync` extracted tokens via bash:** Steps 3-5 (was ~80 lines of per-platform grep instructions) → Step 3 (run `extract-tokens.sh`) + Step 4 (drift analysis applied to JSON output, ~12 lines). The semantic "what is canonical vs drift" judgement stays LLM, but discovery (the ~80% mechanical portion) is now 0-token deterministic.

**`analyze-project` extracted architecture via bash:** Step 2 (architecture scan) now calls `scan-architecture.sh` and consumes JSON instead of inlined "read package.json, ls directories, grep for routes" instructions.

**`discover` wired existing helpers:**
- Step 3 "skip done" mode now calls `scripts/section-status.sh docs/product/start-project.md` for filled-vs-pending JSON instead of manual scan.
- Step 3 iOS auto-detection now calls `scripts/detect-stack.sh` instead of manual `swift/ + *.xcodeproj` checks.
- Step 9 verification re-uses `section-status.sh`.

**`discover-apple-check` wired `detect-stack.sh`:** Step 1 iOS verification replaced manual 5-signal check with single script call.

### Skill sizes (post-v3.2.0)

| Skill | v3.1.x | v3.2.0 | Δ |
|---|---|---|---|
| add-feature | 295 | 278 | −17 |
| fix-bug | 118 | 104 | −14 |
| discover | 141 | 146 | +5 |
| design-sync | 292 | 247 | **−45** |
| design-page | 211 | 210 | −1 |
| seed-mempalace | 164 | 154 | −10 |
| analyze-project | 90 | 95 | +5 |
| discover-apple-check | 181 | 177 | −4 |
| **Net** | **1492** | **1411** | **−81** |

### Skills NOT migrated in v3.2.0

`swiftui-pro`, `compact-save`, `help` — already minimal and right-shaped. Verified leave-alone in the architect review.

### Deferred to v3.3.0 (roadmap)

- **`ingest` unification** — collapse `analyze-project` + `seed-mempalace` into a single skill that runs `scan-architecture.sh` + a future `gather-seed-signals.sh` once and emits both architecture docs AND MemPalace seed-records from one source-of-truth pass. Naturally falls out of v3.2.0's groundwork.
- **`roadmap-ops.sh`** — lift `add-feature` Step 9's roadmap marking (`sed [ ] → [x]`) into a dedicated bash helper. Lower ROI; bundled into v3.3.0.
- **Architect report shared template** (`_shared/references/architect-report.md`) — standardise the `✓ Architect report` shape across 8 Architect skills. Cosmetic, low priority.

### Migration

After merging develop → main:

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…and restart your Claude session. All migrated skills work identically from the user's perspective — same Q&A, same outputs, the difference is invisible except `design-sync` and `analyze-project` are now much faster.

---

## v3.1.0 — 2026-05-11

Heavy → Light Engineer migration for four more skills, following the v3.0.0 `init-project` pattern.

### Changed — `attach-project` (Heavy → Light Engineer)

- **New script `scripts/attach-project.sh`** (~370 lines). Auto-detects stack via `scripts/detect-stack.sh`, then writes only missing files (skip-if-exists semantics): `CLAUDE.md`, `.claude/agents/{docs-agent,code-review-agent}.md`, `.claude/settings.json`, `docs/{architecture/system,product/prd,plans/tasks}.md` stubs, per-stack `.gitignore` appendices (Python / Go / Flutter / Swift / Kotlin / Node / Web / private-mode), per-stack placeholder directories. Idempotent. Does NOT init git (project already has version control) and does NOT scaffold backend code (that's `init-project`'s job).
- **`skills/attach-project/SKILL.md`** rewritten as **Engineer (light)** — 162 → 122 lines. Pre-flight Q&A + Bash invocation + JSON-based summary.
- Smoke verified: Python project (9 files, 0.5s) · idempotent re-run (0 files written, all skipped) · Swift project (auto-detected `ios`).

### Changed — `pre-release-check` (Heavy → Light Engineer + thin LLM)

- **New script `scripts/pre-release-checks.sh`** (~330 lines). Runs the 5 cross-platform checks deterministically: tasks completion (counts `[x]`/`[ ]` in tasks.md), tests (auto-detect runner — pytest / go test / xcodebuild test / npm test — and execute with 300s timeout), config sanity (REPLACE_ME / `*to be filled*` placeholders via `grep-replace-me.sh`), docs sync (stub detection + auto-changelog via `changelog-from-git.sh`), translations (platform-aware detection). Writes `docs/release/pre-release-report-<date>.md` and emits JSON with overall result.
- **`skills/pre-release-check/SKILL.md`** rewritten as **Engineer (light)** — 240 → 112 lines. Cross-platform checks run as bash; only iOS Apple App Store review (Check 6) requires LLM and is dispatched to the `apple-appstore-reviewer` skill conditionally on `platform=ios`. The model only contributes a one-line "overall reason" synthesis at the bottom of the summary.
- Smoke verified on this repo: 0.6s, JSON output correct, report written.

### Changed — `write-*` family (Heavy → Light Engineer, Opus inline)

- **`skills/write-user-stories/SKILL.md`** — 125 → 85 lines.
- **`skills/write-test-docs/SKILL.md`** — 134 → 137 lines (output structure expanded, but boilerplate removed).
- **`skills/write-project-docs/SKILL.md`** — 208 → 194 lines.
- All three now run **inline in Opus main** — no Sonnet subagent dispatch, no YAML return contract, no allowlist enforcement boilerplate. Content generation legitimately needs LLM (translating code/PRD into product-language stories, test plans, READMEs), but the dispatch overhead added cost without value. Each skill now reads inputs → generates inline → writes one to three known output files → renders a summary.

### Aggregate impact

| Skill | v2.3.x lines | v3.1.0 lines | Speed (scaffold step) | Tokens (scaffold step) |
|---|---|---|---|---|
| `init-project` (v3.0.0) | 379 | 183 | ~1s | 0 |
| `attach-project` | 162 | 122 | ~0.5s | 0 |
| `pre-release-check` | 240 | 112 | ~0.6s (5 checks) | 0 |
| `write-user-stories` | 125 | 85 | LLM-bound (inline) | full generation cost |
| `write-test-docs` | 134 | 137 | LLM-bound (inline) | full generation cost |
| `write-project-docs` | 208 | 194 | LLM-bound (inline) | full generation cost |

For the three deterministic skills (`init-project`, `attach-project`, `pre-release-check`): **~8 minutes total runtime in v2.x → ~2 seconds total in v3.1.0** when used end-to-end on a new project. Token cost for those mechanical steps: ~50k → 0.

For the three `write-*` skills: same generation work, ~50 lines of boilerplate eliminated per skill, dispatch overhead (~30s round-trip) removed.

### New scripts

- `scripts/attach-project.sh` — full attach-project scaffolder
- `scripts/pre-release-checks.sh` — 5 deterministic release checks

These join the v2.3.0 / v3.0.0 helpers (`detect-stack.sh`, `derive-wing.sh`, `init-git-repo.sh`, `write-stub.sh`, `grep-replace-me.sh`, `parse-yaml-return.sh`, `section-status.sh`, `changelog-from-git.sh`, `check-plan-scope.sh`, `scaffold-project.sh`) — total **11 bash helpers** in `scripts/`.

### Skills NOT migrated in v3.1.0

`add-feature`, `fix-bug`, `discover`, `discover-apple-check`, `design-sync`, `design-page`, `analyze-project`, `swiftui-pro`, `seed-mempalace`, `compact-save`, `help` — these either need genuine LLM reasoning throughout (semantic decisions on existing code, brainstorm composition, design judgement) or are already lean utility/reference skills.

### Migration

After merging to `main`:

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…and restart your Claude session. All five migrated skills work identically from the user's perspective — same Q&A, same outputs. The difference is invisible except for the dramatic speedup.

---

## v3.0.0 — 2026-05-11

### BREAKING — `init-project` is no longer a Heavy Engineer skill

The scaffolding step in `init-project` (mkdir + cp + sed + git init) was being executed by a dispatched Sonnet subagent in v2.x. That was **architecturally wrong**: none of those operations need LLM thinking. A real-world v2.3.2 smoke run cost **~43k tokens and 8 minutes 34 seconds** to do work that pure bash finishes in **~1 second with 0 tokens**.

In v3.0.0 the subagent dispatch is removed entirely.

### Changed

- **New script `scripts/scaffold-project.sh`** (~580 lines of POSIX bash, no python/node dependency). Accepts every pre-flight parameter via CLI flags and writes the complete scaffold deterministically — base directories, base `.gitignore` with stack-specific appendices, backend files (Python or Go), frontend files (Swift via `xcodegen`, Flutter/Kotlin placeholders, "other" stacks), CLAUDE.md, agent definitions, doc stubs, optional nginx config when a domain is set, optional private-mode gitignore extras. Emits JSON `{status, files_written, files_skipped, warnings, error?}` to stdout. Idempotent: re-running on an existing project skips pre-existing files and reports them in `files_skipped`.

- **`skills/init-project/SKILL.md` rewritten as Engineer (light)** — 379 → 183 lines. Steps are now:
  1. Pre-flight Q&A (Opus main) — unchanged in user experience, identical questions.
  2. Resolve plugin root (via Glob in cache or development clone).
  3. Run `scripts/scaffold-project.sh` with collected parameters (via Bash tool).
  4. Parse the JSON output and render a one-screen summary.

- **No more Sonnet subagent for init-project.** The Heavy Engineer dispatch pattern (preamble, YAML return contract, allowlist enforcement) is retained for skills where it genuinely earns its cost (`add-feature`, `pre-release-check`, `discover` — these need semantic decisions on existing code). For `init-project` the cost was 100% waste.

- **`skills/init-project/references/stack-*.md` retained** as human-readable historical reference. They are no longer composed into a subagent prompt — the same logic now lives directly in `scaffold-project.sh`. They will be removed in v3.1.0 unless they prove useful as documentation.

### Performance

| | v2.x | v3.0.0 | Δ |
|---|---|---|---|
| Time | ~8m 34s | ~1 sec | **−99.8%** |
| Tokens | ~43,000 | 0 (bash) | **−100%** for the scaffold step |
| LLM model needed | Opus + Sonnet | Opus only (for Q&A) | — |

Pre-flight Q&A in Opus main still costs ~2-3k tokens (unchanged).

### Migration

For users on v2.x — no action required. After `/plugin update vladyslav` and a fresh `cla` session, `/vladyslav:init-project` Just Works: same Q&A as before, just instant scaffold instead of an 8-minute pause.

For other heavy-engineer skills (`attach-project`, `write-*`, `pre-release-check`) — the same Heavy → Light migration is on the v3.1.0 roadmap. `attach-project` is the next highest-priority candidate (also ~95% deterministic). `write-*` skills genuinely need LLM for generation but the file-writing wrapper can be lifted out. `pre-release-check` has deterministic checks (test runner, grep, git log) and a small interpretive layer; only the latter needs the model.

---

## v2.3.2 — 2026-05-10

### Fixed

- **Bypass Skill tool dispatch in all 17 commands.** During v2.3.1 smoke-tests, `/vladyslav:<name>` slash-commands were still showing `Successfully loaded skill` repeatedly with no SKILL.md body delivered to the model. Root cause: in current Claude Code (2.1.138), the `Skill` tool — which gets invoked when a command body says `Invoke the X skill` — returns a launch acknowledgement but does not actually deliver the skill body into the conversation. v2.3.1 fixed the pre-existing `disable-model-invocation` block, but did not change this dispatch path.
- All 17 `commands/*.md` rewritten so their bodies tell the model to **read SKILL.md directly via `Glob` + `Read`**, never going through the `Skill` tool. The new pattern is:

  ```
  Locate and read the skill body for vladyslav:<name>. Use the Glob tool with
  pattern '~/.claude/plugins/cache/vladyslav-marketplace/vladyslav/*/skills/<name>/SKILL.md'
  to find it (the version directory varies). If Glob returns no match, fall back to
  '/Volumes/DevSSD/Development/vladyslav-skills/skills/<name>/SKILL.md' (development clone).
  Read the matched file with the Read tool, then follow its instructions exactly from
  top to bottom. Do not call the Skill tool — load the file directly.
  ```

### Migration

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…and restart your Claude session. `/vladyslav:<name>` slash-commands now load SKILL.md content reliably.

---

## v2.3.1 — 2026-05-10

### Fixed

- **Removed `disable-model-invocation: true`** from all 16 `commands/*.md` frontmatter. The original intent (block automatic model-driven skill invocation while keeping explicit slash-commands available) was broken by current Claude Code semantics: the field also blocked the `Skill` tool from delivering the SKILL.md body to the model when a slash-command was used. Result was endless `Successfully loaded skill` echoes with no instructions reaching the model. Removing the field restores normal slash-command behaviour. Skills still self-describe in their `description:` field so the model knows when *not* to invoke automatically.
- `marketplace.json` and `plugin.json` synced to v2.3.1.
- `SkillsManual.md` updated to remove the obsolete policy paragraph.

### Migration

After pulling this version, run inside Claude Code:

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…then restart your Claude session. Slash-commands like `/vladyslav:init-project` will now load the skill body normally.

---

## v2.3.0 — 2026-05-10

Strategic refactor pass: deduplicate boilerplate across heavy-engineer skills, lift deterministic operations into bash scripts, propagate the modular Hybrid layout introduced for `init-project` to the next three largest skills.

### Added

- **`skills/_shared/references/`** — five shared reference files used across 6 heavy-engineer skills:
  - `subagent-preamble.md` — Sonnet subagent role + five mandatory rules (allowlist, no AskUserQuestion, plugin assets, idempotency, reporting)
  - `yaml-return.md` — structured YAML return contract (single source of truth for `status` / `files_written` / `scope_expansion_required` / etc.)
  - `present-summary.md` — orchestrator-side rendering for the four `status` branches plus re-dispatch flow
  - `mempalace-record.md` — required `[WHAT] [WHY] [FILES] [DATE]` record shape and room-type rules
  - `verify-pwd.md` — Step 0.1 contract for architect skills: `CLAUDE.md` check + canonical wing derivation

- **`scripts/` directory** — 9 portable bash helpers replacing deterministic in-skill instructions:
  - `detect-stack.sh` — probes pwd → JSON describing detected stacks
  - `derive-wing.sh` — canonical MemPalace wing name (eliminates case-mismatch bugs)
  - `write-stub.sh` — idempotent placeholder Markdown writer
  - `init-git-repo.sh` — idempotent `git init` + initial commit
  - `grep-replace-me.sh` — quote-safe placeholder grep
  - `parse-yaml-return.sh` — extracts and validates the last fenced ```yaml block from a subagent response
  - `section-status.sh` — scans `start-project.md` for filled vs pending sections
  - `changelog-from-git.sh` — drafts a Markdown CHANGELOG section from `git log`
  - `check-plan-scope.sh` — verifies an `add-feature` Auto-mode diff stays within the approved plan

- **New per-skill references** for the three additional Hybrid refactors:
  - `skills/add-feature/references/auto-mode.md` — Auto-mode-specific Steps 6-8 plus approval map
  - `skills/pre-release-check/references/ios-apple-check.md` — iOS-only Apple-review block
  - `skills/discover/references/discover-section.md` — generic per-section flow plus per-step parameter blocks for Steps 4-7

### Changed

- **All 17 skill descriptions shortened** in frontmatter — total 3437 → 2034 chars (~350 token saving in system prompt). Top three reductions: `design-sync` (375 → 173), `discover-apple-check` (321 → 154), `design-page` (300 → 154).
- **Six heavy-engineer SKILL.md** files refactored to compose from shared references instead of carrying inline boilerplate:
  - `init-project` 439 → 379 lines
  - `attach-project` 215 → 162
  - `write-user-stories` 172 → 125
  - `write-test-docs` 183 → 134
  - `write-project-docs` 259 → 208
  - `pre-release-check` 370 → 320 (further reduced to 240 in the Hybrid pass below)
- **Three additional Hybrid layouts** (SKILL.md + `references/` per skill, following the `init-project` pattern):
  - `add-feature` 388 → 294 lines (Auto-mode → `references/auto-mode.md`)
  - `pre-release-check` 320 → 240 (iOS Apple-check → `references/ios-apple-check.md`)
  - `discover` 330 → 140 (per-section flow → `references/discover-section.md`)
- `docs/architecture/system.md` updated with new `Shared references` and `Helper Scripts` sub-sections under Skill Layout.

### Strategic notes

- Combined effect: **~10k tokens of duplication removed** from skill bodies + **~350 tokens shaved from the system-prompt skill listing**. The latter is what unblocks `vladyslav:*` skills from the `descriptions dropped` budget when many other plugins are installed.
- Lean and untouched (already well-factored): `compact-save` (60 lines), `swiftui-pro` (61), `analyze-project` (89), `help` (106), `fix-bug` (117).
- NOT collapsed: `init-project` ↔ `attach-project` (workflows different — clean-slate vs append-only). `add-feature` ↔ `fix-bug` (phases and ordering differ enough that a shared core would leak).

---

## v2.2.0 — 2026-05-09

### Added

- `.claude/hooks/session-start.sh` — silent SessionStart hook reminding which MemPalace wing this project uses.
- `.claude/hooks/lint-skill-frontmatter.sh` — PostToolUse hook validating SKILL.md frontmatter (`name`, `description`, `Type:`) on every Edit/Write/MultiEdit. Pure bash + awk, no python/node dependency.
- `.claude/hooks/check-docs-sync.sh` — Stop hook that blocks turn-stop with `exit 2` if plugin internals (`skills/`, `.claude/hooks/`, `.claude-plugin/`, `commands/`, `examples/`) were modified without a matching update to `docs/`, `CHANGELOG.md`, `CLAUDE.md`, `README.md`, or `SkillsManual.md`. Loop-safe via `stop_hook_active` flag. Forces documentation to stay in sync with code automatically.
- `examples/mcp-config.example.json` — copy-paste MCP config block for the MemPalace dependency. Linked from the README Requirements section.
- CLAUDE.md sections: `Review Checklist`, `Skill Testing`, `Hooks`. The checklist enumerates the rules that the new lint hook enforces automatically and the rules that remain manual.

### Changed

- **`init-project` skill restructured into the modular `SKILL.md` + `references/` + `assets/` layout (Hybrid refactor).**
  - Stack-specific scaffolding instructions extracted into `skills/init-project/references/stack-{python,go,swift,flutter,kotlin,other}.md` and `references/backend-shared.md`. Each fragment is composed into the subagent prompt only when its stack was selected in pre-flight.
  - Exclusive file templates moved from the repo-root `templates/` into `skills/init-project/assets/` (preserving the `swift/`, `backend/`, `infra/`, `docs/operations/` subtree). Only `templates/DesignSystem.md` stays at the root because it is shared with the `design-sync` skill.
  - `SKILL.md` shrunk from 621 lines to 439 — pre-flight Q&A and cross-stack scaffolding (CLAUDE.md template, agents, doc stubs, git init) remain in place; everything stack-specific now loads on demand.
  - Subagent dispatch pattern preserved: pre-flight in Opus main → Sonnet subagent writes the scaffold → YAML return contract. No user-facing behavioural change.
  - Added new `Step 1: Compose stack fragments` to the Process section, documenting how Opus main reads the relevant `references/` files and substitutes them into the `<STACK_FRAGMENTS>` placeholder of the subagent prompt.

### Fixed

- `skills/help/SKILL.md` and `skills/swiftui-pro/SKILL.md` were missing the `Type:` line required by `CLAUDE.md` working rules. Added `Type: Engineer (light)` and `Type: Architect` respectively.
- README requirements line previously claimed "9 skills" require MemPalace; the actual list is 8.

---

## v2.0.0 — 2026-05-06

### BREAKING

- **Drop two-terminal workflow.** Single-terminal: Opus main session + Sonnet subagent dispatch for execution work. Manual `/model` switching no longer needed.
- **Architect skills** no longer print `━━━ Next (Sonnet terminal) ━━━` handoff blocks. They run interactively in Opus main and end with a plain "Next steps:" list.
- **Heavy Engineer skills** (`write-test-docs`, `write-project-docs`, `write-user-stories`, `attach-project`, `init-project`, `pre-release-check`) now wrap their body in a Sonnet subagent dispatched from Opus main, with pre-flight Q&A in the main session and a YAML-formatted return contract enforcing a strict file allowlist.
- **Light Engineer skills** (`stash`, `unstash`) keep inline behavior in main thread (~30s utility operations; dispatch overhead would exceed the work).
- Architect skills with internal `Agent(...)` dispatches now annotate every dispatch with explicit `model=` (`"sonnet"` for executor work, `"opus"` for synthesis/research). Affected: `add-feature` (5 dispatches → sonnet), `design-page` (1 dispatch → opus).
- Skill `Type:` headers updated: `Architect (Opus)` → `Architect`; `Engineer (Sonnet)` → `Engineer` (heavy) or `Engineer (light)` (stash, unstash).
- `commands/*.md` files no longer contain `/model …` switch instructions.

### Migration

If you were on the v1.x two-terminal workflow:
1. Close your "Engineer" terminal.
2. Run all skills from a single Opus session.
3. No code changes on your side — skills handle dispatching internally.

### Documentation

- `README.md`, `CLAUDE.md`, `skills/help/SKILL.md` updated to describe the one-terminal workflow.
- New design doc: `docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md`.
- New plan doc: `docs/superpowers/plans/2026-05-06-opus-subagent-dispatch.md`.

---

## v1.8.0 — 2026-04-30

Roadmap gate for `add-feature` and `init-project`.
