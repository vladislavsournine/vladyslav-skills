# Session Continuity (Stash/Unstash + Scope Sentinel) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `vladyslav:stash` / `vladyslav:unstash` skills + 2 global CLAUDE.md rules (Scope Sentinel + Active Stash Notification) so any conversation can be paused mid-flight and resumed in a future session.

**Architecture:** Two new Engineer (Sonnet) skills that read/write MemPalace drawers with `room_type=stash`, plus two global rules in `~/.claude/CLAUDE.md` that integrate stash into every session and into mid-execution scope changes. No changes to existing `vladyslav:*` skills — continuity propagates via the global rules.

**Tech Stack:** Markdown skill files, MemPalace MCP (`mempalace_search`, `mempalace_kg_add`, `mempalace_get_taxonomy`, `mempalace_list_wings`), git for `pending_files` detection.

**Spec:** `docs/plans/2026-04-16-stash-unstash-scope-sentinel-design.md`

---

## File Structure

| File | Responsibility |
|------|----------------|
| `commands/stash.md` | Thin slash command, model check + delegate to skill |
| `commands/unstash.md` | Thin slash command, model check + delegate to skill |
| `skills/stash/SKILL.md` | Detect wing → collect mental state → archive previous active → create new active drawer |
| `skills/unstash/SKILL.md` | Detect wing → find active drawer → freshness-validate `pending_files` → restore into conversation |
| `~/.claude/CLAUDE.md` | (manual user step) +2 sections: Scope Sentinel, Active Stash Notification |
| `.claude-plugin/plugin.json` | Version bump 1.6.0 → 1.7.0 |
| `README.md` | Document `/vladyslav:stash` and `/vladyslav:unstash` |
| `SkillsManual.md` | Add entries under "Engineer" section |
| `docs/architecture/system.md` | Brief mention of continuity primitive |

**Out of repo:** `~/.claude/CLAUDE.md` is the user's global config. Task 7 prepares the exact text and asks the user to apply it manually.

---

## Task 0: Pre-flight verification

**Files:** None (read-only checks).

**Goal:** Confirm MemPalace state matches what the design assumes before writing any code.

- [ ] **Step 1: Verify MemPalace MCP server is reachable**

Run: `mempalace_status` (via MCP tool).
Expected: Status response with active drawer count and reachable backend. If unreachable → STOP and ask user to bring MemPalace online.

- [ ] **Step 2: Check taxonomy for `room_type: stash`**

Run: `mempalace_get_taxonomy` (via MCP tool).
Look for `stash` in the returned room types list.
- If present → record this fact, no taxonomy change needed.
- If absent → record this fact. Task 3 (skills/stash/SKILL.md) must include creating the room type via the first `mempalace_kg_add` call (MemPalace creates room types on first use; if the API requires explicit registration, the skill must call the registration tool first).

- [ ] **Step 3: Confirm canonical wing for this repo**

Run: `basename $(pwd)` from `/Users/vlad/.vladyslav-skills/`.
Expected: `vladyslav-skills`. This matches the wings list in `~/.claude/CLAUDE.md` exactly — no new prefix needed.

- [ ] **Step 4: List existing stashes (sanity)**

Run via MCP: `mempalace_search` with query `room_type:stash` across all wings.
Expected: 0 results (this is the first stash implementation). Any pre-existing `stash` records would indicate a prior partial attempt — STOP and resolve before continuing.

---

## Task 1: Create `commands/stash.md`

**Files:**
- Create: `commands/stash.md`

- [ ] **Step 1: Write the command file**

Create `/Users/vlad/.vladyslav-skills/commands/stash.md` with EXACTLY this content:

```markdown
Before starting, check the current model. If it is not Sonnet, stop and tell the user: "Please run /model sonnet in your terminal and restart this command."
---
description: "Use to pause an in-progress task — captures current mental state (open question, work done, pending files, deferred items) into MemPalace so a future session can resume exactly where you stopped"
disable-model-invocation: true
---

Invoke the vladyslav:stash skill and follow it exactly as presented to you
```

- [ ] **Step 2: Verify file exists and parses**

Run:
```bash
test -f /Users/vlad/.vladyslav-skills/commands/stash.md && head -5 /Users/vlad/.vladyslav-skills/commands/stash.md
```
Expected: file exists, first line is the model-check sentence, frontmatter delimiters visible.

