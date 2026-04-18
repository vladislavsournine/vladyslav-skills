# Design: Session Continuity — Stash/Unstash + Scope Sentinel

**Date:** 2026-04-16
**Status:** Revised — Latest-wins semantics + auto-stash integration
**Scope:** New `vladyslav:stash` and `vladyslav:unstash` skills + 2 global rules in `~/.claude/CLAUDE.md` + auto-stash checkpoints in `add-feature` / `fix-bug`.

## Revision Notes (2026-04-16, after pre-flight)

Two design changes after pre-flight revealed MemPalace API constraints and user mid-design requirement change:

1. **Drawer API is immutable.** `mempalace_add_drawer` only adds; there is no update. Therefore `active: true/false` + `archived_at` approach is infeasible. Replaced with **Latest-wins semantics** — the newest drawer with `room=stash` for a wing IS the active stash; older drawers are archived by virtue of not being newest. All stash history remains searchable.
2. **Auto-stash added** (user request): long-running skills (`add-feature`, `fix-bug`) invoke `vladyslav:stash` at meaningful checkpoints so that incomplete executions are captured even if the user never runs `/stash`. See Component 6.

## Problem

Two related continuity gaps surfaced in regular use:

1. **Lost spec/plan context across sessions.** When the user creates a spec for a task, switches to an unrelated task, then returns — the agent often re-creates the spec from scratch instead of continuing the existing one. Existing skills (`superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:executing-plans`) have no detection of in-progress work in `docs/plans/` or `docs/superpowers/specs/`, and `vladyslav:*` skills (`add-feature`, `write-user-stories`) similarly start fresh each invocation.

2. **No mid-conversation snapshot mechanism.** Mid-discussion (e.g. agent has just asked the user to choose between options A/B/C and the user has not yet decided), there is no way to capture this exact mental state and resume it later. The user must either decide on the spot, or lose the context when the session closes.

A third issue surfaced during brainstorming: **scope creep mid-execution**. While running `vladyslav:add-feature`, the user often says "let's also add X" — the agent silently expands scope without classifying whether X is a clarification, an extension, or a separate task. The existing `Blast Radius Rule` in `~/.claude/CLAUDE.md` only governs the agent's own scope expansion, not user-driven scope creep during skill execution.

## Decision

Build a single **continuity primitive** — `stash`/`unstash` — that captures and restores the full mental state of a paused conversation, persisted in MemPalace. Add a global **Scope Sentinel** rule that classifies mid-execution requests and routes "separate task" cases through `stash`. Add a global **session-start notification** that surfaces an active stash without blocking the user.

These four components together solve all three problems:

- Problem 1 (lost specs) → solved indirectly by stash + session-start notification: if the user stashes before closing, `unstash` restores everything; if they forget, the notification reminds them.
- Problem 2 (mid-conversation snapshot) → solved directly by stash storing `open_question` + `done_in_session` + `pending_files`.
- Problem 3 (scope creep) → solved by Scope Sentinel; case (C) "separate task" calls `stash` for a clean context switch.

## Files Changed

| File | Change |
|------|--------|
| `commands/stash.md` | New — thin command delegating to `vladyslav:stash` skill |
| `commands/unstash.md` | New — thin command delegating to `vladyslav:unstash` skill |
| `skills/stash/SKILL.md` | New — Engineer (Sonnet); collects mental state and writes to MemPalace |
| `skills/unstash/SKILL.md` | New — Engineer (Sonnet); reads active stash from MemPalace and restores it into conversation |
| `~/.claude/CLAUDE.md` | Add 2 sections: "Scope Sentinel (Mid-Execution Requests)" and "Active Stash Notification" |
| MemPalace taxonomy | Add new `room_type: stash` (verify via `mempalace_get_taxonomy`; add via taxonomy update mechanism if absent) |
| `.claude-plugin/plugin.json` | Bump version (per repo working rule) |
| `README.md` | Document the two new skills under Workflow Overview |
| `docs/architecture/system.md` | Document continuity primitive briefly |

**Out of repo:** `~/.claude/CLAUDE.md` is the user's global config, not in this repo. The plan must include a manual step for the user to apply the two CLAUDE.md sections, with the exact text provided in the plan.

## Resolved Design Decisions

These were decided during brainstorming. Each is locked unless explicitly reopened.

