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

### Step 0.1: Verify working directory

**This step is mandatory. Do not skip it.**

1. Check that `CLAUDE.md` exists in `pwd`. If not → **STOP**:
   > "No CLAUDE.md found in current directory. Are you in the right project? Expected a project root with CLAUDE.md. Current path: `<pwd>`"

2. Read the project name from `CLAUDE.md` (first heading or `# <ProjectName>` line).

3. Derive the canonical wing name:
   - Take `basename $(pwd)` → lowercase → replace spaces/underscores with hyphens
   - Prepend platform prefix if not already present (`swift-`, `python-`, `flutter-`, `kotlin-`, `web-`)
   - Example: `Sudoku` in `swift/` → `swift-sudoku` (NOT `swift-Sudoku`)

4. Run `mempalace_list_wings`. If a wing exists under a **different casing** (e.g. `swift-Sudoku` vs `swift-sudoku`) → warn the user:
   > "Warning: MemPalace has wing `swift-Sudoku` which looks like a stale duplicate. Using canonical `swift-sudoku` for all writes this session. The stale wing may contain records from a different directory."

5. **Path validation rule (mandatory for all MemPalace reads this session):**
   After any `mempalace_search`, scan each result for absolute file paths (`/Volumes/`, `/Users/`, `/home/`). For each path found:
   - If the path **exists on disk** → result is live, proceed normally
   - If the path **does NOT exist** → treat the drawer as `[STALE: path not found]`, do NOT act on it, flag it to the user before continuing

### Step 0.5: Choose mode

Ask the user: **"Manual mode or Auto mode?"**

- **Manual** (default, safest) — the historic flow: stop after each phase and tell the user to run `/superpowers:<name>` in their terminal. Use when the feature is unusual, high-risk, or you want tight control.
- **Auto** — after approving the contract and the plan, I run execution, code review, security check, tests, commits, docs update, and merge-to-dev **without further stops**, except when a guard rail triggers. Use for routine features where the contract is clear.

Record the chosen mode for the rest of the flow. Do **not** default to Auto silently — always ask.

**Auto-mode guard rails (automatic STOP + ask):**
- More than **2 files touched outside the approved plan** (new files not in the plan)
- **Any existing file refactored outside the plan** (refactor of a file that was "read-only reference" → STOP, regardless of size)
- **Contract or spec changed during execution** (the contract file from Step 4.5 has been modified)
- **Pre-commit auto-gate failure** (see Step 6.5) — tests, code review, or security check reports blocker

Any guard rail → stop, report the situation to the user, ask what to do. Do NOT attempt to work around a guard rail silently.

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

**Manual mode:**
⏸ Stop. Tell the user:
"Step 3 complete. Now run /superpowers:worktree in your terminal.
When done, come back and say 'done' to continue."

**Auto mode:**
Invoke the `superpowers:using-git-worktrees` skill via the Skill tool to create a `feature/<feature-name>` worktree directly. If the project does not use git worktrees (e.g. not a git repo or user opted out in CLAUDE.md), create a regular `feature/<feature-name>` branch via `git checkout -b`. Record the branch name for later steps.

### Step 4: Design the feature

**Manual mode:**
⏸ Stop. Tell the user:
"Step 4 complete. Now run /superpowers:brainstorm in your terminal.
When done, come back and say 'done' to continue."

**Auto mode:**
Invoke the `superpowers:brainstorming` skill via the Skill tool with the feature description from Step 2 plus the project context from Step 1. Capture the brainstorm output (design doc, key decisions, MVP cut).

Present the output to the user and ⏸ **stop for approval**:
"Here's the brainstorm result: <summary>. Approve to continue, reopen to iterate, or abort?"

This is **approval point #2** (first was the feature description in Step 2). Do NOT proceed to the contract until the user says approve.

### Step 4.5: Define contract

Before planning, write down the contract explicitly (3-10 lines is enough):
- Types / function signatures / API schema
- 1 input/output example
- Known error cases / edge cases

The contract is the alignment point between intent, code, and tests. Skipping it means tests will end up verifying what you wrote, not what you intended.

Save the contract as a section inside the design doc from Step 4, or as a separate file `docs/plans/<feature>-contract.md`.

**Both modes:** Present the contract to the user and ⏸ **stop for approval** — this is **approval point #3**. Read the contract out loud (it's 3-10 lines, trivial to verify). Do not proceed until the user approves.