- [ ] **Step 3: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add commands/stash.md
git commit -m "feat(commands): add /stash command (delegator)"
```

---

## Task 2: Create `commands/unstash.md`

**Files:**
- Create: `commands/unstash.md`

- [ ] **Step 1: Write the command file**

Create `/Users/vlad/.vladyslav-skills/commands/unstash.md` with EXACTLY this content:

```markdown
Before starting, check the current model. If it is not Sonnet, stop and tell the user: "Please run /model sonnet in your terminal and restart this command."
---
description: "Use to resume a previously stashed task — reads the active stash for the current wing from MemPalace and restores its open question, prior decisions, pending files, and deferred items into the conversation"
disable-model-invocation: true
---

Invoke the vladyslav:unstash skill and follow it exactly as presented to you
```

- [ ] **Step 2: Verify file exists and parses**

Run:
```bash
test -f /Users/vlad/.vladyslav-skills/commands/unstash.md && head -5 /Users/vlad/.vladyslav-skills/commands/unstash.md
```
Expected: file exists, first line is the model-check sentence.

- [ ] **Step 3: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add commands/unstash.md
git commit -m "feat(commands): add /unstash command (delegator)"
```

---

## Task 3: Create `skills/stash/SKILL.md`

**Files:**
- Create: `skills/stash/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p /Users/vlad/.vladyslav-skills/skills/stash
```

- [ ] **Step 2: Write the SKILL.md**

Create `/Users/vlad/.vladyslav-skills/skills/stash/SKILL.md` with EXACTLY this content:

````markdown
---
name: stash
description: Use to pause an in-progress task — captures current mental state (open question, work done, pending files, deferred items) into MemPalace so a future session can resume exactly where you stopped
---

# Stash

## Overview

Snapshot the current conversation's mental state to MemPalace as a `stash` drawer for the active wing. Future sessions can restore this state via `/vladyslav:unstash`.

This is a continuity primitive — it captures the **point in the conversation**, not just the work done. If the user paused mid-question (e.g. you asked them to choose between A/B/C and they have not decided), the open question is preserved verbatim.

**Type:** Engineer (Sonnet)

## When to use

- The user says `/stash`, "stash this", "збережи стан", "зробити stash", or any equivalent.
- The user explicitly indicates they want to pause and resume later.
- Triggered by Scope Sentinel rule (case C — separate task) when the user picks "stash and switch".

Do NOT use when the user simply says "let's stop" without intending to resume — confirm intent first.

## Process

### Step 0: Verify model

Check current model. If not Sonnet, stop and ask user to switch: `/model sonnet`. Do not proceed.

### Step 1: Detect canonical wing

1. Run `basename $(pwd)` to get the directory name.
2. Lowercase, replace underscores/spaces/dots with hyphens.
3. If it doesn't start with a platform prefix (`swift-`, `python-`, `flutter-`, `kotlin-`, `web-`, `go-`), prepend the appropriate one based on detected stack (see `init-project` for detection logic).
4. Compare against the wings list in `~/.claude/CLAUDE.md`:
   - If the canonical name matches a wing → use it.
   - If no match → ask the user: *"Current directory `<basename>` does not map to any known wing. Pick one (autocomplete) or specify a new wing name:"* and use their answer.
5. Run `mempalace_list_wings`. If a near-duplicate wing exists with different casing → warn:
   > "Found existing wing `<wrong-case>` that looks like a stale duplicate. Using canonical `<correct-case>`."

### Step 2: Collect mental state from conversation

Build a structured snapshot from the active conversation. The five required fields:

1. **`task`** — 1–2 sentences. *"What are we working on?"* Example: `"Adding stash/unstash skills to vladyslav-skills repo. Currently writing implementation plan."`

2. **`open_question`** — the most important field. *"What is the current decision point or unresolved discussion?"* If you (the agent) just asked the user a multi-choice question and they did not answer → that question goes here verbatim with the choices. If no open question → use `"no open question"` literally.
   Example: `"Asked user to pick between (a) one stash per wing or (b) git-style stack. User did not answer."`

3. **`done_in_session`** — short ordered list of decisions made, code written, files touched. Each item one line.
   Example:
   ```
   - Decided: stash stores conversational state + pending files (no diffs)
   - Decided: persistence in MemPalace, no disk file
   - Wrote design doc at docs/plans/2026-04-16-stash-unstash-scope-sentinel-design.md
   ```