| # | Decision | Choice |
|---|----------|--------|
| 1 | What does stash capture? | (b) Conversational state + pending file list (no diffs, no auto-commit) |
| 2 | Where is stash persisted? | MemPalace only (no disk file duplication) |
| 3 | Scope Sentinel classification — who decides? | (iii) Agent decides (A) "clarification" silently; always asks user for (B) "extension" and (C) "separate task" |
| 4 | How many active stashes per project? | (a) One active per wing — realized via Latest-wins |
| 5 | Session-start behavior when stash exists? | (d) Show informational status line in first response, do not block |
| 6a | Conflict — new `stash` while one is already active? | (ii) **Latest-wins** — the newest drawer with `room=stash` for the wing IS active. No explicit archive step. Older drawers remain in MemPalace, searchable, but are not "active". |
| 6b | How is wing detected? | (i+fallback) Map `cwd` → wing. Take `basename $(pwd)`, **strip leading dots** (handles `.vladyslav-skills` → `vladyslav-skills`), lowercase, replace `_`/`.`/spaces with `-`, prepend platform prefix if missing. Compare against wings list in `~/.claude/CLAUDE.md`; if no match, ask user with autocomplete. |
| 7 | Auto-stash in long-running skills? | **Yes** — `add-feature` and `fix-bug` invoke `vladyslav:stash` at defined checkpoints (Component 6). `added_by` field distinguishes auto from manual. |

## Component 1 — `vladyslav:stash`

**Type:** Engineer (Sonnet)
**Trigger:** `/stash` slash command, or natural-language "stash this", "збережи стан", "зробити stash".

**Process:**

1. **Detect wing.** Read `cwd`. Map against the wings list in `~/.claude/CLAUDE.md` (currently: `swift-calories`, `brain`, `swift-homePlayer`, `swift-setlo`, `python-tax`, `python-artur`, `swift-invinoveritas`, `phD`, `swift-sudoku`, `python-video-factory`, `python-floops`, `python-artur2`, `documents`, `python-guitar`, `claude-init`, `vladyslav-skills`, `flutter-paolo`). If `cwd` root folder matches a wing → use it. Otherwise ask user with autocomplete.

2. **Collect mental state from conversation.** Build a structured snapshot:
   - `task` — 1–2 sentences describing the active piece of work
   - `open_question` — current point of discussion / decision pending / "we were debating X" (this is the most important field; without it `unstash` cannot resume the exact moment)
   - `done_in_session` — short list of decisions made, code written, files touched in this session
   - `pending_files` — list of modified-but-uncommitted files with one-line description per file ("what I was doing there"); detect via `git status -s` if available, otherwise from session memory
   - `deferred` — items the user explicitly deferred or that surfaced as "while I'm here" but were not done

3. **No explicit archive step** (Latest-wins). The new drawer created in Step 4 becomes the active stash automatically because it has the newest timestamp. Older stash drawers remain in MemPalace and are searchable but are no longer considered active.

4. **Create new stash drawer.** Call `mempalace_add_drawer` with:
   - `wing`: `<canonical-wing-from-step-1>`
   - `room`: `"stash"`
   - `added_by`: `"mcp"` (for manual `/stash`) or `"add-feature:auto"` / `"fix-bug:auto"` (for auto-stash — see Component 6)
   - `content`: serialized as a single string with the exact YAML below (MemPalace stores content verbatim; keeping it as YAML lets `unstash` parse it back):

   ```yaml
   created_at: 2026-04-16T14:32:00+03:00
   source: manual | add-feature:auto:<checkpoint-name> | fix-bug:auto:<checkpoint-name>
   task: "1-2 sentence summary"
   open_question: "current decision point, or 'no open question'"
   done_in_session:
     - "decision or file written"
   pending_files:
     - path: "src/auth/middleware.ts"
       note: "added skeleton, needs tests"
   deferred:
     - "verify CORS — out of scope of feature X"
   ```

   `created_at` is written into the content (not a separate field) because `mempalace_add_drawer` does not return a server timestamp we can rely on. `unstash` sorts by this `created_at` to find the latest.

5. **Confirm to user.** Output: `Stashed for <wing>. Older stashes remain as history. /unstash to resume.`

## Component 2 — `vladyslav:unstash`

**Type:** Engineer (Sonnet)
**Trigger:** `/unstash` slash command, or natural-language "unstash", "продовжимо stash", "відкрий stash".

