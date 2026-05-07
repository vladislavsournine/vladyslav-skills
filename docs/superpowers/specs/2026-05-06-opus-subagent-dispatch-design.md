# Design: One-Terminal Workflow via Opus Main + Sonnet Subagent Dispatch

> Created: 2026-05-06
> Status: Proposed
> Scope: All 16 skills in `vladyslav-skills` plugin + `README.md` + project `CLAUDE.md` + `docs/architecture/system.md` + `.claude-plugin/plugin.json` (v2.0.0).

## Problem

Current workflow requires manual `/model` switching between Opus (Architect skills) and Sonnet (Engineer skills), often across two terminals. Every skill begins with a `Step 0: Verify model` instruction telling the user to run `/model opus` or `/model sonnet`. Architect skills end with a `━━━ Next (Sonnet terminal) ━━━` block listing the next slash command for the user to copy-paste into the Sonnet terminal.

This produces three pain points:

1. **Manual model switching every skill invocation.** The user has to remember which model each skill expects.
2. **Two-terminal context duplication.** Architect terminal and Engineer terminal both load the same project context, doubling token spend on session loading.
3. **Handoff friction.** Each terminal hop loses live conversation state — only the prepared prompt makes it across.

## Decision

Single-terminal workflow:

- **Main session = Opus** (assumed default; user sets once or runs Claude Code in Opus).
- **Heavy execution work** runs in Sonnet subagents dispatched via the `Agent` tool with `model="sonnet"`.
- **Heavy synthesis/research work** stays Opus (either main thread or `model="opus"` subagent).
- All `Step 0: /model …` instructions removed.
- All `━━━ Next (Sonnet terminal) ━━━` handoff blocks removed.

The user no longer chooses Opus or Sonnet manually. Skills know where to delegate.

## Skill Categorization (After Refactor)

