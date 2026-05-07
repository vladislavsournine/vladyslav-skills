# Opus Subagent Dispatch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor all 16 skills in `vladyslav-skills` plugin to eliminate manual `/model` switching. Architect skills run in Opus main; Heavy Engineer skills wrap their body in Sonnet-subagent dispatch with pre-flight Q&A in Opus main; Light Engineer skills (`stash`, `unstash`) stay inline in main thread.

**Architecture:** Pre-flight checks happen interactively in Opus main session. Heavy Engineer skill bodies execute inside `Agent(model="sonnet")` dispatches with strict file allowlists and a YAML-formatted return contract. Architect skills annotate every internal `Agent(...)` call with explicit `model=` parameter. Two-terminal handoff blocks are removed from all skills.

**Tech Stack:** Markdown SKILL.md files, JSON plugin manifest, bash for verification grep checks.

**Spec:** `docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md`

**Branch:** `feature/opus-subagent-dispatch` (already created)

---

## Verification Approach (TDD via grep)

Skills are markdown — no traditional test framework. Each task uses **grep-based assertions** as its "test":

- **Pre-condition** (before refactor): grep finds the old pattern (e.g., `/model opus` step). This is the "failing test" — it asserts the new state has been reached, but the new state hasn't been applied yet, so the assertion fails.
- **Refactor step**: edit the SKILL.md.
- **Post-condition** (after refactor): grep no longer finds the old pattern AND finds the new pattern. The assertion now passes.

Each Heavy Engineer task additionally includes a manual sandbox check (run the skill end-to-end in a test project, verify pre-flight + dispatch + summary work).

---

## Phase 1 — Pilot (~1.5 hours)

Refactor one Heavy Engineer skill (`write-test-docs`) and one Architect skill (`analyze-project`) end-to-end. Validate the patterns work before cascading to the remaining 14 skills.

---

### Task 1: Refactor `write-test-docs` (Heavy Engineer pilot)

**Files:**
- Modify: `skills/write-test-docs/SKILL.md` (full body rewrite)

- [ ] **Step 1: Verify pre-condition (old pattern present)**

Run:
```bash
grep -E "Step 0: Verify model|/model sonnet|━━━ Next \(Sonnet terminal\)" skills/write-test-docs/SKILL.md
```
Expected: matches all 3 patterns (skill currently has model switch + handoff block).

- [ ] **Step 2: Replace SKILL.md with new Heavy Engineer template**

Replace the entire content of `skills/write-test-docs/SKILL.md` with:

````markdown
---
name: write-test-docs
description: Use when test documentation is missing or outdated - generates test plan with coverage targets and manual QA checklist from PRD and user stories
---

# Write Test Docs

## Overview

Generate test plan and manual QA checklist from PRD, user stories, and architecture docs.

**Type:** Engineer

## Process

### Step 0: Pre-flight (Opus main)

Interactive checks before dispatching the subagent.

1. Read `CLAUDE.md` in `pwd`. If missing → STOP: "No CLAUDE.md found in current directory. Are you in the right project?". Otherwise extract project name.

2. Check input files:
   - `docs/product/prd.md` — required
   - `docs/product/user-stories.md` — required
   - `docs/architecture/system.md` — optional
   - `docs/architecture/api.md` — optional

3. For each missing **required** file, ask user:
   > "Required input `<path>` is missing. Options: (a) create stub now / (b) abort. Which?"
   - On abort → exit cleanly, no dispatch.
   - On stub → create a placeholder file (`# <Title>\n\n*to be filled*\n`), proceed.

4. Read content of available input files. Record paths and content snippets.

5. Compose dispatch context (project name + verified file paths + content snippets).

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Generate test plan + QA checklist"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs>`

Wait for return.

### Step 2: Present summary

Parse the YAML block at the end of the subagent's response.

**If parse fails** → print the full subagent output, run `git status --short`, tell user: "Subagent returned unstructured response. Files on disk: `<git status>`. Review manually."

**If parse succeeds**, render based on `status`:

`status: success` →
```
✓ Engineer summary (write-test-docs)
  Wrote: <files_written paths joined>
  Warnings: <warnings, if any>
  Files unstaged. Review before commit.
  Next: <next_step_suggestion>
```

`status: partial` → same as success plus:
```
  Note: <files_skipped> were not generated. See warnings.
```

`status: scope_expansion_required` →
```
⚠ Engineer halted (write-test-docs)
  Subagent wanted to modify <path> (outside allowlist).
  Reason: <reason>

  Options:
    1. Approve — re-dispatch with extended allowlist
    2. Skip — leave file untouched
    3. Abort
```
Wait for user choice; on (1), re-invoke Step 1 with extended allowlist.