**Process:**

1. **Detect wing** (same logic as `stash`).

2. **Find latest stash (Latest-wins).** `mempalace_search` with `wing=<wing>, room="stash"`, query="stash created_at" (broad match), limit=20. Parse each drawer's YAML content; extract `created_at`. Select the drawer with the **newest `created_at`** as active. Older drawers are implicitly archived — they remain searchable but are not restored by default.

3. **Handle empty case.** If no stash drawers found for this wing → output: `No stash for wing <wing>.` Offer cross-wing search as optional: `Search other wings? (y/n)`.

4. **Validate freshness.** For each `pending_files` entry, `git status -s` to confirm the file still has changes. If a file is now clean → flag it in output ("file `<path>` is now clean — likely committed since stash"). This implements the "before recommending from memory" rule from `~/.claude/CLAUDE.md` (verify before acting).

5. **Restore into conversation.** Output structured restoration:
   ```
   Resuming: <task>

   Where we stopped: <open_question>

   Done previously in this thread:
   - <done_in_session items>

   Pending files (verify state before resuming):
   - <pending_files items, with freshness flags>

   Deferred:
   - <deferred items>

   Ready to continue. What's next?
   ```

6. **Wait for user input.** Do not auto-act on the restored context. The user drives the next step (often: answering the previously-open question).

## Component 3 — Scope Sentinel (global rule)

**Location:** New section in `~/.claude/CLAUDE.md`.

**Exact text to insert:**

```markdown
## Scope Sentinel (Mid-Execution Requests)

When the user issues a new request WHILE you are already executing a skill or command:

1. STOP — do not begin the new request immediately.
2. Classify silently: (A) clarification of current task, (B) extension of current task, (C) separate task.
3. **(A) Clarification** ("the field is `email` not `mail`") → continue without asking.
4. **(B) Extension** ("also add sorting to this list") → ask: *"Expand current plan to include this, or queue as Deferred follow-up?"*
5. **(C) Separate task** ("by the way, fix the auth bug") → ask: *"Stash current work and switch, or finish current first?"* — if user picks stash → invoke `vladyslav:stash` before switching.

Never silently expand scope. (B) and (C) always require explicit user confirmation.

This rule complements the Blast Radius Rule (which governs agent-driven scope expansion); Scope Sentinel governs user-driven mid-execution scope changes.
```

## Component 4 — Active Stash Notification (global rule)

**Location:** New section in `~/.claude/CLAUDE.md`, near the MemPalace section.

**Exact text to insert:**

```markdown
## Active Stash Notification (Session Start)

At the start of any session inside a project that maps to a wing:
1. Run `mempalace_search` with `wing=<current-wing>, room="stash"`, query="stash created_at", limit=5. Parse each returned drawer's YAML `content` and extract `created_at`.
2. If at least one result exists, take the drawer with the **newest `created_at`** — this is the latest stash. Prefix the FIRST response in the session with:
   > ℹ Latest stash: `<task>` (from `<created_at>`, source `<source>`). `/unstash` to resume.
3. Then proceed with the user's actual request. Do NOT block, do NOT ask for confirmation. Pure information. Do NOT fetch or display older stashes.

This runs once per session, not per message. If the user explicitly says "ignore stash" or "no memory", skip this check.
```

## Component 5 — MemPalace room convention

MemPalace `room` parameter is free-form; there is no enum enforcement. Creating a drawer with `room="stash"` automatically registers the room type in the taxonomy. No separate registration step is needed.

**Drawer schema for stash (content field, stored verbatim as YAML text):**

```yaml
created_at: <iso8601-with-timezone>         # used by unstash/notification for latest-wins
source: manual | add-feature:auto:<checkpoint> | fix-bug:auto:<checkpoint>
task: "1-2 sentence summary"
open_question: "current decision point or 'no open question'"
done_in_session:
  - "each item one line"
pending_files:
  - path: "<repo-relative-path>"
    note: "<one-line description of work in progress>"
deferred:
  - "item with reason"
```

**Distinguishing fields:**
- `wing` + `room="stash"` filters drawers to stashes for one project.
- Within that set, `created_at` orders them — newest is active.
- `source` distinguishes manual from auto-stash (affects `unstash` output phrasing: "last manual stash" vs "auto-checkpoint at <checkpoint-name>").

## Component 6 — Auto-stash integration in long-running skills

