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

4. Read FULL content of available input files (do not truncate). Record paths and content. The subagent needs complete input to produce accurate test coverage.

5. Compose dispatch context (project name + verified file paths + content).

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Generate test plan + QA checklist"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs>`

Wait for return.

### Step 2: Present summary

Parse the YAML block in the subagent's response. Look for the last fenced ` ```yaml ` block. Treat as parse failure (status: unknown) if: (a) no ` ```yaml ` block is found, (b) the block does not contain a `status:` field, OR (c) the YAML is malformed (e.g., unbalanced indentation).

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
Wait for user choice. On (1), re-dispatch: take the same subagent prompt template from Step 1, add the path from `scope_expansion_required[0].path` (and any additional entries) to the Output allowlist section of the prompt, re-invoke the Agent tool with this updated prompt and the same other parameters. Reuse pre-flight outputs already in memory — do NOT re-read input files. On (2), record the skipped path and proceed to next step. On (3), exit cleanly with no further action.

`status: error` →
```
✗ Engineer failed (write-test-docs)
  Error: <error message>
```
Best-effort: invoke `vladyslav:stash` skill with `source: "write-test-docs:error"`, `task: "Write test docs"`, `open_question: "Subagent failed: <error>"`. If stash itself fails, log warning, continue.

---

## Subagent prompt template

````
You are a Sonnet subagent dispatched by the `write-test-docs` skill in the `vladyslav-skills` plugin. You have no conversation history with the user — this prompt is your full briefing.

## Project context

Working directory: <pwd>
Project name: <from CLAUDE.md>
Key facts from CLAUDE.md (extracted by pre-flight — must include: project type, primary tech stack, platform (web / iOS / Android / cross-platform), and any testing-relevant constraints. If the project is mobile, ensure the platform bullet is explicit so the subagent generates the device-specific QA section):
<3-5 bullets>

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
files_skipped: []  # populate with paths the subagent considered but did not write to
warnings:
  - <non-blocking issue, if any>
scope_expansion_required:
  - path: <if applicable>
    reason: <if applicable>
next_step_suggestion: /superpowers:test-driven-development
summary: |
  <1-3 sentence human-readable description>
```
````
