---
name: write-project-docs
description: Use when human-readable documentation is needed - generates README, onboarding guide, and deployment guide from architecture and code analysis
---

# Write Project Docs

## Overview

Generate documentation for humans: README, onboarding guide, deployment guide. No AI context — these are for team members, new developers, and stakeholders.

**Recommended model:** Sonnet (`vd-docs` command uses it automatically)

## Process

### Step 1: Read context

Read:
- `CLAUDE.md`
- `docs/architecture/system.md`
- `docs/architecture/api.md` (if exists)
- Existing `README.md`
- Docker/deployment configs

### Step 2: Create/update README.md

Include:
- Project description (from PRD if available)
- How to run locally (exact commands)
- Project structure (directory tree)
- API overview (if backend)
- Deployment summary

Do NOT include: AI context, CLAUDE.md references, skill references.

### Step 3: Create onboarding guide

Write `docs/onboarding.md`:
- Prerequisites (tools to install)
- Setup steps (clone, env, run)
- Architecture overview (high level)
- Key files to know
- Development workflow
- How to run tests
- Who to ask for help

### Step 4: Create deployment guide

Write `docs/deployment.md`:
- Environment requirements
- Step-by-step deployment process
- Environment variables reference
- Rollback procedure
- Monitoring/logging

### Step 5: Finish

```
✓ Project documentation updated.

Files:
- README.md
- docs/onboarding.md
- docs/deployment.md

Remember:
- /exit to close this session
```