| Category | Count | Skills | Where Work Runs |
|----------|-------|--------|-----------------|
| **Architect** | 8 | `add-feature`, `fix-bug`, `analyze-project`, `design-sync`, `discover`, `discover-apple-check`, `design-page`, `seed-mempalace` | Opus main (interactive + synthesis). Internal `Agent` dispatches annotated explicitly with `model="sonnet"` (executor work) or `model="opus"` (heavy synthesis). |
| **Heavy Engineer** | 6 | `write-test-docs`, `write-project-docs`, `write-user-stories`, `attach-project`, `init-project`, `pre-release-check` | Pre-flight in Opus main → entire body executes in Sonnet subagent → summary parsed and presented in Opus main. |
| **Light Engineer** | 2 | `stash`, `unstash` | Opus main, no dispatch. Body executes inline (~30s operation, dispatch overhead would exceed work). |
| **Reference** | 2 | `help`, `swiftui-pro` | No Type. `help` is documentation only (no model concerns); `swiftui-pro` is a third-party review skill invoked via Skill tool from inside other skills (runs in caller's thread). |

## Heavy Engineer Skill Structure

Each Heavy Engineer SKILL.md follows this template:

```markdown
**Type:** Engineer

## Process

### Step 0: Pre-flight (Opus main)

[Skill-specific interactive checks:
  - Read CLAUDE.md, identify project name + canonical wing.
  - Verify required input files exist; if missing → ask user.
  - Resolve any ambiguity that requires user dialog.
  - Compose dispatch context.]

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool:
- subagent_type: "general-purpose"
- model: "sonnet"
- description: "<short>"
- prompt: <subagent prompt template, filled with pre-flight outputs>

### Step 2: Present summary

Parse subagent return YAML.
Print human-readable summary to user.
Suggest next step (e.g., /vladyslav:pre-release-check).

---

## Subagent prompt template

[Self-contained briefing — subagent has no conversation history. Includes:
  - Project context (working dir, key facts from CLAUDE.md)
  - Verified inputs (paths from pre-flight, content snippets)
  - Task instructions (the original skill body)
  - Output allowlist (exact files allowed to create/modify)
  - Required return YAML structure]
```

### Subagent Return Contract (YAML)

The prompt template requires the subagent to return a YAML block of this shape:

```yaml
status: success | partial | scope_expansion_required | error
files_written:
  - path: <relative path>
    action: created | modified | replaced
files_skipped: []
warnings:
  - <non-blocking note>
scope_expansion_required:
  - path: <path outside allowlist>
    reason: <why subagent wanted to write there>
next_step_suggestion: <slash command or empty>
summary: |
  <1-3 sentence human-readable description>
```

The Opus main thread parses this and renders one of three UX flows:

**Success:**
```
✓ Engineer summary (write-test-docs)
  Wrote: docs/testing/test-plan.md, docs/testing/manual-qa.md
  Warnings: PRD has no security section — coverage marked 'partial'
  Files unstaged. Review before commit.
  Next: /vladyslav:pre-release-check
```

**Scope expansion:**
```
⚠ Engineer halted (write-test-docs)
  Subagent wanted to modify docs/product/prd.md (outside allowlist).
  Reason: needed to add test-coverage section

  Options:
    1. Approve — re-dispatch with extended allowlist
    2. Skip — leave PRD untouched, mark coverage 'partial'
    3. Abort
```

**Error:**
```
✗ Engineer failed (write-test-docs)
  Error: subagent could not parse docs/product/user-stories.md
  Auto-stash created: stash:<id>
```

### Allowlist Enforcement

The subagent prompt template includes a hard rule:

> "You may only CREATE or MODIFY these files: `<allowlist>`. If you discover need to touch a file outside this list — STOP, do NOT make the change, return `status: scope_expansion_required` with the path and reason."

This is the same guard-rail pattern already used in `add-feature` Step 6 (Auto mode parallel agents) — reused here.

### Fallback Parsing

If the subagent ignores the YAML format, the Opus main thread falls back to:

- Treat the entire output as `summary` text.
- Mark `status: unknown`.
- Tell the user: "Subagent returned unstructured response, please review files manually before proceeding. Files on disk: <git status output>".

This keeps the skill resilient to subagent format drift.

### Auto-Stash on Engineer Failure

When `status: error`, Opus main best-effort creates one auto-stash via `vladyslav:stash` skill (Light Engineer, runs in main thread) capturing:
- skill name
- pre-flight inputs
- subagent error message

If `mempalace_add_drawer` fails inside auto-stash, print a warning and continue. Auto-stash never blocks error reporting.

## Architect Skill Changes

For all 8 Architect skills:

1. **Header:** `**Type:** Architect (Opus)` → `**Type:** Architect`
2. **Step 0:** Remove "Check current model. If not Opus, switch: `/model opus`" (or equivalent).
3. **End-of-skill report:** Remove `━━━ Next (Sonnet terminal) ━━━━━━━━━━━━━━━` blocks. Replace with simple "Next: `/vladyslav:<name>`" suggestions (no terminal switching language).

For Architect skills with internal `Agent` dispatches, annotate each dispatch with explicit `model`:

| Skill | Internal Dispatch | model= |
|-------|-------------------|--------|
| `add-feature` | Step 6 Agent A (test writer) | `sonnet` |
| `add-feature` | Step 6 Agent B (impl writer) | `sonnet` |
| `add-feature` | Step 6.5 `pr-review-toolkit:code-reviewer` | `sonnet` |
| `add-feature` | Step 6.5 `pr-review-toolkit:silent-failure-hunter` | `sonnet` |
| `discover` | 4 parallel research subagents | `opus` (heavy thinking, do NOT downgrade) |
| `design-page` | Per-screen design subagents | `opus` (creative decisions) |
| `fix-bug` | (none — uses Skill tool for TDD/debug, runs in main thread) | n/a — intentional: bug diagnosis benefits from Opus reasoning (root cause vs symptom). Cost trade-off accepted. |
| `analyze-project`, `design-sync`, `seed-mempalace`, `discover-apple-check` | (none — synthesis runs in main thread) | n/a |

### New Project Rule (CLAUDE.md)

Add to project `CLAUDE.md` working rules:

> When an architect skill dispatches a subagent via `Agent`, it MUST specify `model` explicitly. Use `model="sonnet"` for executor-type work (write tests, write impl, run review/security checks). Use `model="opus"` for synthesis/research work (design decisions, deep analysis, multi-source research).

## Light Engineer Skill Changes

For `stash` and `unstash`:

1. **Header:** `**Type:** Engineer (Sonnet)` → `**Type:** Engineer (light)`
2. **Step 0:** Remove "Check current model. If not Sonnet, switch: `/model sonnet`".
3. Body unchanged. Runs in main thread (Opus). 30-second operation; Opus pricing acceptable.

## Files Changed

| File | Change |
|------|--------|
| `skills/write-test-docs/SKILL.md` | Restructure to Heavy Engineer template (Step 0/1/2 + subagent prompt template). |
| `skills/write-project-docs/SKILL.md` | Same. |
| `skills/write-user-stories/SKILL.md` | Same. |
| `skills/attach-project/SKILL.md` | Same. |
| `skills/init-project/SKILL.md` | Same. |
| `skills/pre-release-check/SKILL.md` | Same. |
| `skills/add-feature/SKILL.md` | Drop Step 0 model switch + handoff block. Annotate Agent dispatches with `model="sonnet"`. |
| `skills/fix-bug/SKILL.md` | Drop Step 0 model switch + handoff block. |
| `skills/analyze-project/SKILL.md` | Drop Step 0 model switch + handoff block. |
| `skills/design-sync/SKILL.md` | Drop Step 0 model switch + handoff block. |
| `skills/discover/SKILL.md` | Drop Step 0 model switch + handoff block. Annotate research Agent dispatches with `model="opus"`. |
| `skills/discover-apple-check/SKILL.md` | Drop Step 0 model switch + handoff block. |
| `skills/design-page/SKILL.md` | Drop Step 0 model switch + handoff block. Annotate per-screen Agent dispatches with `model="opus"`. |
| `skills/seed-mempalace/SKILL.md` | Drop Step 0 model switch + handoff block. |
| `skills/stash/SKILL.md` | Drop Step 0 model switch. Header → `Engineer (light)`. |
| `skills/unstash/SKILL.md` | Same. |
| `skills/help/SKILL.md` | Update frontmatter description (drop "two-terminal workflow" mention). Replace "Two-Terminal Workflow" body section with "One-Terminal Workflow" — Opus main + Sonnet subagents auto-dispatched. |
| `README.md` | Drop two-terminal workflow section. Add one-terminal description: "Run any skill from Opus session. Skills delegate execution work to Sonnet subagents automatically." |
| `CLAUDE.md` (project) | Drop "Architect skills end with a prepared prompt for the Sonnet terminal" rule. Add new rule on explicit `model=` annotation for internal Agent dispatches. |
| `docs/architecture/system.md` | Update if it documents the two-terminal architecture. |
| `.claude-plugin/plugin.json` | Bump version to `2.0.0`. |
| `commands/` | Verify no `/model` hints inside command files; remove if present. |

## Migration Plan (5 Phases, ~6 hours)

### Phase 1 — Pilot (~1.5 hours)

1. Refactor `write-test-docs` to Heavy Engineer template (smallest, simplest pre-flight).
2. Sandbox-test end-to-end: pre-flight asks for missing PRD, dispatch fires Sonnet, files written correctly to allowlist, return YAML parsed, summary rendered.
3. Refactor `analyze-project` to Architect changes (drop Step 0, drop handoff block).
4. Sandbox-test: skill runs in Opus main without prompting for model switch, no handoff block at end.

**Gate:** Both pilots pass before proceeding to Phase 2.

### Phase 2 — Cascade Heavy Engineer (~1.5 hours)

Apply proven pattern to: `write-project-docs`, `write-user-stories`, `attach-project`, `init-project`, `pre-release-check`. Each skill = separate commit. Smoke-test after each.

### Phase 3 — Cascade Architect (~2 hours)

Refactor remaining 7 Architect skills. For `add-feature`, `discover`, `design-page` — also add explicit `model=` parameters per the table above.

### Phase 4 — Light Engineer (~15 min)

Drop `Step 0: /model sonnet` from `stash`, `unstash`. Update header to `Engineer (light)`.

### Phase 5 — Docs + release (~1 hour)

- Update `README.md` (one-terminal description).
- Update project `CLAUDE.md` (drop two-terminal rule, add explicit-`model=` rule).
- Update `docs/architecture/system.md` if needed.
- Verify `commands/` has no `/model` hints.
- Bump `.claude-plugin/plugin.json` to `2.0.0`.
- CHANGELOG entry: `BREAKING: drop two-terminal workflow. Single-terminal Opus main + Sonnet subagents for execution. Manual /model switching no longer needed.`

## Validation Criteria (acceptance gate before merge to develop)

Sandbox-tested on a test project:

| Skill | What to verify |
|-------|----------------|
| `/vladyslav:add-feature` | End-to-end Auto mode. Zero `/model` prompts. Step 6 parallel agents fire with `model="sonnet"`. Step 6.5 review/security agents fire with `model="sonnet"`. Final report has no `━━━ Next (Sonnet terminal) ━━━` block. |
| `/vladyslav:fix-bug` | No terminal handoff at end. |
| `/vladyslav:write-test-docs` | Pre-flight asks for missing PRD. Sonnet subagent writes test-plan.md and manual-qa.md to allowlist. Return YAML parsed. Summary printed. |
| `/vladyslav:stash` | Runs in main thread without dispatch. Completes within seconds. |
| `/vladyslav:discover` | 4 parallel research subagents each fire with `model="opus"` (heavy thinking preserved). |

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Sonnet subagent ignores return YAML format | Fallback parser in Step 2: treat entire output as `summary`, mark `status: unknown`, instruct user to review files manually. |
| Sonnet subagent overspends tokens by searching | Pre-flight passes verified file paths and content snippets in the dispatch prompt — subagent does not need to search. |
| User updates plugin without reading CHANGELOG | v2.0.0 bump signals breaking change; CHANGELOG entry prominent. |
| `add-feature` Auto mode loses existing guard rails (file-count, contract-hash, scope-expansion-keyword) | Guard rails run in Opus main AFTER subagent return — only the `model` parameter changes, not the guard-rail logic. |
| Subagent partially writes files then hits scope expansion | `status: partial` covers this case; both `files_written` and `scope_expansion_required` lists rendered to user. |
| User Ctrl+C during subagent run | Opus main runs `git status` after subagent termination, reports written files (if any). |

## Out of Scope

- Rewriting `stash`/`unstash` as deterministic non-LLM scripts (option C from brainstorming). Possible future optimization, separate refactor, does not block one-terminal goal.
- Cost telemetry / per-skill token tracking. Could be added later if cost analysis shows surprises.
- Backward-compat fallback for users on the old two-terminal flow. Not needed — single-user plugin, breaking change in v2.0.0.
