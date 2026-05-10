---
name: write-user-stories
description: Use when product or QA needs implemented features as user stories. Generates from code and docs with acceptance criteria.
---

# Write User Stories

## Overview

Create or update `docs/product/user-stories.md` — a human-readable registry of implemented features for product owners and QA. Not for development planning — for verification of what's built.

**Type:** Engineer

## Process

### Step 0: Pre-flight (Opus main)

Interactive checks before dispatching the subagent.

1. Read `CLAUDE.md` in `pwd`. If missing → STOP: "No CLAUDE.md found in current directory. Are you in the right project?". Otherwise extract project name.

2. Check input files:
   - `CLAUDE.md` — required
   - `docs/product/prd.md` — required
   - `docs/architecture/api.md` — optional
   - `docs/architecture/system.md` — optional
   - existing `docs/product/user-stories.md` — optional (preserve any existing entries; the subagent updates rather than overwrites where reasonable)

3. For each missing **required** file, ask user:
   > "Required input `<path>` is missing. Options: (a) create stub now / (b) abort. Which?"
   - On abort → exit cleanly, no dispatch.
   - On stub → create a placeholder file (`# <Title>\n\n*to be filled*\n`), proceed.

4. Read FULL content of available input files (do not truncate). Record paths and content. The subagent needs complete input to produce accurate user stories.

5. Compose dispatch context (project name + verified file paths + content).

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Generate or update user stories with acceptance criteria and status"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs>`

Wait for return.

### Step 2: Present summary

Pipe the subagent response through `<plugin>/scripts/parse-yaml-return.sh`. Then render the human-facing summary as specified in `<plugin>/skills/_shared/references/present-summary.md` (substitute `<skill-name>` → `write-user-stories`). That reference defines the four `status` branches (`success`, `partial`, `scope_expansion_required`, `error`) verbatim — follow it without paraphrasing.

On `status: scope_expansion_required` and user approval, re-dispatch with an extended allowlist (add `scope_expansion_required[0].path`); reuse pre-flight outputs, do NOT re-run AskUserQuestion.

---

## Subagent prompt template

The full subagent prompt is composed by Opus main from these fragments, in order:

1. **Preamble** — verbatim contents of `<plugin>/skills/_shared/references/subagent-preamble.md` (substitute `<X>` → `write-user-stories`).
2. **Project context** + **Task steps** — defined inline below.
3. **YAML return contract** — verbatim contents of `<plugin>/skills/_shared/references/yaml-return.md`.

Concatenate the three into a single string and pass as `prompt:` to the Agent tool.

The inline part of the prompt template (item 2):

````
## Project context

Working directory: <pwd>
Project name: <from CLAUDE.md>
Key facts from CLAUDE.md (extracted by pre-flight — must include: project type, primary tech stack, platform (web / iOS / Android / cross-platform), and any QA-relevant constraints. If the project is mobile, ensure the platform bullet is explicit so the subagent generates platform-specific acceptance criteria):
<3-5 bullets>

## Verified inputs

CLAUDE.md:
<content from pre-flight>

docs/product/prd.md:
<content from pre-flight>

docs/architecture/api.md (if available):
<content from pre-flight>

docs/architecture/system.md (if available):
<content from pre-flight>

docs/product/user-stories.md (if available — preserve any existing entries where reasonable):
<content from pre-flight>

## Your task

Generate or update `docs/product/user-stories.md`:

- Scan the codebase to determine which features are actually implemented (route handlers, screen implementations, tests, UI wiring).
- Per feature, write a story in the format:

```markdown
## [Feature Area]

### US-NNN: [Short title]
**As** [role], **I can** [action], **so that** [benefit].

**Acceptance criteria:**
- [ ] [Specific verifiable check]

**Status:** ✅ Done / 🚧 Partial / ❌ Not started
**Implemented in:** [file paths or "not yet"]
```

Rules:
- Human-readable language — no implementation jargon
- Each story is independently verifiable by QA
- Status reflects actual code state, not plans
- Sort: done first, then partial, then not started

## Output allowlist

You may ONLY create or modify these files:
- `docs/product/user-stories.md`

If you discover need to touch any other file — STOP, do NOT make the change, return `status: scope_expansion_required`. Set `next_step_suggestion: /vladyslav:write-test-docs` in the YAML return.
````
