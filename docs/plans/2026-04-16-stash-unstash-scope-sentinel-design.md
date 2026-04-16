# Design: Session Continuity — Stash/Unstash + Scope Sentinel

**Date:** 2026-04-16
**Status:** Draft (awaiting user review)
**Scope:** New `vladyslav:stash` and `vladyslav:unstash` skills + 2 global rules in `~/.claude/CLAUDE.md` + MemPalace taxonomy update.

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
| 4 | How many active stashes per project? | (a) One active per wing |
| 5 | Session-start behavior when stash exists? | (d) Show informational status line in first response, do not block |
| 6a | Conflict — new `stash` while one is already active? | (ii) Auto-archive the old one (set `active: false`, add `archived_at`); new stash becomes active. Old remains searchable. |
| 6b | How is wing detected? | (i+fallback) Map `cwd` → wing (root folder name ≈ wing name) with hardcoded list from `~/.claude/CLAUDE.md`; if no match, ask user with autocomplete |

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

3. **Archive previous active stash for this wing.** `mempalace_search` with filters `wing=<wing>, room_type=stash, active=true`. If found, update that drawer: `active: false`, `archived_at: <now>`. (Old stash remains searchable but is no longer the active one.)

4. **Create new stash drawer.** Call `mempalace_kg_add` with:
   ```yaml
   wing: <wing>
   room_type: stash
   active: true
   created_at: <iso8601>
   archived_at: null
   content:
     task: "..."
     open_question: "..."
     done_in_session: ["...", "..."]
     pending_files:
       - path: "src/auth/middleware.ts"
         note: "added skeleton, needs tests"
     deferred:
       - "verify CORS — out of scope of feature X"
   ```

5. **Confirm to user.** Output: `Stashed for <wing>. Previous stash archived. /unstash to resume.`

## Component 2 — `vladyslav:unstash`

**Type:** Engineer (Sonnet)
**Trigger:** `/unstash` slash command, or natural-language "unstash", "продовжимо stash", "відкрий stash".

**Process:**

1. **Detect wing** (same logic as `stash`).

2. **Find active stash.** `mempalace_search` with `wing=<wing>, room_type=stash, active=true`. Expect 0 or 1 result.

3. **Handle empty case.** If no active stash → output: `No active stash for <wing>. Search archived? (y/n)`. If yes → list recent archived stashes for this wing with timestamps and let user pick.

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
1. Run `mempalace_search` with filters `wing=<current-wing>, room_type=stash, active=true`.
2. If a result exists, prefix the FIRST response in the session with:
   > ℹ Active stash: `<task>` (from `<created_at>`). `/unstash` to resume.
3. Then proceed with the user's actual request. Do NOT block, do NOT ask for confirmation. Pure information.

This runs once per session, not per message. If the user explicitly says "ignore stash" or "no memory", skip this check.
```

## Component 5 — MemPalace taxonomy update

Verify whether `room_type: stash` already exists by calling `mempalace_get_taxonomy`. If absent, add it (mechanism depends on MemPalace's taxonomy API — the plan must include the exact call). Document the schema:

```yaml
room_type: stash
purpose: Pause-and-resume snapshot of an active work session within a wing.
fields:
  active: bool          # exactly one active stash per wing at any time
  archived_at: iso8601? # null while active, timestamp once archived
  content:
    task: string                     # 1-2 sentence summary
    open_question: string            # current decision point or "no open question"
    done_in_session: string[]
    pending_files: { path, note }[]
    deferred: string[]
```

## Integration With Existing `vladyslav:*` Skills

**No changes to existing skills are needed.** This is by design:

- Component 4 (session-start notification) surfaces active stash before any skill runs, so all existing skills (`add-feature`, `write-user-stories`, `init-project`, etc.) inherit continuity for free.
- Component 3 (Scope Sentinel) lives in global `CLAUDE.md` and applies to every skill invocation globally.

If a future need arises (e.g. `add-feature` should refuse to start when an active stash exists for the same wing), it can be added later as an opt-in check inside that skill. For now, YAGNI.

## Out of Scope

- **No git auto-commit / auto-stash.** User retains full control of their git state. `pending_files` is a textual note only.
- **No multi-stash stack** (named stashes, `stash list`, `stash pop <id>`). One active per wing. Archived stashes are searchable via `mempalace_search` if needed but have no first-class UI.
- **No mid-session conversation replay.** `unstash` reconstructs context as a structured summary, not a verbatim transcript.
- **No changes to `superpowers:*` skills.** They remain untouched (per user constraint — "не буду апдейтіть чужий репозитарій"). Continuity for superpowers-driven specs is handled indirectly via session-start notification + manual `unstash`.
- **No automatic linking from stash → spec/plan files.** If a stash references a spec at `docs/plans/X-design.md`, the `pending_files` field handles that. No separate "linked spec" field.

## Open Questions

None at design time. All key decisions resolved in brainstorming (table above).

## Notes

- **Wing detection edge case:** The wings list in `~/.claude/CLAUDE.md` is hand-maintained. If the user adds a new project but forgets to update the wings list, `stash` will fall back to asking. The plan should include a note in the `stash` SKILL telling the user how to add a new wing to the global list when prompted.
- **MemPalace dependency:** This entire design depends on MemPalace being available in the session. If the MCP server is down, `stash` should fail loudly with `MemPalace unavailable — cannot stash. Try again when MCP is reachable.` rather than silently degrading to a local file (which would violate decision #2).
- **No translations until pre-release-check** (per repo working rule). Skill SKILL.md files written in English. User-facing strings (the notification, the `stash`/`unstash` confirmation messages) — in English for now; translation pass during pre-release-check if needed.