**Goal:** Guarantee that incomplete executions of `add-feature` or `fix-bug` leave a recoverable stash, even if the user closes the session without invoking `/stash`.

**Mechanism:** The two long-running skills invoke `vladyslav:stash` (same skill used by `/stash`) at defined checkpoints. Each invocation passes `source` metadata identifying which skill and which checkpoint fired the auto-stash. `unstash` displays this source so the user knows whether they are resuming manual or automatic state.

### 6.1 — `skills/add-feature` checkpoints

Trigger an auto-stash (via `vladyslav:stash` call with `source: "add-feature:auto:<name>"`) at each of:

| Checkpoint name | Fires after | `open_question` content |
|-----------------|-------------|-------------------------|
| `contract-approved` | User approves the contract in Step 4.5 | `"Contract approved — awaiting plan writing"` |
| `plan-approved` | User approves the implementation plan | `"Plan approved — awaiting execution start"` |
| `subagent-task-complete:N` | Each completed subagent task in auto-mode | `"Subagent task N complete — awaiting task N+1"` |
| `auto-gate-blocker` | Auto-gate finds a blocker (tests/review/security) | `"Auto-gate blocked on: <reason>"` |

Auto-stash calls do NOT re-execute wing detection — they inherit wing from the skill's current directory (`add-feature` already validates this in Step 0.1).

### 6.2 — `skills/fix-bug` checkpoints

Trigger an auto-stash at each of:

| Checkpoint name | Fires after | `open_question` content |
|-----------------|-------------|-------------------------|
| `reproduction-written` | Failing test that reproduces the bug is committed | `"Reproduction test committed — awaiting fix"` |
| `fix-applied` | Fix committed, test now passes | `"Fix applied and test passing — awaiting regression verification"` |
| `regression-passed` | Full test suite passes after fix | `"Regression clean — ready to merge"` |

### 6.3 — `pending_files` collection in auto-stash

Same logic as manual: `git status --short` at the time of the checkpoint. If between checkpoints the user committed interim work, `pending_files` may be empty — that's correct and `unstash` will reflect "no pending files".

### 6.4 — `done_in_session` in auto-stash

Populate with the skill's internal step summary (e.g., `add-feature` already records what step it just finished). Do NOT replay the entire conversation — keep it to 3-5 bullets of the most recent significant events.

### 6.5 — Failure handling inside auto-stash

If `mempalace_add_drawer` fails during auto-stash → log a warning inline (*"Auto-stash failed: <reason>. Continuing — manual `/stash` recommended."*) but do NOT abort the parent skill. Auto-stash is best-effort insurance; it must not break the primary workflow.

## Out of Scope

- **No git-level auto-commit or `git stash`.** The conversational auto-stash in Component 6 writes to MemPalace only. User retains full control of their git state. `pending_files` is a textual note only.
- **No multi-stash stack** (named stashes, `stash list`, `stash pop <id>`). One active per wing (Latest-wins). Older stashes remain in MemPalace and are searchable via `mempalace_search` if needed but have no first-class UI.
- **No mid-session conversation replay.** `unstash` reconstructs context as a structured summary, not a verbatim transcript.
- **No changes to `superpowers:*` skills.** They remain untouched (per user constraint — "не буду апдейтіть чужий репозитарій"). Continuity for superpowers-driven specs is handled indirectly via session-start notification + manual `unstash`.
- **No automatic linking from stash → spec/plan files.** If a stash references a spec at `docs/plans/X-design.md`, the `pending_files` field handles that. No separate "linked spec" field.

## Open Questions

None at design time. All key decisions resolved in brainstorming (table above).

## Notes

- **Wing detection edge case:** The wings list in `~/.claude/CLAUDE.md` is hand-maintained. If the user adds a new project but forgets to update the wings list, `stash` will fall back to asking. The plan should include a note in the `stash` SKILL telling the user how to add a new wing to the global list when prompted.
- **MemPalace dependency:** This entire design depends on MemPalace being available in the session. If the MCP server is down, `stash` should fail loudly with `MemPalace unavailable — cannot stash. Try again when MCP is reachable.` rather than silently degrading to a local file (which would violate decision #2).
- **No translations until pre-release-check** (per repo working rule). Skill SKILL.md files written in English. User-facing strings (the notification, the `stash`/`unstash` confirmation messages) — in English for now; translation pass during pre-release-check if needed.