`status: error` →
```
✗ Engineer failed (write-test-docs)
  Error: <error message>
```
Best-effort: invoke `vladyslav:stash` skill with `source: "write-test-docs:error"`, `task: "Write test docs"`, `open_question: "Subagent failed: <error>"`. If stash itself fails, log warning, continue.

---

## Subagent prompt template

```
You are a Sonnet subagent dispatched by the `write-test-docs` skill in the `vladyslav-skills` plugin. You have no conversation history with the user — this prompt is your full briefing.

## Project context

Working directory: <pwd>
Project name: <from CLAUDE.md>
Key facts from CLAUDE.md:
<3-5 bullets the pre-flight extracts>

## Verified inputs

docs/product/prd.md:
<content from pre-flight>

docs/product/user-stories.md:
<content from pre-flight>

docs/architecture/system.md (if available):
<content from pre-flight>

docs/architecture/api.md (if available):
<content from pre-flight>

## Your task

Generate two files:

1. `docs/testing/test-plan.md` with sections:
   - Unit Tests (per component, with coverage targets %)
   - Integration Tests (scenario list)
   - Edge Cases (extracted from PRD)

2. `docs/testing/manual-qa.md`:
   - One section per user flow
   - Each section: happy path + error cases + empty state + loading state
   - Device-specific section if mobile project

Use these markdown templates as reference shapes:

```markdown
# Test Plan
## Unit Tests
- [Component]: [what to test] — target: [X]% coverage
## Integration Tests
- [Scenario]: [description]
## Edge Cases (from PRD)
- [Edge case]: [how to test]
```

```markdown
# Manual QA Checklist
## [User Flow Name]
- [ ] Happy path: [steps]
- [ ] Error: [what happens when X fails]
- [ ] Empty state: [what shows when no data]
- [ ] Loading state: [what shows during load]
## Device-Specific (if mobile)
- [ ] iOS [version]: [checks]
- [ ] Offline mode: [behavior]
```

## Output allowlist

You may ONLY create or modify these files:
- `docs/testing/test-plan.md`
- `docs/testing/manual-qa.md`

If you discover need to touch any other file — STOP, do NOT make the change, return `status: scope_expansion_required`.

## Required return format

End your response with EXACTLY one YAML block:

```yaml
status: success | partial | scope_expansion_required | error
files_written:
  - path: docs/testing/test-plan.md
    action: created | modified | replaced
  - path: docs/testing/manual-qa.md
    action: created | modified | replaced
files_skipped: []
warnings:
  - <non-blocking issue, if any>
scope_expansion_required:
  - path: <if applicable>
    reason: <if applicable>
next_step_suggestion: /superpowers:test-driven-development
summary: |
  <1-3 sentence human-readable description>
```
```
````

- [ ] **Step 3: Verify post-condition (new pattern in place)**

Run:
```bash
! grep -qE "Step 0: Verify model|/model sonnet|━━━ Next \(Sonnet terminal\)" skills/write-test-docs/SKILL.md \
  && grep -q "Step 0: Pre-flight" skills/write-test-docs/SKILL.md \
  && grep -q "Step 1: Dispatch" skills/write-test-docs/SKILL.md \
  && grep -q "Step 2: Present summary" skills/write-test-docs/SKILL.md \
  && grep -q 'model: "sonnet"' skills/write-test-docs/SKILL.md \
  && echo OK
```
Expected: prints `OK`.

- [ ] **Step 4: Manual sandbox test**

In a test project:
1. Run `/vladyslav:write-test-docs` from an Opus session.
2. Verify Step 0 reports "PRD found" / "PRD missing — stub or abort?" depending on state.
3. Choose to dispatch.
4. Verify the Agent tool was invoked with `model: "sonnet"`.
5. Verify subagent writes only `docs/testing/test-plan.md` and `docs/testing/manual-qa.md`.
6. Verify Step 2 prints the summary in the new format.

If any step fails → fix the SKILL.md, re-test. Do NOT proceed to Task 2 until this works.

- [ ] **Step 5: Commit**

```bash
git add skills/write-test-docs/SKILL.md
git commit -m "refactor(write-test-docs): wrap body in Sonnet subagent dispatch

Heavy Engineer pilot for v2.0 one-terminal workflow. Pre-flight Q&A
runs in Opus main; body executes in Sonnet subagent with file allowlist
and YAML return contract. Removes manual /model switch + handoff block.

Refs: docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md"
```

---

### Task 2: Refactor `analyze-project` (Architect pilot)

**Files:**
- Modify: `skills/analyze-project/SKILL.md` (header, Step 0, end-of-skill block)

- [ ] **Step 1: Verify pre-condition**