4. **`pending_files`** — list of files the agent modified or created in this session that are not yet committed. Detect via `git status --short` from the repo root. For each file, add a 1-line note from session memory describing **what the agent was doing in that file**.
   Example:
   ```
   - path: skills/stash/SKILL.md
     note: "Wrote Steps 0-3, Steps 4-5 still empty"
   ```
   If git is unavailable or the project is not a git repo → use only session memory and add a note `"git unavailable — list reconstructed from session memory only"`.

5. **`deferred`** — items the user explicitly deferred or that surfaced as "while I'm here" but were intentionally not done. Each item one line with the reason.
   Example:
   ```
   - "Refactor wing detection into shared helper — out of scope of this feature"
   ```

### Step 3: Archive previous active stash (if any)

1. Run `mempalace_search` with: query `room_type:stash active:true wing:<wing>`.
2. Inspect each result for active stashes for this wing (filter precisely — search may return loose matches).
3. For each found drawer:
   - Read its full content.
   - Update it via the appropriate MemPalace tool (try `mempalace_kg_add` with the same drawer id and merged content, or `mempalace_kg_invalidate` followed by re-creation under archived state — use whichever the MemPalace API supports for "update existing drawer"; if neither works, fall back to creating a new drawer with `active: false, archived_at: <iso8601>` and a `replaces: <old-drawer-id>` field, leaving the old one untouched but documented as superseded).
   - Set `active: false` and `archived_at: <current iso8601 timestamp>`.
4. Confirm internally: at most one drawer for this wing now has `active: true` (it should be zero before Step 4 creates the new one).

### Step 4: Create new active stash drawer

Call `mempalace_kg_add` with this exact drawer structure:

```yaml
wing: <canonical-wing-from-step-1>
room_type: stash
active: true
created_at: <current-iso8601-timestamp>
archived_at: null
content:
  task: "<from-step-2.1>"
  open_question: "<from-step-2.2>"
  done_in_session:
    - "<item 1>"
    - "<item 2>"
  pending_files:
    - path: "<repo-relative-path>"
      note: "<one-line-description>"
  deferred:
    - "<deferred item with reason>"
```

