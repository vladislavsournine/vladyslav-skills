---
name: write-project-docs
description: Use when human-readable documentation is needed - generates README, onboarding guide, and deployment guide from architecture and code analysis
---

# Write Project Docs

## Overview

Generate documentation for humans: README, onboarding guide, deployment guide. No AI context — these are for team members, new developers, and stakeholders.

**Type:** Engineer (Sonnet)

## Process

### Step 0: Verify model

Check current model. If not Sonnet, switch: `/model sonnet`

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

Print engineer report:

```
✓ Engineer report:
- README.md: created/updated
- docs/onboarding.md: created/updated
- docs/deployment.md: created/updated

━━━ Next (Sonnet terminal) ━━━━━━━━━━━━━━━━
/vladyslav:pre-release-check

Context:
"Project docs updated. Run pre-release verification."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Or if all work is complete:
━━━ Ready for deploy ━━━━━━━━━━━━━━━━━━━━━━
All features implemented and documented.
- Live QA: docs/testing/manual-qa.md
- Deploy: docs/deployment.md
- Final check: /vladyslav:pre-release-check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