Run:
```bash
grep -E "Type:.*Architect \(Opus\)|/model opus|━━━ Next \(.* terminal\)" skills/analyze-project/SKILL.md
```
Expected: matches all 3 patterns.

- [ ] **Step 2: Update header — drop "(Opus)"**

Edit `skills/analyze-project/SKILL.md`:
- Find: `**Type:** Architect (Opus)`
- Replace: `**Type:** Architect`

- [ ] **Step 3: Remove "Step 0: Verify model"**

Edit `skills/analyze-project/SKILL.md`:
- Find the entire `### Step 0: Verify model\n\nCheck current model. If not Opus, switch: \`/model opus\`` block (3 lines including the heading).
- Delete it.
- Renumber subsequent steps if needed (Step 1 → Step 0, etc., OR leave as-is — match existing project style by checking other refactored skills).

Decision: keep step numbers as-is (no renumbering). Step 0 simply removed; the file starts at Step 1.

- [ ] **Step 4: Replace "━━━ Next (... terminal) ━━━" handoff block**

Edit `skills/analyze-project/SKILL.md`:

Find the end-of-skill block that says (approximately):
```
━━━ Next (same Opus terminal) ━━━━━━━━━━━━━
Architecture documented. Ready to add features."

Or for documentation (Sonnet terminal):
━━━ Next (Sonnet terminal) ━━━━━━━━━━━━━━━━
"Analyzed <project>. Architecture docs updated.
```

Replace with:
```
Next steps:
- /vladyslav:add-feature — start adding features
- /vladyslav:write-project-docs — generate human-readable docs
- /vladyslav:write-user-stories — registry of implemented features
```

- [ ] **Step 5: Verify post-condition**

Run:
```bash
! grep -qE "Type:.*Architect \(Opus\)|/model opus|━━━ Next \(" skills/analyze-project/SKILL.md \
  && grep -q "^\*\*Type:\*\* Architect$" skills/analyze-project/SKILL.md \
  && echo OK
```
Expected: `OK`.

- [ ] **Step 6: Manual sandbox test**

In a test project that has CLAUDE.md and some code:
1. Run `/vladyslav:analyze-project` from an Opus session.
2. Verify it does NOT prompt about model.
3. Verify it produces the expected `docs/architecture/system.md` (and friends).
4. Verify the final report does NOT include `━━━ Next (Sonnet terminal) ━━━` block.

- [ ] **Step 7: Commit**

```bash
git add skills/analyze-project/SKILL.md
git commit -m "refactor(analyze-project): drop /model switch + terminal handoff

Architect pilot for v2.0 one-terminal workflow. Skill assumes Opus default;
no internal Agent dispatches yet, so no model= annotations needed.

Refs: docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md"
```

---

### Task 3: Pilot validation gate

- [ ] **Step 1: Sandbox-test BOTH pilots end-to-end**

Pick a test project. Run:
```
/vladyslav:write-test-docs   # Heavy Engineer pilot
/vladyslav:analyze-project   # Architect pilot
```

Verify:
- Neither prompts to switch model.
- `write-test-docs` dispatches Sonnet subagent (visible in tool calls).
- `analyze-project` runs in main thread (no dispatch).
- Both produce expected output files.

If either fails → fix the corresponding SKILL.md, re-test. **Do not proceed to Phase 2 until both pilots pass.**

- [ ] **Step 2: Confirmation checkpoint**

Print to user:
> "Phase 1 pilot validated. Cascading pattern to remaining 14 skills. Starting Phase 2."

---

## Phase 2 — Cascade Heavy Engineer (~1.5 hours)

Apply the proven Heavy Engineer template (from Task 1) to the remaining 5 Heavy Engineer skills. Each skill = one task. Pattern is identical; the differences are: (a) which input files pre-flight checks, (b) what files the subagent is allowed to write, (c) the subagent's task instructions.

For each skill below, follow the **same 5-step structure** as Task 1:
1. Verify pre-condition (`grep -E "Step 0: Verify model|/model sonnet|━━━ Next \(Sonnet terminal\)"` matches).
2. Replace SKILL.md body with new Heavy Engineer template (use Task 1 as structural reference; substitute the skill-specific values from the table below).
3. Verify post-condition.
4. Manual sandbox test (run skill, verify pre-flight + dispatch + summary).
5. Commit with message `refactor(<skill>): wrap body in Sonnet subagent dispatch`.

### Per-skill specifics