**Auto mode:** After approval, record the contract file path and its current git blob hash (via `git hash-object`) — this is the baseline for the "contract changed during execution" guard rail. If the hash changes during Step 6, it triggers a STOP.

#### Auto-stash checkpoint: `contract-approved`

After the user approves the contract, invoke the `vladyslav:stash` skill (best-effort — do NOT abort the parent flow on failure) with:

- `source`: `"add-feature:auto:contract-approved"`
- `task`: short one-liner of the feature being added
- `open_question`: `"Contract approved — awaiting plan writing"`
- `done_in_session`: last 3-5 significant events from this skill's internal step log
- `pending_files`: `git status --short` at this point
- `deferred`: items the user deferred so far in this run (if any)

If `mempalace_add_drawer` fails → print a warning inline: *"Auto-stash failed: `<reason>`. Continuing — run `/stash` manually if you want a guaranteed snapshot."* and continue. Auto-stash is best-effort insurance; it MUST NOT break the primary workflow.

### Step 5: Create implementation plan

After the contract (Step 4.5) is locked:

**Manual mode:**
⏸ Stop. Tell the user:
"Step 5 complete. Now run /superpowers:write-plan in your terminal.
When done, come back and say 'done' to continue."

**Auto mode:**
Invoke the `superpowers:writing-plans` skill via the Skill tool, feeding it the contract + brainstorm output. Capture the plan — it must list each bite-sized task, which contract piece it implements, and (crucially) **which files each task will create or modify**. The file list is the baseline for the "files touched outside plan" guard rail.

Present the plan to the user and ⏸ **stop for approval** — this is **approval point #4**. Show:
- Task list (numbered)
- Files that will be created (new)
- Files that will be modified (existing)
- Files that are "read-only reference" (must NOT be refactored during execution)

Do not proceed to Step 6 until the user approves. Record the file lists — main thread will enforce them as guard rails.

Each task in the plan must reference which part of the contract it implements.

#### Auto-stash checkpoint: `plan-approved`

After the user approves the plan, invoke the `vladyslav:stash` skill (best-effort — do NOT abort on failure) with:

- `source`: `"add-feature:auto:plan-approved"`
- `task`: short one-liner of the feature
- `open_question`: `"Plan approved — awaiting execution start"`
- `done_in_session`: recent checkpoint events (contract-approved, plan written, plan approved)
- `pending_files`: `git status --short`
- `deferred`: any deferred items

If `mempalace_add_drawer` fails → print a warning inline and continue. Auto-stash is insurance, never a blocker.

### Step 6: Execute the plan

**Manual mode:**

Ask the user which execution approach. **Parallel agents is recommended by default.**

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

**Auto mode:**

Execute the plan directly via parallel subagents. **Do NOT stop to ask between tasks** unless a guard rail triggers.

For each batch of parallelizable tasks from the plan:

1. **Launch two subagents in parallel via the Agent tool** (single message, two tool calls):
   - Agent A — `subagent_type: "general-purpose"`, `isolation: "worktree"`. Prompt includes: the contract, the brainstorm result, the relevant task from the plan, and this strict instruction:
     > "You may only CREATE or MODIFY these files: `<plan's file list for this task>`. Files outside this list are read-only — do NOT touch them. If you discover you need to modify a file outside the list, STOP and report `SCOPE EXPANSION REQUIRED: <path> — <reason>` instead of making the change. Do NOT modify the contract file `<contract path>` under any circumstances — that file is frozen."
   - Agent A writes **tests** for the contract piece.
   - Agent B — same settings. Agent B writes the **implementation** for the contract piece, against the same file list constraint.

2. **Wait for both agents to return.**

3. **Run guard rail checks on the combined changes:**
   - `git status --short` and `git diff --stat` on the worktree
   - Compute the set of files touched
   - **Check #1 (file count):** compare touched files vs the plan's file list. If more than **2 files** are outside the plan → STOP + report.
   - **Check #2 (existing-file refactor):** for each touched file that IS in the plan, check whether it was marked "read-only reference" in the plan. If yes → STOP + report.
   - **Check #3 (contract hash):** recompute `git hash-object <contract path>` and compare to the baseline from Step 4.5. If different → STOP + report.
   - **Check #4 (scope expansion keyword):** scan either agent's output for `SCOPE EXPANSION REQUIRED`. If present → STOP + report that agent's message verbatim to the user.

