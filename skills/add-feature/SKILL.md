---
name: add-feature
description: Use when adding a new feature to a production project - orchestrates full cycle from idea through brainstorming, planning, implementation, to documentation updates
---

# Add Feature

## Overview

Full-cycle feature addition: idea → design → plan → implement → docs. Orchestrates superpowers skills in the right order with project-specific reminders.

**Recommended model:** Opus (`vd-feature` command uses it automatically)

## Process

### Step 1: Read project context

Read these files before anything else:
- `CLAUDE.md`
- `docs/architecture/system.md`
- `docs/architecture/api.md` (if exists)
- `docs/product/prd.md`
- `docs/plans/tasks.md`

### Step 2: Get feature description

Ask the user to describe the feature they want to add. Free text.

### Step 3: Design the feature

Invoke `superpowers:brainstorming` skill. Follow it exactly — it will:
- Ask clarifying questions
- Propose approaches
- Present design for approval
- Save design doc

### Step 4: Create implementation plan

After design is approved, invoke `superpowers:writing-plans` skill. It will:
- Create bite-sized tasks
- Save plan to docs/plans/

### Step 5: Execute the plan

Ask the user which execution approach:
- **Subagent-driven (this session):** invoke `superpowers:subagent-driven-development`
- **Parallel session:** guide user to open new terminal with `vd-feature`

### Step 6: Post-implementation

After implementation is complete:

1. Update `docs/product/user-stories.md` — add the new feature as a story
2. Update `docs/architecture/api.md` — if any endpoints changed
3. Update `docs/plans/tasks.md` — mark completed tasks

Then print:

```
✓ Feature implemented.

Updated:
- docs/product/user-stories.md
- docs/architecture/api.md (if changed)
- docs/plans/tasks.md

Remember:
- Do NOT add translations now — wait for vd-release
- Run vd-tests to update test documentation
- /exit to close this session
```