| Skill | Pre-flight inputs (required *) | Output allowlist | Subagent task summary |
|-------|-------------------------------|------------------|----------------------|
| `write-project-docs` | `CLAUDE.md`*, `docs/architecture/system.md`*, `docs/architecture/api.md`, existing `README.md`, deployment configs | `README.md`, `docs/onboarding.md`, `docs/deployment.md` | Generate human-readable README, onboarding guide, deployment guide. No AI/skill references inside output. |
| `write-user-stories` | `CLAUDE.md`*, `docs/product/prd.md`*, `docs/architecture/api.md`, `docs/architecture/system.md`, existing `docs/product/user-stories.md` | `docs/product/user-stories.md` | Scan codebase for implemented features; generate registry with status (Done/Partial/Not started). Sort done first. |
| `attach-project` | `pwd` is a project root (`.git/` or recognizable project file)*. Ask user via AskUserQuestion: additional stacks, domain, private mode (these are real interactive Q&A — must be in pre-flight). | Files determined by stack selection (CLAUDE.md, agents, .gitignore, dir structure). Subagent's allowlist must include exactly the files chosen during pre-flight. | Create missing Claude Code structure for the project. Skip every existing file. Append-only on `.gitignore`. |
| `init-project` | New empty directory (or directory user is OK with overwriting)*. AskUserQuestion: project name, stacks, domain, private mode (interactive — pre-flight). | Files generated per stack (potentially many — exact list determined during pre-flight). | Create complete Claude Code project scaffold. Strict adherence to chosen stacks. |
| `pre-release-check` | `CLAUDE.md`*, `docs/plans/tasks.md`*, `docs/testing/manual-qa.md`, `docs/architecture/system.md`, plugin/project config files | (Mostly read-only — produces a verification report.) Allowlist: `docs/release/pre-release-report-<date>.md`. | Run all pre-release verification checks (tasks completed, tests configured, docs synced, translations present, iOS-specific Apple review). Report blockers. |

### Tasks

- [ ] **Task 4:** Refactor `skills/write-project-docs/SKILL.md`. Apply Heavy Engineer template with above specifics.

- [ ] **Task 5:** Refactor `skills/write-user-stories/SKILL.md`. Apply Heavy Engineer template with above specifics.

- [ ] **Task 6:** Refactor `skills/attach-project/SKILL.md`. Apply Heavy Engineer template. Note: pre-flight is heavy here — it includes the AskUserQuestion stack-selection dialog. The subagent's allowlist is computed dynamically from pre-flight outputs.

- [ ] **Task 7:** Refactor `skills/init-project/SKILL.md`. Apply Heavy Engineer template. Note: this is the largest skill (410 lines). Pre-flight contains the full interactive setup dialog (stack selection, project name, domain). The subagent receives a deterministic file-creation task with a precise allowlist.

- [ ] **Task 8:** Refactor `skills/pre-release-check/SKILL.md`. Apply Heavy Engineer template. Note: this skill is mostly read-only verification — the subagent's main output is the report file. Allowlist: just one file.

Each task is a separate commit.

---

## Phase 3 — Cascade Architect (~2 hours)

Apply the Architect template (from Task 2) to the remaining 7 Architect skills. For three of them (`add-feature`, `discover`, `design-page`), additionally annotate every internal `Agent(...)` call with explicit `model=` parameter.

For each Architect skill, follow the **same 5-step structure** as Task 2:
1. Verify pre-condition.
2. Drop `**Type:** Architect (Opus)` → `**Type:** Architect`.
3. Drop `### Step 0: Verify model` block.
4. Replace `━━━ Next (... terminal) ━━━` handoff blocks with simple "Next steps:" suggestions.
5. (For 3 skills) annotate internal `Agent(...)` dispatches with `model=`.
6. Verify post-condition.
7. Manual sandbox test.
8. Commit with message `refactor(<skill>): drop /model switch + terminal handoff`.

---

### Task 9: Refactor `skills/add-feature/SKILL.md` (with `model=` annotations)

**Files:**
- Modify: `skills/add-feature/SKILL.md`

- [ ] **Step 1: Verify pre-condition (old patterns + un-annotated Agent calls)**

```bash
grep -E "Type:.*Architect \(Opus\)|/model opus|━━━ Next \(" skills/add-feature/SKILL.md
```
Expected: matches.

```bash
grep -c '"general-purpose"' skills/add-feature/SKILL.md
```
Expected: ≥4 (Step 6 Agent A, Agent B; Step 6.5 code-reviewer, silent-failure-hunter — possibly more).

- [ ] **Step 2: Apply standard Architect changes**

(See Task 2 steps 2-4.)

- [ ] **Step 3: Annotate Step 6 parallel Agent dispatches with `model="sonnet"`**

Find the Step 6 Auto mode parallel-agents block. The current Agent A dispatch reads (approximately):
```
- Agent A — `subagent_type: "general-purpose"`, `isolation: "worktree"`. Prompt includes: ...
```