4. **If all four checks pass → proceed to Step 6.5** (auto-gate). If Step 6.5 also passes → commit and move to the next batch.

#### Auto-stash checkpoint: `subagent-task-complete:N`

After each batch's commit succeeds (Step 6.5 passed + commit made), invoke the `vladyslav:stash` skill (best-effort — do NOT abort on failure) with:

- `source`: `"add-feature:auto:subagent-task-complete:<N>"` (substitute the concrete task number)
- `task`: short one-liner of the feature
- `open_question`: `"Subagent task <N> complete — awaiting task <N+1>"`
- `done_in_session`: last 3-5 significant events
- `pending_files`: `git status --short` (usually empty right after commit)
- `deferred`: any deferred items

If `mempalace_add_drawer` fails → print a warning inline and continue. Never block the batch loop.

5. **Repeat** until the plan is fully executed.

**Rules that apply to every execution mode:**
- **Tests and code in parallel** — both derive from the contract (Step 4.5). No "code first, tests after".
- **Blast Radius Rule** (see `~/.claude/CLAUDE.md`) — smallest justified change, no "while I'm here" refactors, ask the user before expanding scope.

### Step 6.5: Auto-gate (auto mode only)

**Runs before every commit in auto mode. Blocks the commit on failure. No user approval needed for the gate itself — only if it fails.**

Execute these three checks sequentially. If all pass → commit. If any fails → STOP, report, ask the user what to do.

1. **Tests.** Detect the project's test command (`package.json scripts.test`, `pytest`, `go test ./...`, `xcodebuild test`, `Makefile test` target, or CLAUDE.md's documented test command). Run it against the current worktree. **Blocker if any test fails.**

2. **Code review.** Dispatch a review agent via the Agent tool:
   - `subagent_type: "pr-review-toolkit:code-reviewer"` (preferred), or `"feature-dev:code-reviewer"` as fallback
   - Prompt: "Review the staged diff (`git diff --cached`) for bugs, logic errors, security issues, and project-convention violations. Report only HIGH-confidence issues. Flag silent failures and inadequate error handling specifically."
   - **Blocker if the agent reports any HIGH-severity issue.**

3. **SwiftUI review (iOS projects only).** If the project uses Swift/SwiftUI (detected by `.xcodeproj`, `Package.swift`, or `.swift` files in the staged diff), invoke the `vladyslav:swiftui-pro` skill via the Skill tool, scoped to the staged diff files. **Blocker if the skill reports any HIGH-severity issue** (deprecated API, accessibility violation, Swift concurrency data race).

4. **Security.** Invoke the security checker:
   - Preferred: Skill tool → `superpowers:owasp-security` (scoped to the staged diff)
   - Fallback: Agent tool → `subagent_type: "pr-review-toolkit:silent-failure-hunter"`
   - **Blocker if: injection risks, secrets in diff, authZ gaps on mutations, silent catch blocks without logging.**

**If all checks pass:** proceed to commit. The pre-commit hook (`~/.claude/hooks/pre-commit-review.sh`) will still fire as an additional safety net — that's expected, not redundant. Compose a concise commit message referencing the contract piece, stage only the files from the plan (not `git add -A`), commit.

**If any check fails:**
- Print the failure details to the user
- Stop the loop
- Ask: "Auto-gate failure at <step>. <details>. How to proceed? (fix and retry / reopen plan / abort feature)"
- Do NOT bypass the gate. Do NOT weaken the check ("the test is flaky, let's skip it"). The gate is a contract with the user.

#### Auto-stash checkpoint: `auto-gate-blocker`

Before asking the user how to proceed, invoke the `vladyslav:stash` skill (best-effort — do NOT abort on failure) with:

- `source`: `"add-feature:auto:auto-gate-blocker"`
- `task`: short one-liner of the feature
- `open_question`: `"Auto-gate blocked on: <reason>"` (substitute the concrete failure reason)
- `done_in_session`: last 3-5 significant events
- `pending_files`: `git status --short`
- `deferred`: any deferred items

If `mempalace_add_drawer` fails → print a warning inline and continue with the "how to proceed" question to the user. The stash is best-effort insurance so an interrupted session can resume the gate decision.

### Step 7: Code review

**Manual mode:**

After implementation is complete:

⏸ Stop. Tell the user:
"Step 7 complete. Now run /superpowers:code-review in your terminal.
When done, come back and say 'done' to continue."

If feedback is received:

