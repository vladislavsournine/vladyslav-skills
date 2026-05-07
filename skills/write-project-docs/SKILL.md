---
name: write-project-docs
description: Use when human-readable documentation is needed - generates README, onboarding guide, and deployment guide from architecture and code analysis
---

# Write Project Docs

## Overview

Generate documentation for humans: README, onboarding guide, deployment guide. No AI context — these are for team members, new developers, and stakeholders.

**Type:** Engineer

## Process

### Step 0: Pre-flight (Opus main)

Interactive checks before dispatching the subagent.

1. Read `CLAUDE.md` in `pwd`. If missing → STOP: "No CLAUDE.md found in current directory. Are you in the right project?". Otherwise extract project name.

2. Check input files:
   - `CLAUDE.md` — required
   - `docs/architecture/system.md` — required
   - `docs/architecture/api.md` — optional
   - existing `README.md` — optional (preserve any custom sections)
   - deployment configs: scan the directory tree for `Dockerfile`, `docker-compose.yml`, `.github/workflows/*.yml`, `vercel.json` — optional, note any found

3. For each missing **required** file, ask user:
   > "Required input `<path>` is missing. Options: (a) create stub now / (b) abort. Which?"
   - On abort → exit cleanly, no dispatch.
   - On stub → create a placeholder file (`# <Title>\n\n*to be filled*\n`), proceed.

4. Read FULL content of available input files (do not truncate). Record paths and content. The subagent needs complete input to produce accurate documentation.

5. Compose dispatch context (project name + verified file paths + content).

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Generate README, onboarding guide, and deployment guide"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs>`

Wait for return.

### Step 2: Present summary

Parse the YAML block in the subagent's response. Look for the last fenced ` ```yaml ` block. Treat as parse failure (status: unknown) if: (a) no ` ```yaml ` block is found, (b) the block does not contain a `status:` field, OR (c) the YAML is malformed (e.g., unbalanced indentation).

**If parse fails** → print the full subagent output, run `git status --short`, tell user: "Subagent returned unstructured response. Files on disk: `<git status>`. Review manually."

**If parse succeeds**, render based on `status`:

`status: success` →
```
✓ Engineer summary (write-project-docs)
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
⚠ Engineer halted (write-project-docs)
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
✗ Engineer failed (write-project-docs)
  Error: <error message>
```
Best-effort: invoke `vladyslav:stash` skill with `source: "write-project-docs:error"`, `task: "Write project docs"`, `open_question: "Subagent failed: <error>"`. If stash itself fails, log warning, continue.

---

## Subagent prompt template

````
You are a Sonnet subagent dispatched by the `write-project-docs` skill in the `vladyslav-skills` plugin. You have no conversation history with the user — this prompt is your full briefing.

## Project context

Working directory: <pwd>
Project name: <from CLAUDE.md>
Key facts from CLAUDE.md (extracted by pre-flight — must include: project type, primary tech stack, platform (web / iOS / Android / cross-platform / CLI / plugin / etc.), and any deployment-relevant constraints. If the project has a backend, ensure the API/service bullet is explicit so the subagent generates the API overview section):
<3-5 bullets>

## Verified inputs

CLAUDE.md:
<content from pre-flight>

docs/architecture/system.md:
<content from pre-flight>

docs/architecture/api.md (if available):
<content from pre-flight>

README.md (if available — preserve any custom sections found here):
<content from pre-flight>

Deployment configs found (list paths; include content of each):
<content from pre-flight>

## Your task

Generate three files. Do NOT include any references to AI, Claude, CLAUDE.md, skills, or plugin internals in any output — these are human-readable documents for team members, new developers, and stakeholders.

1. `README.md` with sections:
   - Project description (clear one-paragraph summary)
   - How to run locally (exact commands)
   - Project structure (directory tree, key dirs/files)
   - API overview (if backend project — endpoints, auth method)
   - Deployment summary (one paragraph pointing to docs/deployment.md)

2. `docs/onboarding.md` with sections:
   - Prerequisites (tools to install, versions)
   - Setup steps (clone, env vars, install deps, run)
   - Architecture overview (high-level, derived from system.md)
   - Key files to know
   - Development workflow (branching, PRs, code review)
   - How to run tests
   - Who to ask for help (placeholder if unknown)

3. `docs/deployment.md` with sections:
   - Environment requirements (runtime versions, infra)
   - Step-by-step deployment process
   - Environment variables reference (name, purpose, example value)
   - Rollback procedure
   - Monitoring/logging

Use these markdown templates as reference shapes:

```markdown
# <Project Name>

<One-paragraph description>

## Run locally
\`\`\`bash
# install deps
# start dev server
\`\`\`

## Project structure
\`\`\`
src/       # source code
docs/      # documentation
\`\`\`

## API overview (if applicable)
- `GET /endpoint` — description

## Deployment
See [docs/deployment.md](docs/deployment.md).
```

```markdown
# Onboarding Guide

## Prerequisites
- Tool A vX.Y
- Tool B vX.Y

## Setup
1. Clone the repo
2. Copy `.env.example` → `.env` and fill in values
3. Install dependencies
4. Run locally

## Architecture overview
<high-level description>

## Key files
- `path/to/file` — purpose

## Development workflow
<branching, PR, review process>

## Running tests
\`\`\`bash
# test command
\`\`\`

## Who to ask
- <name/team> for <topic>
```

```markdown
# Deployment Guide

## Environment requirements
- Runtime: Node vX / Python vX / etc.
- Infrastructure: <cloud provider, services>

## Deploy steps
1. Step one
2. Step two

## Environment variables
| Variable | Purpose | Example |
|----------|---------|---------|
| VAR_NAME | What it does | value |

## Rollback
<steps to roll back>

## Monitoring / logging
<where to find logs, alerts>
```

## Output allowlist

You may ONLY create or modify these files:
- `README.md`
- `docs/onboarding.md`
- `docs/deployment.md`

If you discover need to touch any other file — STOP, do NOT make the change, return `status: scope_expansion_required`.

## Required return format

End your response with EXACTLY one YAML block:

```yaml
status: success | partial | scope_expansion_required | error
files_written:
  - path: README.md
    action: created | modified | replaced
  - path: docs/onboarding.md
    action: created | modified | replaced
  - path: docs/deployment.md
    action: created | modified | replaced
files_skipped: []  # populate with paths the subagent considered but did not write to
warnings:
  - <non-blocking issue, if any>
scope_expansion_required:
  - path: <if applicable>
    reason: <if applicable>
next_step_suggestion: /vladyslav:pre-release-check
summary: |
  <1-3 sentence human-readable description>
```
````