Edit to:
```
- Agent A — `subagent_type: "general-purpose"`, `model: "sonnet"`, `isolation: "worktree"`. Prompt includes: ...
```

Same change for Agent B.

- [ ] **Step 4: Annotate Step 6.5 code review + silent-failure-hunter dispatches**

Find Step 6.5 code review:
```
- `subagent_type: "pr-review-toolkit:code-reviewer"` (preferred), or `"feature-dev:code-reviewer"` as fallback
```
Add `model: "sonnet"` parameter to both:
```
- `subagent_type: "pr-review-toolkit:code-reviewer"`, `model: "sonnet"` (preferred), or `"feature-dev:code-reviewer"`, `model: "sonnet"` as fallback
```

Find Step 6.5 silent-failure-hunter:
```
- Fallback: Agent tool → `subagent_type: "pr-review-toolkit:silent-failure-hunter"`
```
Edit to:
```
- Fallback: Agent tool → `subagent_type: "pr-review-toolkit:silent-failure-hunter"`, `model: "sonnet"`
```

- [ ] **Step 5: Verify post-condition**

```bash
! grep -qE "Type:.*Architect \(Opus\)|/model opus|━━━ Next \(" skills/add-feature/SKILL.md \
  && [ "$(grep -c 'model: "sonnet"' skills/add-feature/SKILL.md)" -ge 4 ] \
  && echo OK
```
Expected: `OK`.

- [ ] **Step 6: Manual sandbox test**

In a test project, run `/vladyslav:add-feature` Auto mode end-to-end on a small feature. Verify:
- No `/model opus` prompt.
- Step 6 parallel Agent dispatches show `model: "sonnet"` in tool calls.
- Step 6.5 code review fires with Sonnet.
- Final report does NOT contain `━━━ Next (Sonnet terminal) ━━━` block.

- [ ] **Step 7: Commit**

```bash
git add skills/add-feature/SKILL.md
git commit -m "refactor(add-feature): drop /model switch + annotate Agent dispatches

- Step 6 parallel test+impl agents → model=sonnet
- Step 6.5 code-reviewer + silent-failure-hunter → model=sonnet
- Removed terminal handoff blocks; replaced with inline next-step list

Refs: docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md"
```

---

### Task 10: Refactor `skills/fix-bug/SKILL.md` (no Agent dispatches)

Apply the standard 5-step Architect changes (Task 2 pattern). No `model=` annotations needed — this skill uses `Skill` tool for sub-skills, which run in main thread.

Pre-condition grep / post-condition grep / sandbox test / commit as in Task 2.

- [ ] Apply changes; verify; sandbox-test; commit.

---

### Task 11: Refactor `skills/design-sync/SKILL.md` (no Agent dispatches)

Same as Task 10. No internal `Agent` calls to annotate.

- [ ] Apply changes; verify; sandbox-test; commit.

---

### Task 12: Refactor `skills/discover/SKILL.md` (with `model="opus"` annotations)

**Files:**
- Modify: `skills/discover/SKILL.md`

- [ ] **Step 1: Pre-condition + count of Agent dispatches**

```bash
grep -c '"general-purpose"' skills/discover/SKILL.md
```
Expected: ≥4 (4 parallel research subagents: competitors, monetization, valuation, marketing).

- [ ] **Step 2: Apply standard Architect changes**

(Task 2 steps 2-4.)

- [ ] **Step 3: Annotate research Agent dispatches with `model="opus"`**

Find each `Agent(...)` block in Step N where 4 research subagents are dispatched in parallel. Add `model: "opus"` to each.

> **Why opus, not sonnet:** these subagents do heavy research/synthesis (competitor analysis, monetization strategy, valuation reasoning, marketing analysis). Per spec, synthesis-type work uses Opus.

- [ ] **Step 4: Verify post-condition**

```bash
[ "$(grep -c 'model: "opus"' skills/discover/SKILL.md)" -ge 4 ] && echo OK
```
Expected: `OK`.

- [ ] **Step 5: Sandbox test + commit** (as in Task 9 step 6-7).

---

### Task 13: Refactor `skills/discover-apple-check/SKILL.md` (no Agent dispatches)

Same as Task 10. Uses `Skill` tool for `apple-appstore-reviewer`. No model annotations.

- [ ] Apply changes; verify; sandbox-test; commit.

---

### Task 14: Refactor `skills/design-page/SKILL.md` (with `model="opus"` annotations)

Same shape as Task 12. The per-screen design subagents need `model="opus"` (creative design decisions).

- [ ] Apply standard Architect changes (Task 2 pattern).
- [ ] Annotate per-screen `Agent(...)` dispatches with `model: "opus"`.
- [ ] Verify post-condition: `grep -c 'model: "opus"'` ≥ 1.
- [ ] Sandbox test; commit.

