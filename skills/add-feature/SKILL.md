---
name: add-feature
description: Use when adding a new feature to a production project - orchestrates full cycle from idea through brainstorming, planning, implementation, to documentation updates
---

# Add Feature

## Overview

Full-cycle feature addition: idea → design → plan → implement → docs. Orchestrates superpowers skills in the right order with project-specific reminders.

**Type:** Architect (Opus)

## Process

### Step 0: Verify model

Check current model. If not Opus, switch: `/model opus`

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

⏸ Stop. Tell the user:
"Step 3 complete. Now run /superpowers:worktree in your terminal.
When done, come back and say 'done' to continue."

### Step 4: Design the feature

⏸ Stop. Tell the user:
"Step 4 complete. Now run /superpowers:brainstorm in your terminal.
When done, come back and say 'done' to continue."

### Step 4.5: Define contract

Before planning, write down the contract explicitly (3-10 lines is enough):
- Types / function signatures / API schema
- 1 input/output example
- Known error cases / edge cases

The contract is the alignment point between intent, code, and tests. Skipping it means tests will end up verifying what you wrote, not what you intended.

Save the contract as a section inside the design doc from Step 4, or as a separate file `docs/plans/<feature>-contract.md`.

### Step 5: Create implementation plan

After the contract (Step 4.5) is locked:

⏸ Stop. Tell the user:
"Step 5 complete. Now run /superpowers:write-plan in your terminal.
When done, come back and say 'done' to continue."

Each task in the plan must reference which part of the contract it implements.

### Step 6: Execute the plan

Ask the user which execution approach. **Parallel agents is recommended by default** — it lets tests and implementation run on separate agents in true parallel, which is the point of having a contract in Step 4.5.

- **Parallel agents (recommended):**
  ⏸ Stop. Tell the user:
  "Step 6 complete. Now run /superpowers:parallel in your terminal.
  When done, come back and say 'done' to continue."

- **Subagent-driven (this session):**
  ⏸ Stop. Tell the user:
  "Step 6 complete. Now run /superpowers:execute-plan in your terminal.
  When done, come back and say 'done' to continue."

- **Parallel session:**
  ⏸ Stop. Tell the user:
  "Step 6 complete. Now run /superpowers:execute-plan in a new terminal.
  When done, come back and say 'done' to continue."

**Rules that apply to every execution mode:**
- **Tests and code in parallel** — both derive from the contract (Step 4.5). No "code first, tests after".
- **Blast Radius Rule** (see `~/.claude/CLAUDE.md`) — smallest justified change, no "while I'm here" refactors, ask the user before expanding scope.

### Step 7: Code review

After implementation is complete:

⏸ Stop. Tell the user:
"Step 7 complete. Now run /superpowers:code-review in your terminal.
When done, come back and say 'done' to continue."

If feedback is received:

⏸ Stop. Tell the user:
"Step 7 complete. Now run /superpowers:code-review in your terminal to process the feedback.
When done, come back and say 'done' to continue."

### Step 8: Finish the branch

⏸ Stop. Tell the user:
"Step 8 complete. Now run /superpowers:finish-branch in your terminal.
When done, come back and say 'done' to continue."

### Step 9: Post-implementation

After merge:

1. Update `docs/product/user-stories.md` — add the new feature as a story
2. Update `docs/architecture/api.md` — if any endpoints changed
3. Update `docs/plans/tasks.md` — mark completed tasks

Print architect report with prepared prompt for Sonnet terminal:

```
✓ Architect report:
- Feature: <description>
- Design: <key decisions>
- Implementation: <files changed, endpoints added>
- Tests: <count> passing
- Merged to: <branch>

Updated:
- docs/product/user-stories.md
- docs/architecture/api.md (if changed)
- docs/plans/tasks.md

Do NOT add translations — wait for pre-release-check phase.

━━━ Next (Sonnet terminal) ━━━━━━━━━━━━━━━━
/vladyslav:write-test-docs

Context:
"Implemented <feature>. <count> endpoints added,
<count> tests passing. Update test documentation."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Or if all work is complete:
━━━ Ready for deploy ━━━━━━━━━━━━━━━━━━━━━━
All features implemented and tested.
- Live QA: docs/testing/manual-qa.md
- Deploy: docs/deployment.md
- Final check: /vladyslav:pre-release-check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
