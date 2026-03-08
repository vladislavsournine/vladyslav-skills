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

### Step 3: Create worktree (optional)

Invoke `superpowers:using-git-worktrees` to create an isolated worktree for this feature. Recommended for production projects to keep main branch clean.

### Step 4: Design the feature

Invoke `superpowers:brainstorming` skill. Follow it exactly — it will:
- Ask clarifying questions
- Propose approaches
- Present design for approval
- Save design doc

### Step 5: Create implementation plan

After design is approved, invoke `superpowers:writing-plans` skill. It will:
- Create bite-sized tasks
- Save plan to docs/plans/

### Step 6: Execute the plan

Ask the user which execution approach:
- **Subagent-driven (this session):** invoke `superpowers:subagent-driven-development`
- **Parallel session:** invoke `superpowers:executing-plans` in a new terminal
- **Parallel agents:** invoke `superpowers:dispatching-parallel-agents` if tasks are independent

### Step 7: Code review

After implementation is complete, invoke `superpowers:requesting-code-review` to verify the work meets requirements.

If feedback is received later, use `superpowers:receiving-code-review` to process it with technical rigor.

### Step 8: Finish the branch

Invoke `superpowers:finishing-a-development-branch` — it will guide merge, PR, or cleanup.

### Step 9: Post-implementation

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