---

### Task 15: Refactor `skills/seed-mempalace/SKILL.md` (no Agent dispatches)

Same as Task 10. Synthesis runs in main thread (Opus).

- [ ] Apply changes; verify; sandbox-test; commit.

---

## Phase 4 — Light Engineer (~15 min)

Trivial cleanup. Both skills are bundled into one task.

---

### Task 16: Refactor `stash` and `unstash` (Light Engineer)

**Files:**
- Modify: `skills/stash/SKILL.md`
- Modify: `skills/unstash/SKILL.md`

- [ ] **Step 1: Verify pre-condition**

```bash
grep -E "Type:.*Engineer \(Sonnet\)|/model sonnet" skills/stash/SKILL.md skills/unstash/SKILL.md
```
Expected: matches in both files.

- [ ] **Step 2: Update headers**

In both files:
- Find: `**Type:** Engineer (Sonnet)`
- Replace: `**Type:** Engineer (light)`

- [ ] **Step 3: Remove "Step 0: Verify model"**

In both files: delete the entire `### Step 0: Verify model` block.

- [ ] **Step 4: Verify post-condition**

```bash
! grep -qE "Type:.*Engineer \(Sonnet\)|/model sonnet" skills/stash/SKILL.md skills/unstash/SKILL.md \
  && grep -q "^\*\*Type:\*\* Engineer (light)$" skills/stash/SKILL.md \
  && grep -q "^\*\*Type:\*\* Engineer (light)$" skills/unstash/SKILL.md \
  && echo OK
```
Expected: `OK`.

- [ ] **Step 5: Manual sandbox test**

Run `/vladyslav:stash` and `/vladyslav:unstash` in a project. Verify both work as before (no behavior change, just removed model-switch step).

- [ ] **Step 6: Commit**

```bash
git add skills/stash/SKILL.md skills/unstash/SKILL.md
git commit -m "refactor(stash, unstash): drop /model switch (Light Engineer)

These skills are short-running utility skills (~30s). Dispatching to a
Sonnet subagent would add overhead exceeding the actual work. Body
unchanged; just removes the manual model-switch instruction.

Refs: docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md"
```

---

## Phase 5 — Docs + Release (~1 hour)

Update user-facing docs and release artifacts. Each task is a separate commit.

---

### Task 17: Update `skills/help/SKILL.md`

**Files:**
- Modify: `skills/help/SKILL.md` (frontmatter description + body)

- [ ] **Step 1: Verify pre-condition**

```bash
grep -iE "two-terminal|architect terminal|engineer terminal" skills/help/SKILL.md
```
Expected: matches.

- [ ] **Step 2: Update frontmatter description**

Find:
```yaml
description: Use when starting work or unsure which skill to use - shows all available vladyslav skills, two-terminal workflow, and superpowers integration
```
Replace:
```yaml
description: Use when starting work or unsure which skill to use - shows all available vladyslav skills, single-terminal workflow, and superpowers integration
```

- [ ] **Step 3: Replace "Two-Terminal Workflow" section**

Find the `## Two-Terminal Workflow` section (and the explanation under it about keeping two terminals).

Replace with:
```markdown
## One-Terminal Workflow (v2.0+)

Run any vladyslav skill from a single Opus session. Skills delegate execution
work to Sonnet subagents automatically — no manual `/model` switching required.

- **Architect skills** (add-feature, fix-bug, analyze-project, design-sync,
  discover, discover-apple-check, design-page, seed-mempalace) run interactively
  in Opus.
- **Heavy Engineer skills** (write-test-docs, write-project-docs, write-user-stories,
  attach-project, init-project, pre-release-check) run their body in a Sonnet
  subagent dispatched from Opus main; pre-flight Q&A stays interactive.
- **Light Engineer skills** (stash, unstash) run inline in main thread (~30s
  utility operations).
```

- [ ] **Step 4: Verify post-condition**

```bash
! grep -qiE "two-terminal|architect terminal|engineer terminal" skills/help/SKILL.md \
  && grep -q "One-Terminal Workflow" skills/help/SKILL.md \
  && echo OK
```
Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
git add skills/help/SKILL.md
git commit -m "docs(help): replace two-terminal workflow with one-terminal description"
```

---

### Task 18: Update `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Verify pre-condition**

```bash
grep -iE "two-terminal|architect terminal|engineer terminal|sonnet terminal|opus terminal" README.md
```
Expected: matches.

- [ ] **Step 2: Find and replace two-terminal section**

Read `README.md`. Identify the section that documents the two-terminal workflow (likely titled "Workflow", "Two-Terminal Workflow", "Usage", or similar).

