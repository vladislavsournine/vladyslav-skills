---
name: write-user-stories
description: Use when product or QA needs a registry of implemented features - scans code and docs to generate human-readable user stories with acceptance criteria and status
---

# Write User Stories

## Overview

Create or update `docs/product/user-stories.md` — a human-readable registry of implemented features for product owners and QA. Not for development planning — for verification of what's built.

**Type:** Engineer (Sonnet)

## Process

### Step 0: Verify model

Check current model. If not Sonnet, switch: `/model sonnet`

### Step 1: Read context

Read these files:
- `docs/product/prd.md` — what was planned
- `docs/architecture/api.md` — what endpoints exist
- `docs/architecture/system.md` — system overview
- `docs/product/user-stories.md` — existing stories (if any)

### Step 2: Analyze implemented features

Scan the codebase to determine which features are actually implemented:
- Check route handlers / screen implementations
- Check if tests exist for features
- Check if UI components are wired up

### Step 3: Write user stories

For each feature, write in this format:

```markdown
## [Feature Area]

### US-001: [Short title]
**As** [role], **I can** [action], **so that** [benefit].

**Acceptance criteria:**
- [ ] [Specific verifiable check]
- [ ] [Another check]

**Status:** ✅ Done / 🚧 Partial / ❌ Not started
**Implemented in:** [file paths or "not yet"]
```

### Step 4: Write to file

Save to `docs/product/user-stories.md`.

Rules:
- Human-readable language — no implementation jargon
- Each story is independently verifiable by QA
- Status reflects actual code state, not plans
- Sort: done first, then partial, then not started

### Step 5: Finish

Print engineer report:

```
✓ Engineer report:
- User stories updated: N done, M partial, K not started
- File: docs/product/user-stories.md

━━━ Next (Sonnet terminal) ━━━━━━━━━━━━━━━━
/vladyslav:write-test-docs

Context:
"User stories updated. N done, M partial, K not started.
Generate test plan and QA checklist."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
