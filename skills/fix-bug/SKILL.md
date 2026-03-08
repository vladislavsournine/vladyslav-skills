---
name: fix-bug
description: Use when fixing a bug in a production project - orchestrates full cycle from diagnosis through fix, regression test, code review, docs update, and branch merge
---

# Fix Bug

## Overview

Full-cycle bug fix: diagnose → fix → test → review → merge → update docs. Orchestrates superpowers skills in the right order with project-specific reminders.

**Recommended model:** Opus (`vd-fix` command uses it automatically)

## Process

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

Invoke `superpowers:test-driven-development` skill:
1. Write a failing test that reproduces the bug
2. Run test — verify it fails
3. Write the minimal fix
4. Run test — verify it passes
5. Run full test suite — verify nothing else broke

### Step 6: Code review

Invoke `superpowers:requesting-code-review` to verify:
- Fix addresses root cause, not just symptom
- No regressions introduced
- Test coverage is adequate

If feedback is received, use `superpowers:receiving-code-review` to process it.

### Step 7: Finish the branch

Invoke `superpowers:finishing-a-development-branch` — it will guide merge, PR, or cleanup.

### Step 8: Update docs

After merge:

1. `docs/product/user-stories.md` — add note about the fix or update affected story status
2. `docs/testing/manual-qa.md` — add regression check for this bug
3. `docs/plans/tasks.md` — mark bug task as done (if it was tracked)

### Step 9: Finish

Print summary, then offer flow transition:

```
✓ Bug fixed and merged.

Fix: <one-line summary of what was wrong and how it was fixed>
Regression test: <test file and test name>

Updated:
- docs/product/user-stories.md
- docs/testing/manual-qa.md
- docs/plans/tasks.md

Do NOT add translations now — wait for vd-release.

Next step: vd-tests (Sonnet) to update test documentation, or vd-release (Sonnet) if ready to ship.

1) Continue to vd-tests here — invoke /vladyslav:write-test-docs in this session
   ⚠️ Current session uses Opus. vd-tests recommends Sonnet (cheaper).
2) Continue to vd-release here — invoke /vladyslav:pre-release-check in this session
   ⚠️ Current session uses Opus. vd-release recommends Sonnet (cheaper).
3) New session (recommended for cost) — run `vd-tests` or `vd-release` in a new terminal
4) Done for now — /exit
```

**If "Continue here":** invoke the chosen skill via Skill tool.

**If "New session":** print:
```
Run in a new terminal:
  vd-tests    # to update test documentation
  vd-release  # if ready to ship

Context to paste:
  "Just fixed bug: <description>. Root cause: <cause>. Regression test added in <file>."
```

**If "Done":** remind about translations rule and print `/exit`.
