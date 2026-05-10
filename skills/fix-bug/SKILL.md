---
name: fix-bug
description: Use when fixing a bug in a production project. Full cycle: diagnose, fix, regression test, review, docs.
---

# Fix Bug

## Overview

Full-cycle bug fix: diagnose → fix → test → review → merge → update docs. Orchestrates superpowers skills in the right order with project-specific reminders.

**Type:** Architect

## Process

### Step 0: Verify working directory

**This step is mandatory. Do not skip it.**

1. Check that `CLAUDE.md` exists in `pwd`. If not → **STOP**:
   > "No CLAUDE.md found in current directory. Are you in the right project? Current path: `<pwd>`"

2. Derive the canonical wing name:
   - `basename $(pwd)` → lowercase → replace spaces/underscores with hyphens
   - Prepend platform prefix if not present (`swift-`, `python-`, `flutter-`, etc.)
   - Example: `Sudoku` in `swift/` → `swift-sudoku` (NOT `swift-Sudoku`)

3. Run `mempalace_list_wings`. If a wrong-case duplicate wing exists → warn the user (same project under two names = stale records risk).

4. **Path validation rule (mandatory for all MemPalace reads this session):**
   After any `mempalace_search`, for each result containing absolute file paths: verify the path exists on disk. If not → mark `[STALE: path not found]` and do not act on it.

### Step 1: Read project context

Read these files before anything else:
- `CLAUDE.md`
- `docs/architecture/system.md`
- `docs/architecture/api.md` (if exists)
- `docs/product/user-stories.md`
- `docs/plans/tasks.md`

### Step 2: Get bug description

Ask the user to describe the bug. Accept:
- Free text description
- Link to issue/ticket
- Error message or stack trace
- Steps to reproduce

### Step 3: Create worktree

Invoke `superpowers:using-git-worktrees` to create an isolated branch for the fix. Branch name: `fix/<short-bug-description>`.

### Step 4: Diagnose the bug

Invoke `superpowers:systematic-debugging` skill. Follow it exactly — it will:
- Form hypotheses
- Gather evidence systematically
- Identify root cause
- Avoid jumping to conclusions

### Step 5: Write regression test + fix

**Respect the Blast Radius Rule** (see `~/.claude/CLAUDE.md`): the fix must be the smallest justified change that addresses the root cause. If a larger restructuring would genuinely be better, **STOP and ask the user** before expanding scope — don't silently refactor.

Invoke `superpowers:test-driven-development` skill:
1. Write a failing test that reproduces the bug
2. Run test — verify it fails
3. Write the minimal fix that addresses the root cause (not just the symptom)
4. Run test — verify it passes
5. Run full test suite — verify nothing else broke
6. Run `git diff --stat` — confirm the change footprint matches the declared scope

### Step 6: Code review

Invoke `superpowers:requesting-code-review` to verify:
- Fix addresses root cause, not just symptom
- No regressions introduced
- Test coverage is adequate

If feedback is received, invoke `superpowers:receiving-code-review` to process it with technical rigor — verify before implementing suggestions.

### Step 7: Finish the branch

Invoke `superpowers:finishing-a-development-branch` — it will guide merge, PR, or cleanup.

### Step 8: Update docs

After merge:

1. `docs/product/user-stories.md` — add note about the fix or update affected story status
2. `docs/testing/manual-qa.md` — add regression check for this bug
3. `docs/plans/tasks.md` — mark bug task as done (if it was tracked)

### Step 9: Finish

Print architect report:

```
✓ Architect report:
- Bug: <description>
- Root cause: <what was wrong>
- Fix: <what was changed>
- Regression test: <test file and test name>
- Merged to: <branch>

Updated:
- docs/product/user-stories.md
- docs/testing/manual-qa.md
- docs/plans/tasks.md

Do NOT add translations — wait for pre-release-check phase.

Next steps:
- /vladyslav:write-test-docs — update test documentation for the fix
- /vladyslav:pre-release-check — run pre-release verification before shipping
```