If `mempalace_kg_add` returns an error → STOP and report it to the user. Do not silently degrade to a local file (this would violate the design's MemPalace-only decision).

### Step 5: Confirm to user

Output verbatim (substituting `<wing>`):

```
Stashed for wing `<wing>`. Previous stash (if any) archived.

Resume with `/vladyslav:unstash` in any future session in this project.
```

Do not proceed with any further conversation actions — the user typically closes the session here.

## Failure modes

- **MemPalace unreachable** → STOP, output: `"MemPalace MCP unreachable. Cannot stash. Restore the connection and try again. Your session state is NOT saved."`
- **Wing detection ambiguous** → ask user (Step 1.4 fallback).
- **Multiple active stashes already exist for this wing** (corrupted state from a prior bug) → archive ALL of them in Step 3, then proceed.
- **`pending_files` empty AND `done_in_session` empty AND `open_question` is `"no open question"`** → ask user: *"There is nothing meaningful to stash (no open question, no work done, no pending files). Stash anyway?"* If yes → proceed; if no → abort gracefully.

## Integration

This skill is invoked:
- Manually via `/vladyslav:stash`
- Automatically by Scope Sentinel rule (`~/.claude/CLAUDE.md`) when the user picks "stash and switch" in case C

The companion skill `vladyslav:unstash` is the only consumer of stash drawers.
````

- [ ] **Step 3: Verify file structure**

Run:
```bash
test -f /Users/vlad/.vladyslav-skills/skills/stash/SKILL.md && head -10 /Users/vlad/.vladyslav-skills/skills/stash/SKILL.md
```
Expected: file exists, frontmatter visible with `name: stash` and a `description:` line.

- [ ] **Step 4: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add skills/stash/SKILL.md
git commit -m "feat(skills): add stash skill — captures conversation mental state to MemPalace"
```

---

## Task 4: Create `skills/unstash/SKILL.md`

**Files:**
- Create: `skills/unstash/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p /Users/vlad/.vladyslav-skills/skills/unstash
```

- [ ] **Step 2: Write the SKILL.md**

Create `/Users/vlad/.vladyslav-skills/skills/unstash/SKILL.md` with EXACTLY this content:

````markdown
---
name: unstash
description: Use to resume a previously stashed task — reads the active stash for the current wing from MemPalace and restores its open question, prior decisions, pending files, and deferred items into the conversation
---

# Unstash

## Overview

Restore a stashed conversation state into the current session. Reads the active `stash` drawer for the current wing from MemPalace, validates `pending_files` are still in the expected state on disk, and outputs a structured restoration so the user can continue exactly where they paused.

**Type:** Engineer (Sonnet)

## When to use

- The user says `/unstash`, "unstash", "продовжимо stash", "відкрий stash", or equivalent.
- The session-start notification informed the user of an active stash and the user wants to resume.

Do NOT use to "browse" stashes — there is no list/pop UI by design (one active stash per wing). Archived stashes can be searched manually via `mempalace_search` if needed.

## Process

### Step 0: Verify model

Check current model. If not Sonnet, stop and ask user to switch: `/model sonnet`. Do not proceed.

### Step 1: Detect canonical wing

Same logic as `vladyslav:stash` Step 1 (canonical name from `basename $(pwd)`, platform prefix, fallback to user prompt if no match in `~/.claude/CLAUDE.md` wings list).

### Step 2: Find active stash for this wing

1. Run `mempalace_search` with: query `room_type:stash active:true wing:<wing>`.
2. Filter results to drawers where `room_type=stash` AND `active=true` AND `wing=<wing>` exactly.
3. Branch:
   - **0 results** → output to user:
     > `No active stash for wing <wing>.`
     > `Search archived stashes? (y/n)`
     If user says yes → run `mempalace_search` with `room_type:stash wing:<wing>` (no active filter), list up to 10 most recent with `created_at` and `task` fields, ask user to pick one. If picked → continue from Step 3 with that drawer. If user says no → stop here.
   - **1 result** → use that drawer, continue.
   - **2+ results** (corrupted state) → warn user, list all with `created_at`, ask user to pick one. Do NOT auto-resolve.

### Step 3: Validate `pending_files` freshness

For each entry in the drawer's `pending_files` list:
1. Run `git status --short -- "<path>"` from the wing's repo root.
2. Check three states:
   - **File still has uncommitted changes** → mark as `[live]` in output.
   - **File is now clean** (no uncommitted changes) → mark as `[committed-since-stash]` — likely the user committed this work in a different session.
   - **File does not exist** → mark as `[missing]` — the file was deleted since the stash; user should be told this.
3. If git is unavailable → mark all as `[unverified — git unavailable]` and add a note in the output.

This implements the "before recommending from memory" rule from `~/.claude/CLAUDE.md`.

### Step 4: Restore into conversation

Output exactly this structure (substituting drawer fields):

```
Resuming stashed work for wing `<wing>`.

**Task:** <task>

**Where we stopped:** <open_question>

**Done previously in this thread:**
- <done_in_session item 1>
- <done_in_session item 2>
- ...

**Pending files (verify before resuming):**
- <pending_files[0].path> — <pending_files[0].note> [<freshness-flag>]
- <pending_files[1].path> — <pending_files[1].note> [<freshness-flag>]
- ...

**Deferred:**
- <deferred item 1>
- <deferred item 2>
- ...

**Stash created:** <created_at>

Ready to continue. What's next?
```

If a section's source list is empty, render it as `(none)` instead of an empty bullet list.

### Step 5: Wait for user input

Do NOT auto-act on the restored context. The user drives the next step (most often: answering the previously-open question, or saying "let's start with file X").

The active stash drawer remains `active: true` in MemPalace after unstash — it represents in-progress work. The user may stash again later (Task 3 archives the previous active drawer) or commit/finish the work (no-op for the stash drawer; it stays as a historical record of the resume point).

## Failure modes

- **MemPalace unreachable** → STOP, output: `"MemPalace MCP unreachable. Cannot read stash. Restore the connection and try again."`
- **Wing detection ambiguous** → ask user (same fallback as `stash`).
- **Drawer schema mismatch** (missing required fields) → output the raw drawer content with a warning: *"Stash drawer is missing expected fields. Showing raw content — interpret manually."* Do not invent values.

## Integration

Companion to `vladyslav:stash`. Can be invoked manually or after the session-start notification (defined in `~/.claude/CLAUDE.md`) prompts the user.
````

- [ ] **Step 3: Verify file structure**

Run:
```bash
test -f /Users/vlad/.vladyslav-skills/skills/unstash/SKILL.md && head -10 /Users/vlad/.vladyslav-skills/skills/unstash/SKILL.md
```
Expected: file exists, frontmatter with `name: unstash` and a `description:`.

- [ ] **Step 4: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add skills/unstash/SKILL.md
git commit -m "feat(skills): add unstash skill — restores stashed conversation from MemPalace"
```

---

## Task 5: Bump plugin version

**Files:**
- Modify: `.claude-plugin/plugin.json` (line 4)

- [ ] **Step 1: Update version**

Open `/Users/vlad/.vladyslav-skills/.claude-plugin/plugin.json`. Change line 4 from:
```json
  "version": "1.6.0",
```
To:
```json
  "version": "1.7.0",
```

- [ ] **Step 2: Verify**

Run:
```bash
grep '"version"' /Users/vlad/.vladyslav-skills/.claude-plugin/plugin.json
```
Expected output: `  "version": "1.7.0",`

- [ ] **Step 3: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add .claude-plugin/plugin.json
git commit -m "chore: bump version to 1.7.0 (stash/unstash skills)"
```

---

## Task 6: Update README, SkillsManual, and architecture doc

**Files:**
- Modify: `README.md`
- Modify: `SkillsManual.md`
- Modify: `docs/architecture/system.md`

- [ ] **Step 1: Read current README to find insertion point**

```bash
grep -n "vladyslav:" /Users/vlad/.vladyslav-skills/README.md | head -20
```
Expected: a list of skills somewhere in the README. Identify a logical place to add stash/unstash entries (e.g. after `seed-mempalace` or in a "Continuity" section).

- [ ] **Step 2: Edit README.md**

Add this section near the existing skills list (place it where it logically fits — likely under a new "Session Continuity" heading near `seed-mempalace`):

```markdown
### Session Continuity

- **`/vladyslav:stash`** — pause an in-progress task. Captures the current mental state (open question, decisions made, pending files, deferred items) to MemPalace as the active stash for the current wing.
- **`/vladyslav:unstash`** — resume a previously stashed task. Reads the active stash for the current wing and restores its open question, prior work, pending files, and deferred items into the conversation. Validates `pending_files` against git state before showing them.

One active stash per wing. Calling `stash` again archives the previous active stash (set `active: false`, add `archived_at`); archived stashes remain searchable via MemPalace.

Companion to two global rules in `~/.claude/CLAUDE.md`: **Scope Sentinel** (catches scope creep mid-execution) and **Active Stash Notification** (informs you at session start if a stash exists for this wing).
```

- [ ] **Step 3: Edit SkillsManual.md**

Add this entry under the "Engineer (Sonnet)" section (find via `grep -n "Engineer" SkillsManual.md`):

```markdown
### Session Continuity

- **`/vladyslav:stash`** — pause-and-resume primitive. Snapshots the current conversation's mental state (task summary, open question, decisions made, pending files, deferred items) into a MemPalace `stash` drawer for the active wing. Use when you need to close a session mid-flight or switch to a separate task without losing context. One active stash per wing — running `stash` again archives the previous active drawer.

- **`/vladyslav:unstash`** — restores the active stash for the current wing into the conversation. Validates `pending_files` against git state (live / committed-since-stash / missing) before showing them. Use at the start of a session to resume previously-stashed work.

These pair with two global rules in `~/.claude/CLAUDE.md`:
- **Scope Sentinel** — catches "let's also add X" mid-execution; classifies as (A) clarification (silent), (B) extension (asks before expanding plan), or (C) separate task (offers to stash + switch).
- **Active Stash Notification** — at session start, if a stash exists for the current wing, prepends an informational line to the first response: `ℹ Active stash: <task> (from <created_at>). /unstash to resume.` — does not block.
```

- [ ] **Step 4: Edit docs/architecture/system.md**

Add a brief mention near the end of the architecture doc (find a "Continuity" or "Memory" section, or add a new one):

```markdown
## Continuity Primitive

`vladyslav:stash` / `vladyslav:unstash` (added in 1.7.0) provide explicit pause-and-resume across sessions. Persistence is in MemPalace as drawers with `room_type=stash`, `active: bool`. Exactly one drawer per wing has `active: true` at any time; older actives are archived on each new stash. The skills are Engineer (Sonnet); the integration with all other skills happens through two global rules in `~/.claude/CLAUDE.md` (Scope Sentinel + Active Stash Notification) — no per-skill modifications were needed.
```

- [ ] **Step 5: Verify all three files updated**

Run:
```bash
grep -l "stash" /Users/vlad/.vladyslav-skills/README.md /Users/vlad/.vladyslav-skills/SkillsManual.md /Users/vlad/.vladyslav-skills/docs/architecture/system.md
```
Expected: all three paths printed.

- [ ] **Step 6: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add README.md SkillsManual.md docs/architecture/system.md
git commit -m "docs: document stash/unstash skills and continuity primitive"
```

---

## Task 7: Apply global CLAUDE.md rules (manual user step)

**Files:**
- Modify: `~/.claude/CLAUDE.md` (NOT in this repo — user's global config)

This task requires explicit user permission and is performed by the user (not the agent), because `~/.claude/CLAUDE.md` is the user's personal global configuration and should not be modified silently.

- [ ] **Step 1: Show the user the exact text to add**

Tell the user: *"Two new sections need to be appended to `~/.claude/CLAUDE.md`. Below is the exact text. Please review and apply when ready (or grant me permission to apply, and I will edit the file)."*

Then output the two sections verbatim:

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

## Active Stash Notification (Session Start)

At the start of any session inside a project that maps to a wing:
1. Run `mempalace_search` with filters `wing=<current-wing>, room_type=stash, active=true`.
2. If a result exists, prefix the FIRST response in the session with:
   > ℹ Active stash: `<task>` (from `<created_at>`). `/unstash` to resume.
3. Then proceed with the user's actual request. Do NOT block, do NOT ask for confirmation. Pure information.

This runs once per session, not per message. If the user explicitly says "ignore stash" or "no memory", skip this check.
```

- [ ] **Step 2: Wait for user**

The user must:
- Either edit `~/.claude/CLAUDE.md` themselves and append the two sections, then say "applied"
- OR grant explicit permission ("yes, you apply it"), in which case the agent uses the Edit tool to append the sections to `/Users/vlad/.claude/CLAUDE.md` (no commit — this file is not in this repo).

- [ ] **Step 3: Verify**

After application, run:
```bash
grep -c "Scope Sentinel" /Users/vlad/.claude/CLAUDE.md
grep -c "Active Stash Notification" /Users/vlad/.claude/CLAUDE.md
```
Expected: both return at least 1.

- [ ] **Step 4: No commit**

This file is outside the repo. Nothing to commit here. Move on.

---

## Task 8: Manual integration test

**Files:** None — this is end-to-end behavioral verification.

This task verifies that the skills, the rules, and MemPalace integrate correctly. It cannot be automated (no unit-test harness for Markdown skills); the user runs the scenarios and reports.

- [ ] **Step 1: Restart Claude Code session**

Tell the user to close the current Claude Code session and start a fresh one in `/Users/vlad/.vladyslav-skills/`. This ensures the new skills, commands, and CLAUDE.md rules are picked up.

- [ ] **Step 2: Test stash with a meaningful state**

In the new session, ask the user to:
1. Have a short conversation that establishes some state (e.g., "let's discuss adding feature X — give me 2-3 options").
2. Without picking an option, run `/stash`.
3. Verify the agent:
   - Correctly identifies wing `vladyslav-skills`
   - Captures the open question (the unanswered "pick an option" question)
   - Captures `done_in_session` (the conversation context)
   - Reports `Stashed for wing vladyslav-skills.`
4. Verify in MemPalace via `mempalace_search` that an `active: true` drawer with `room_type: stash, wing: vladyslav-skills` exists with the captured content.

Expected: PASS. If any field is missing or the wrong wing → STOP and fix Task 3 (skills/stash/SKILL.md).

- [ ] **Step 3: Test session-start notification**

Close the session. Open a new one in `/Users/vlad/.vladyslav-skills/`. Send any message (e.g., "list files").

Expected: the first response begins with `ℹ Active stash: <task> (from <created_at>). /unstash to resume.` followed by the actual response. If missing → STOP and verify Task 7 (CLAUDE.md edit) was applied correctly.

- [ ] **Step 4: Test unstash**

In the same session from Step 3, run `/unstash`.

Expected: the agent outputs the structured restoration block (Task / Where we stopped / Done previously / Pending files / Deferred), with the open question matching what was stashed in Step 2. If the structure is wrong → STOP and fix Task 4.

- [ ] **Step 5: Test stash overwrite (archive previous)**

In the same session, have a brief new conversation establishing different state, then run `/stash` again. Then run `mempalace_search` with `wing:vladyslav-skills room_type:stash` (no active filter).

Expected: 2 drawers — one with `active: true` (the new one), one with `active: false` and `archived_at: <timestamp>` (the previous one). If the previous is still active → STOP and fix Task 3, Step 3.

- [ ] **Step 6: Test Scope Sentinel (case C)**

Start `/vladyslav:add-feature` (or any other long-running skill). Mid-execution, say "by the way, fix the typo in README.md".

Expected: the agent stops, recognizes this is a separate task (case C), and asks: *"Stash current work and switch, or finish current first?"* If it silently switches or silently continues → STOP and fix Task 7 (CLAUDE.md edit was incomplete or rule wording is unclear).

- [ ] **Step 7: Document any deviations**

If all 6 scenarios pass → mark this task complete.
If any scenario produced unexpected behavior → write findings to `docs/plans/2026-04-16-stash-unstash-scope-sentinel-followups.md`, list each failing scenario with actual vs expected behavior, and decide whether to: (a) fix in this PR, or (b) defer to a follow-up plan. The user makes this call.

---

## Task 9: Final commit and push

**Files:** Push to `origin/main`.

- [ ] **Step 1: Verify clean working tree and check log**

Run:
```bash
cd /Users/vlad/.vladyslav-skills
git status
git log --oneline main ^origin/main
```
Expected: working tree clean, log shows commits from Tasks 1, 2, 3, 4, 5, 6 (six commits).

- [ ] **Step 2: Ask user before pushing**

This is a destructive-ish action (visible to others, hard to reverse). Ask: *"Six commits are ready to push to `origin/main`. Push now? (y/n)"*

- [ ] **Step 3: Push (only with user approval)**

```bash
cd /Users/vlad/.vladyslav-skills
git push origin main
```

- [ ] **Step 4: Tag the release**

```bash
cd /Users/vlad/.vladyslav-skills
git tag -a v1.7.0 -m "v1.7.0 — stash/unstash skills + continuity rules"
git push origin v1.7.0
```

- [ ] **Step 5: Verify remote**

Run:
```bash
git ls-remote --tags origin v1.7.0
```
Expected: tag exists on remote.

---

## Self-Review

**1. Spec coverage:** Each section of the design doc maps to a task:

| Spec Section | Task |
|--------------|------|
| Component 1 — `vladyslav:stash` | Task 1 (command) + Task 3 (skill) |
| Component 2 — `vladyslav:unstash` | Task 2 (command) + Task 4 (skill) |
| Component 3 — Scope Sentinel | Task 7 (manual CLAUDE.md edit) |
| Component 4 — Active Stash Notification | Task 7 (manual CLAUDE.md edit) |
| Component 5 — MemPalace taxonomy | Task 0 (verify) + Task 3 Step 4 (auto-create on first use) |
| Files Changed table | Tasks 1, 2, 3, 4, 5, 6, 7 |
| Resolved decision 1 (stash content) | Task 3, Step 2 (5 fields) |
| Resolved decision 2 (MemPalace only) | Task 3, Step 4 (no disk fallback) |
| Resolved decision 3 (Scope Sentinel iii) | Task 7 (rule text) |
| Resolved decision 4 (one active per wing) | Task 3, Step 3 (archive previous) |
| Resolved decision 5 (notification = info, no block) | Task 7 (rule text), Task 8 Step 3 (verify) |
| Resolved decision 6a (auto-archive) | Task 3, Step 3 |
| Resolved decision 6b (cwd → wing + fallback) | Task 3, Step 1; Task 4, Step 1 |
| Out of Scope items | Not implemented (correct) |
| Open Questions | None at design time (still none) |

No gaps.

**2. Placeholder scan:** Searched for "TBD", "TODO", "implement later", "fill in details", "appropriate", "handle edge cases" — none found in the plan text. The only "TODO"-like references are in the *content* of the skills (where they describe user-facing concepts like `deferred` items), not in the plan instructions themselves.

**3. Type consistency:**
- Field names in drawer schema (`task`, `open_question`, `done_in_session`, `pending_files`, `deferred`) match exactly across Task 3 (write) and Task 4 (read). ✓
- Wing detection logic identical in Task 3 Step 1 and Task 4 Step 1 (referenced by name to avoid drift). ✓
- Freshness flags in Task 4 Step 3 (`[live]`, `[committed-since-stash]`, `[missing]`, `[unverified]`) appear in Task 4 Step 4 output template. ✓
- Plugin version `1.7.0` consistent in Task 5 and Task 9. ✓

No issues found.
