---
name: write-test-docs
description: Use when test docs are missing or outdated. Generates test plan and manual QA checklist from PRD and user stories.
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

Pipe the subagent response through `<plugin>/scripts/parse-yaml-return.sh`. Then render the human-facing summary as specified in `<plugin>/skills/_shared/references/present-summary.md` (substitute `<skill-name>` → `write-test-docs`). That reference defines the four `status` branches (`success`, `partial`, `scope_expansion_required`, `error`) verbatim — follow it without paraphrasing.

On `status: scope_expansion_required` and user approval, re-dispatch with an extended allowlist (add `scope_expansion_required[0].path`); reuse pre-flight outputs, do NOT re-run AskUserQuestion.

---

## Subagent prompt template

The full subagent prompt is composed by Opus main from these fragments, in order:

1. **Preamble** — verbatim contents of `<plugin>/skills/_shared/references/subagent-preamble.md` (substitute `<X>` → `write-test-docs`).
2. **Project context** + **Task steps** — defined inline below.
3. **YAML return contract** — verbatim contents of `<plugin>/skills/_shared/references/yaml-return.md`.

Concatenate the three into a single string and pass as `prompt:` to the Agent tool.

The inline part of the prompt template (item 2):

````
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

If you discover need to touch any other file — STOP, do NOT make the change, return `status: scope_expansion_required`. Set `next_step_suggestion: /superpowers:test-driven-development` in the YAML return.
````
