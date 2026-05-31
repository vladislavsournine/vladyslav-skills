---
name: write-project-docs
description: Use when human-readable docs are needed. Generates README, onboarding, and deployment guides from code/architecture.
---

# Write Project Docs

**Type:** Engineer (light)

## Overview

Generate three human-readable documents for team members, new developers, and stakeholders:

- `README.md` (project root)
- `docs/onboarding.md`
- `docs/deployment.md`

These are NOT AI-context documents — they are for humans. No mentions of Claude, CLAUDE.md, skills, or plugin internals.

This was a Heavy Engineer skill until v3.1.0 (inline in Opus). v4.2.0 fans the three independent doc generations out to parallel `sonnet` subagents — the Opus main session keeps pre-flight, the no-AI-mention gate, and the merge. See `_shared/references/orchestration-conventions.md`.

## Process

### Step 0: Pre-flight

1. Read `CLAUDE.md` from `pwd`. If missing → STOP: "No CLAUDE.md found — are you in the right project?" and extract the project name + primary stack + platform (web / iOS / Android / cross-platform / CLI / plugin / etc.).

2. Verify input files:
   - **Required:** `CLAUDE.md`, `docs/architecture/system.md`
   - **Optional:** `docs/architecture/api.md`, existing `README.md` (preserve any custom sections found there), deployment configs found in the tree

3. For each missing **required** file, ask the user:
   > "Required input `<path>` is missing. Options: (a) run `/vladyslav:ingest` first to populate it / (b) create stub now / (c) abort"
   - On (a) → exit cleanly. Suggest the user run ingest then come back.
   - On (b) → create stub and continue (output will be skeletal).
   - On (c) → exit cleanly.

4. **Scan for deployment configs.** Look at the project tree for `Dockerfile`, `docker-compose.yml`, `.github/workflows/*.yml`, `vercel.json`, `fly.toml`, `railway.toml`. Note any found — they shape the deployment guide.

### Step 1: Read inputs

Read the FULL content of every available input file (do not truncate). The output must be accurate to the actual code state.

### Steps 2–4: Generate the three docs (parallel fan-out)

The three documents are independent — none references another's output. Dispatch them as **three `Agent` calls in a single message** so they run concurrently, each `model: "sonnet"` (pure generation from decided inputs — see `_shared/references/orchestration-conventions.md`).

Give each subagent: the relevant input content from Step 1, its structure block below, the preservation rule (merge, don't clobber user-edited sections of an existing file), and the no-AI-mention rule. Each subagent writes its own file.

After all three return, the Opus main session runs the **no-AI-mention gate** (grep the three outputs for `Claude` / `CLAUDE.md` / `.claude/` / "AI" and fix any leak) before rendering the summary. This gate stays in the main session — never delegated.

### Step 2: Generate README.md  *(subagent → `README.md`)*

Write `README.md` at the project root. If it exists, preserve any custom sections; merge the rest.

Structure:

```markdown
# <Project Name>

<One-paragraph description — what the project does, who it's for>

## Run locally

\`\`\`bash
# install dependencies
# start dev server / build app
\`\`\`

## Project structure

\`\`\`
<key directory>/    # purpose
<key directory>/    # purpose
\`\`\`

## API overview (if backend project)

- `GET /endpoint` — purpose
- `POST /endpoint` — purpose

## Deployment

See [docs/deployment.md](docs/deployment.md).
```

Do NOT include `Claude`, `CLAUDE.md`, `.claude/`, or "AI" anywhere in the README.

### Step 3: Generate docs/onboarding.md  *(subagent → `docs/onboarding.md`)*

Write `docs/onboarding.md`. Preserve user edits where reasonable.

Structure:

```markdown
# Onboarding Guide

For new developers joining the project.

## Prerequisites

- <tool A> v<X.Y> — <reason>
- <tool B> v<X.Y> — <reason>

## Setup

1. Clone the repo
2. Copy `.env.example` → `.env` and fill values
3. Install dependencies (`<command>`)
4. Run locally (`<command>`)

## Architecture overview

<2-4 paragraphs explaining the system at a high level — derived from docs/architecture/system.md, summarised for a newcomer>

## Key files to know

- `<path>` — <purpose, why it matters>

## Development workflow

- Branching strategy: <e.g. trunk-based, feature branches, gitflow>
- PR review: <process>
- Code style: <linter / formatter>

## Running tests

\`\`\`bash
<test command>
\`\`\`

## Who to ask

- `<name / team>` for `<topic>`  ← placeholder if unknown
```

### Step 4: Generate docs/deployment.md  *(subagent → `docs/deployment.md`)*

Write `docs/deployment.md`. Preserve user edits.

Structure:

```markdown
# Deployment Guide

## Environment requirements

- Runtime: <Node vX / Python vX / Swift vX / etc.>
- Infrastructure: <cloud provider, services in use>
- External dependencies: <DB, Redis, S3, etc.>

## Deploy steps

1. Step one
2. Step two
3. Step three

## Environment variables

| Variable | Purpose | Example value |
|----------|---------|---------------|
| `VAR_NAME` | What it does | `example_value` |

## Rollback procedure

<concrete steps to roll back a bad deploy>

## Monitoring / logging

- Logs: <where to find them>
- Metrics dashboard: <URL or "not yet wired">
- Alerting: <PagerDuty / Slack / "not yet wired">
```

Derive concrete deploy steps from the deployment configs found in Step 0.4. For projects without any deployment config, fill the file with stub guidance ("no deployment configuration found — fill manually once chosen").

### Step 5: Summary

Render:

```
✓ write-project-docs complete
  Files: README.md, docs/onboarding.md, docs/deployment.md
  Action per file: <created | updated>
  Deployment configs detected: <list, or "none — manual fill required">
  Warnings: <warnings, if any>
  Next: /vladyslav:pre-release-check  — verify before deploying
```

---

## Why this is a Light Engineer skill (with parallel generation)

- **Three independent generation passes.** v3.1.0 dropped the old Heavy Engineer YAML-return + present-summary boilerplate (~50 lines of tax). v4.2.0 keeps that lean body but fans the three generations out to parallel `sonnet` subagents — wall-clock ~3× faster and cheaper than three sequential opus passes, with no contract boilerplate.
- **The Opus main session stays the control plane** — pre-flight, the no-AI-mention gate, and preservation sanity all run in main, not in subagents.
- **No allowlist enforcement** — exactly three output paths, all under-the-project-root, none surprising. Each subagent owns exactly one path.

## Output

- `README.md`
- `docs/onboarding.md`
- `docs/deployment.md`
