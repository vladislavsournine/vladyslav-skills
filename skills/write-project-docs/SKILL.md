---
name: write-project-docs
description: Use when human-readable docs are needed. Generates README, onboarding, and deployment guides from code/architecture.
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

Pipe the subagent response through `<plugin>/scripts/parse-yaml-return.sh`. Then render the human-facing summary as specified in `<plugin>/skills/_shared/references/present-summary.md` (substitute `<skill-name>` → `write-project-docs`). That reference defines the four `status` branches (`success`, `partial`, `scope_expansion_required`, `error`) verbatim — follow it without paraphrasing.

On `status: scope_expansion_required` and user approval, re-dispatch with an extended allowlist (add `scope_expansion_required[0].path`); reuse pre-flight outputs, do NOT re-run AskUserQuestion.

---

## Subagent prompt template

The full subagent prompt is composed by Opus main from these fragments, in order:

1. **Preamble** — verbatim contents of `<plugin>/skills/_shared/references/subagent-preamble.md` (substitute `<X>` → `write-project-docs`).
2. **Project context** + **Task steps** — defined inline below.
3. **YAML return contract** — verbatim contents of `<plugin>/skills/_shared/references/yaml-return.md`.

Concatenate the three into a single string and pass as `prompt:` to the Agent tool.

The inline part of the prompt template (item 2):

````
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

If you discover need to touch any other file — STOP, do NOT make the change, return `status: scope_expansion_required`. Set `next_step_suggestion: /vladyslav:pre-release-check` in the YAML return.
````