Replace with a description of the one-terminal workflow: Opus main + Sonnet subagent dispatch. Reference the v2.0 release.

Specific replacement text (adapt to actual README structure):
```markdown
## Workflow (v2.0)

Single-terminal: run any skill from an Opus session. Skills dispatch Sonnet
subagents automatically for execution work.

| Skill type | Where it runs |
|-----------|---------------|
| Architect (8 skills) | Opus main session — interactive design + synthesis |
| Heavy Engineer (6 skills) | Pre-flight Q&A in Opus main → body in Sonnet subagent |
| Light Engineer (2 skills) | Opus main inline (~30s utility operations) |

No manual `/model` switching needed.
```

- [ ] **Step 3: Verify post-condition**

```bash
! grep -qiE "two-terminal|architect terminal|engineer terminal|sonnet terminal|opus terminal" README.md \
  && grep -q "v2.0\|One-Terminal\|one-terminal" README.md \
  && echo OK
```
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs(readme): document one-terminal workflow for v2.0"
```

---

### Task 19: Update project `CLAUDE.md`

**Files:**
- Modify: `CLAUDE.md` (project root)

- [ ] **Step 1: Verify pre-condition**

```bash
grep -iE "Architect skills end with a prepared prompt for the Sonnet terminal|two-terminal|Sonnet terminal" CLAUDE.md
```
Expected: matches at least one pattern.

- [ ] **Step 2: Replace the two-terminal working rule**

Find the bullet:
```
- Architect skills end with a prepared prompt for the Sonnet terminal
- Engineer skills end with a report + next step
```

Replace with:
```
- Architect skills run interactively in Opus main — internal `Agent(...)` dispatches MUST specify `model` explicitly (`model="sonnet"` for executor work; `model="opus"` for synthesis/research)
- Heavy Engineer skills wrap body in Sonnet subagent dispatch with pre-flight Q&A in Opus main
- Light Engineer skills (stash, unstash) run inline in main thread
```

- [ ] **Step 3: Verify post-condition**

```bash
! grep -qiE "Architect skills end with a prepared prompt for the Sonnet terminal" CLAUDE.md \
  && grep -q 'model="sonnet"' CLAUDE.md \
  && grep -q 'model="opus"' CLAUDE.md \
  && echo OK
```
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude-md): replace two-terminal rule with explicit-model dispatch rule"
```

---

### Task 20: Update `docs/architecture/system.md` (if needed) + bump version + CHANGELOG

**Files:**
- Modify (conditionally): `docs/architecture/system.md`
- Modify: `.claude-plugin/plugin.json`
- Modify (or create): `CHANGELOG.md`
- Modify (audit): `commands/*.md`

- [ ] **Step 1: Audit `docs/architecture/system.md`**

Run:
```bash
grep -iE "two-terminal|architect terminal|engineer terminal" docs/architecture/system.md
```
If matches found → update those sections to reflect the new one-terminal architecture. If no matches → no change needed.

- [ ] **Step 2: Audit `commands/` for `/model` hints**

Run:
```bash
grep -lE "/model opus|/model sonnet" commands/*.md
```
If any files match → remove the `/model …` hint from each. If no matches → skip.

- [ ] **Step 3: Bump plugin version**

Edit `.claude-plugin/plugin.json`:
- Find: `"version": "1.x.x"` (whatever current value is — recent commits show 1.8.0)
- Replace: `"version": "2.0.0"`

- [ ] **Step 4: Add/update CHANGELOG.md**

If `CHANGELOG.md` exists, prepend the new entry. If not, create it.

Entry text:
```markdown
# Changelog

## v2.0.0 — 2026-05-06

### BREAKING

- **Drop two-terminal workflow.** Single-terminal: Opus main session + Sonnet subagent dispatch for execution work. Manual `/model` switching no longer needed.
- Architect skills no longer print `━━━ Next (Sonnet terminal) ━━━` handoff blocks.
- Heavy Engineer skills (write-test-docs, write-project-docs, write-user-stories, attach-project, init-project, pre-release-check) now wrap their body in a Sonnet subagent dispatched from Opus main, with pre-flight Q&A in main session.
- Light Engineer skills (stash, unstash) keep inline behavior in main thread (~30s utility operations).

### Migration

If you were on the two-terminal workflow: delete your "Engineer" terminal. Run all skills from a single Opus session. No code changes on your side — skills handle dispatching internally.
```

- [ ] **Step 5: Verify post-conditions**

```bash
grep '"version": "2.0.0"' .claude-plugin/plugin.json \
  && grep "v2.0.0" CHANGELOG.md \
  && ! grep -qiE "two-terminal|architect terminal|engineer terminal" docs/architecture/system.md \
  && ! grep -qE "/model opus|/model sonnet" commands/*.md \
  && echo OK
```
Expected: `OK`.