⏸ Stop. Tell the user:
"Step 7 complete. Now run /superpowers:code-review in your terminal to process the feedback.
When done, come back and say 'done' to continue."

**Auto mode:**

The per-commit auto-gate (Step 6.5) already runs the code review agent on each commit, so a final code review pass is usually redundant. Exception: run one **whole-branch review** at the end via Agent tool `subagent_type: "pr-review-toolkit:code-reviewer"` with prompt "Review the entire branch diff (`git diff main...HEAD`) for cross-commit issues — inconsistencies, partial refactors, dead code left between commits."

If the whole-branch review surfaces issues: dispatch another subagent to fix them (same file-scope constraint as Step 6), re-run auto-gate, then proceed. No user approval needed unless a guard rail triggers.

### Step 8: Finish the branch

**Manual mode:**

⏸ Stop. Tell the user:
"Step 8 complete. Now run /superpowers:finish-branch in your terminal.
When done, come back and say 'done' to continue."

**Auto mode:**

Merge the feature branch into `dev` (or the project's development branch — detect from `git branch -r` or CLAUDE.md) **automatically, without user approval**. Use a merge commit (not squash) by default so the per-commit history is preserved, unless the project's CLAUDE.md specifies otherwise.

Do **NOT** merge into `main` automatically. Merge-to-main is **approval point #5** — after the report in Step 9, ask the user: "All checks passed, dev branch is updated. Merge to main now? (yes / not yet / never on auto)". On `yes`, merge to main. On `not yet`, leave it on dev and note in the report. On `never on auto`, record a preference memory and never ask again for this project.

### Step 9: Post-implementation

After merge (both modes — auto does this without stopping, manual requires the user to confirm merge happened):

1. Update `docs/product/user-stories.md` — add the new feature as a story
2. Update `docs/architecture/api.md` — if any endpoints changed
3. Update `docs/plans/tasks.md` — mark completed tasks
4. Write a MemPalace `decision` record to the project wing: `[WHAT] feature <name> implemented, [CONTRACT] <path>, [FILES] <list>, [DATE] <today>`
5. **Auto mode:** run `git diff --stat main...HEAD` to produce the blast-radius summary for the report (files touched vs plan)

Print architect report with prepared prompt for Sonnet terminal:

```
✓ Architect report:
- Feature: <description>
- Mode: <manual|auto>
- Design: <key decisions>
- Implementation: <files changed, endpoints added>
- Blast radius: <files touched> / <files planned> — <match|expanded with approval|within plan>
- Tests: <count> passing
- Auto-gate runs: <count> (auto mode) — review HIGH issues: <count>, security issues: <count>
- Guard rail triggers: <count> (auto mode) — all resolved with user approval
- Merged to: <branch>
- Merge to main: <yes|pending user approval|never on auto>

Updated:
- docs/product/user-stories.md
- docs/architecture/api.md (if changed)
- docs/plans/tasks.md
- MemPalace wing <name> — decision record added

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

## Auto-mode approval map (quick reference)

**Approval required (user must say yes):**
1. Feature description (Step 2)
2. Brainstorm output (Step 4)
3. Contract (Step 4.5)
4. Plan (Step 5)
5. Merge to `main` (Step 8 end)
6. Any guard rail trigger (Step 6 checks #1-4, Step 6.5 failures)
7. Final pre-release check (separate skill: `/vladyslav:pre-release-check`)

**Automatic (no approval — runs nonstop):**
- Worktree / branch creation (Step 3)
- Parallel agent dispatch for tests + code (Step 6)
- Tests → code review → SwiftUI review (iOS only) → security checks before each commit (Step 6.5)
- Commit messages, staging, committing
- Merge to `dev` branch (Step 8)
- Updates to `docs/product/user-stories.md`, `docs/architecture/api.md`, `docs/plans/tasks.md`
- MemPalace `decision` record writes

**Guard rails — silent auto-STOP + ask:**
- More than 2 files touched outside the plan
- Any existing file refactored that was marked "read-only reference"
- Contract file hash changed during execution
- `SCOPE EXPANSION REQUIRED` in any agent's output
- Auto-gate blocker: test failure / HIGH-severity review issue / security finding

**Design principle:** Auto mode is fast for **routine** features where the contract is clear. When something unexpected comes up, a guard rail should catch it and escalate — not silently absorb it. If a user finds themselves repeatedly approving guard rail triggers for the same kind of expansion, that's a signal the plan format should be richer, not that the guard rails should be loosened.