- [ ] **Step 6: Final repo-wide grep — no leftover patterns**

```bash
echo "=== /model leftovers ==="
grep -rE "/model opus|/model sonnet" skills/ commands/ README.md CLAUDE.md docs/ 2>/dev/null || echo "  (none)"
echo "=== terminal-handoff leftovers ==="
grep -rE "━━━ Next \(.* terminal\)" skills/ commands/ README.md CLAUDE.md 2>/dev/null || echo "  (none)"
echo "=== two-terminal language leftovers ==="
grep -riE "two-terminal" skills/ commands/ README.md CLAUDE.md 2>/dev/null || echo "  (none)"
```
Expected: all three sections print `(none)`.

If any leftovers found → fix them in a separate commit.

- [ ] **Step 7: Commit final cleanup + version bump**

```bash
git add .claude-plugin/plugin.json CHANGELOG.md docs/architecture/system.md commands/
git commit -m "release: bump to v2.0.0 — one-terminal workflow

BREAKING: drop two-terminal workflow. See CHANGELOG.md for migration notes.

Refs: docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md
      docs/superpowers/plans/2026-05-06-opus-subagent-dispatch.md"
```

---

## Phase 6 — PR (~10 min)

- [ ] **Step 1: Push the branch**

```bash
git push -u origin feature/opus-subagent-dispatch
```

- [ ] **Step 2: Open PR against `develop`**

```bash
gh pr create --base develop --title "v2.0: one-terminal workflow via Opus main + Sonnet subagent dispatch" --body "$(cat <<'EOF'
## Summary

- Refactor all 16 skills to eliminate manual `/model` switching.
- Architect skills (8) run in Opus main; internal `Agent(...)` dispatches annotated explicitly with `model=` per work type.
- Heavy Engineer skills (6) wrap body in Sonnet subagent dispatch with pre-flight Q&A in main session and YAML return contract.
- Light Engineer skills (stash, unstash) keep inline behavior.
- Drop two-terminal workflow from README, CLAUDE.md, help skill, and any handoff blocks in skill bodies.
- Version bump 1.8.x → 2.0.0 (BREAKING change).

## Test plan

- [ ] `/vladyslav:add-feature` end-to-end Auto mode on test project — no `/model` prompts, Sonnet subagents fire for execution + review
- [ ] `/vladyslav:fix-bug` — no terminal handoff at end
- [ ] `/vladyslav:write-test-docs` — pre-flight asks for missing PRD; Sonnet subagent writes test-plan.md + manual-qa.md to allowlist
- [ ] `/vladyslav:stash` — runs in main thread, completes within seconds
- [ ] `/vladyslav:discover` — 4 parallel research subagents fire with `model="opus"`
- [ ] All 16 SKILL.md files: no `/model` switch step, no `━━━ Next (… terminal) ━━━` block

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review

This section is for the planning agent — confirms the plan is internally consistent before handoff.

**Spec coverage:**
- One-terminal workflow → Tasks 1-16 cover all 16 skills.
- Architect skill `model=` annotations → Tasks 9 (add-feature/sonnet), 12 (discover/opus), 14 (design-page/opus). Other Architect skills have no internal `Agent` calls (verified via reading SKILL.md files during planning).
- Heavy Engineer template → Task 1 defines full template; Tasks 4-8 reuse it.
- Light Engineer trivial cleanup → Task 16.
- README → Task 18. CLAUDE.md → Task 19. help skill → Task 17. Architecture doc + commands + version + CHANGELOG → Task 20.
- Validation criteria from spec → Task 3 (pilot gate) + per-task sandbox tests + Task 20 Step 6 final repo-wide grep.

**Placeholder scan:**
- Task 1 has full new SKILL.md content embedded.
- Tasks 4-8 reference Task 1 as template + provide a per-skill specifics table (inputs, allowlist, task summary).
- Task 9 has explicit `model=` annotation steps with file-text-find/replace instructions.
- Task 20 has full CHANGELOG entry text.
- No "TBD", "TODO", or "fill in details" markers.

**Type / file consistency:**
- All SKILL.md paths verified during planning.
- Heavy Engineer skill list matches spec table.
- Light Engineer skill list matches spec table.

**Known compromises:**
- Tasks 4-8 reference the Heavy Engineer template structure rather than duplicating the full body 6 times. The engineer must read Task 1 as the structural reference. This is intentional to keep the plan readable — the per-skill table provides the deltas.
- Task 20 step 1 ("Audit docs/architecture/system.md") and step 2 ("Audit commands/") are conditional — if no leftover patterns are found, no edit is made.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-06-opus-subagent-dispatch.md`. Two execution options:

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
