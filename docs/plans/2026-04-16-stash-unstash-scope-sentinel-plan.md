# Session Continuity (Stash/Unstash + Scope Sentinel) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `vladyslav:stash` / `vladyslav:unstash` skills + 2 global CLAUDE.md rules (Scope Sentinel + Active Stash Notification) so any conversation can be paused mid-flight and resumed in a future session. Also wire auto-stash checkpoints into `vladyslav:add-feature` and `vladyslav:fix-bug` so incomplete runs leave a recoverable stash even without a manual `/stash`.

**Architecture:** Two new Engineer (Sonnet) skills that write/read MemPalace drawers with `room="stash"`. Drawer content is YAML with `created_at` embedded inside — newest `created_at` per wing IS the active stash (Latest-wins; MemPalace drawer API is add-only). Two global rules in `~/.claude/CLAUDE.md` (Scope Sentinel + Active Stash Notification) integrate stash into every session. `add-feature` and `fix-bug` invoke `vladyslav:stash` at defined checkpoints with `source: "<skill>:auto:<checkpoint>"`.

**Tech Stack:** Markdown skill files, MemPalace MCP (`mempalace_add_drawer`, `mempalace_search`, `mempalace_get_taxonomy`, `mempalace_list_wings`, `mempalace_status`), git for `pending_files` detection.

**Spec:** `docs/plans/2026-04-16-stash-unstash-scope-sentinel-design.md`

---

## File Structure

| File | Responsibility |
|------|----------------|
| `commands/stash.md` | Thin slash command, model check + delegate to skill |
| `commands/unstash.md` | Thin slash command, model check + delegate to skill |
| `skills/stash/SKILL.md` | Detect wing → collect mental state → create new stash drawer (Latest-wins) |
| `skills/unstash/SKILL.md` | Detect wing → find newest stash drawer by `created_at` → freshness-validate `pending_files` → restore into conversation |
| `skills/add-feature/SKILL.md` | Add auto-stash calls at 4 checkpoints (contract-approved, plan-approved, subagent-task-complete:N, auto-gate-blocker) |
| `skills/fix-bug/SKILL.md` | Add auto-stash calls at 3 checkpoints (reproduction-written, fix-applied, regression-passed) |
| `~/.claude/CLAUDE.md` | (manual user step) +2 sections: Scope Sentinel, Active Stash Notification |
| `.claude-plugin/plugin.json` | Version bump 1.6.0 → 1.7.0 |
| `README.md` | Document `/vladyslav:stash` and `/vladyslav:unstash` + auto-stash mention |
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

- [ ] **Step 2: Check taxonomy**

Run: `mempalace_get_taxonomy` (via MCP tool).
Expected: taxonomy returned. `room` is free-form (no enum), so no registration step is needed. Record any existing `stash` drawer count for sanity.

- [ ] **Step 3: Confirm canonical wing for this repo**

Run: `basename $(pwd)` from `/Users/vlad/.vladyslav-skills/`.
Expected: `.vladyslav-skills`. Strip leading dot → `vladyslav-skills`. This matches the wings list in `~/.claude/CLAUDE.md` exactly.

- [ ] **Step 4: List existing stashes (sanity)**

Run via MCP: `mempalace_search` with `query="stash"`, `wing="vladyslav-skills"`, `limit=10`.
Expected: 0 results (this is the first stash implementation). Any pre-existing `room=stash` records would indicate a prior partial attempt — STOP and resolve before continuing.

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
description: "Use to resume a previously stashed task — reads the latest stash for the current wing from MemPalace and restores its open question, prior decisions, pending files, and deferred items into the conversation"
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

**Semantics:** Latest-wins. MemPalace drawers are immutable; the newest stash drawer per wing IS the active one. Older stashes remain as history.

## When to use

- The user says `/stash`, "stash this", "збережи стан", "зробити stash", or any equivalent.
- The user explicitly indicates they want to pause and resume later.
- Triggered by Scope Sentinel rule (case C — separate task) when the user picks "stash and switch".
- Invoked internally by other `vladyslav:*` skills at defined auto-stash checkpoints (e.g. `vladyslav:add-feature`, `vladyslav:fix-bug`). In that case the caller passes `source: "<skill>:auto:<checkpoint>"`.

Do NOT use when the user simply says "let's stop" without intending to resume — confirm intent first.

## Process

### Step 0: Verify model

Check current model. If not Sonnet, stop and ask user to switch: `/model sonnet`. Do not proceed.

### Step 1: Detect canonical wing

1. Run `basename $(pwd)` to get the directory name.
2. **Strip leading dots** (handles `.vladyslav-skills` → `vladyslav-skills`).
3. Lowercase, replace underscores/spaces/dots with hyphens.
4. If it does not start with a platform prefix (`swift-`, `python-`, `flutter-`, `kotlin-`, `web-`, `go-`), prepend the appropriate one based on detected stack (see `init-project` for detection logic).
5. Compare against the wings list in `~/.claude/CLAUDE.md`:
   - If the canonical name matches a wing → use it.
   - If no match → ask the user: *"Current directory `<basename>` does not map to any known wing. Pick one (autocomplete) or specify a new wing name:"* and use their answer.
6. Run `mempalace_list_wings`. If a near-duplicate wing exists with different casing → warn:
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

### Step 3: Determine source

- If invoked via `/vladyslav:stash` command or natural-language stash request → `source: "manual"`.
- If invoked by another skill with `source` metadata passed in → use that value (e.g., `"add-feature:auto:contract-approved"`, `"fix-bug:auto:fix-applied"`).

### Step 4: Create new stash drawer (Latest-wins)

Call `mempalace_add_drawer` with:

- `wing`: `<canonical-wing-from-step-1>`
- `room`: `"stash"`
- `added_by`: `"mcp"` (for manual) OR `"add-feature:auto"` / `"fix-bug:auto"` (when invoked by those skills)
- `content`: a single string with the EXACT YAML below (MemPalace stores the content verbatim; embedding `created_at` inside lets `unstash` sort by timestamp):

```yaml
created_at: <current-iso8601-with-timezone>
source: <value from Step 3>
task: "<from step 2.1>"
open_question: "<from step 2.2>"
done_in_session:
  - "<item 1>"
  - "<item 2>"
pending_files:
  - path: "<repo-relative-path>"
    note: "<one-line description>"
deferred:
  - "<deferred item with reason>"
```

If `pending_files` or `deferred` or `done_in_session` is empty → include the key with an empty list (`pending_files: []`), not omit it. This keeps `unstash` parsing uniform.

If `mempalace_add_drawer` returns an error → STOP and report it to the user with: `"MemPalace add_drawer failed: <reason>. Your session state is NOT saved."` Do not silently degrade to a local file.

**No explicit archive step.** Older stash drawers for this wing remain in MemPalace unchanged — they are implicitly archived by virtue of not being the newest.

### Step 5: Confirm to user

Output verbatim (substituting `<wing>`):

```
Stashed for wing `<wing>`. Older stashes remain as history.

Resume with `/vladyslav:unstash` in any future session in this project.
```

Do not proceed with any further conversation actions — for manual stash the user typically closes the session here. For auto-stash (invoked by another skill), return control to the caller.

## Failure modes

- **MemPalace unreachable** → STOP, output: `"MemPalace MCP unreachable. Cannot stash. Restore the connection and try again. Your session state is NOT saved."`
- **Wing detection ambiguous** → ask user (Step 1.5 fallback).
- **`pending_files` empty AND `done_in_session` empty AND `open_question` is `"no open question"`** → ask user: *"There is nothing meaningful to stash (no open question, no work done, no pending files). Stash anyway?"* If yes → proceed; if no → abort gracefully. (This check only applies for manual stash; auto-stash always proceeds because a checkpoint is itself meaningful state.)

## Integration

This skill is invoked:
- Manually via `/vladyslav:stash`
- Automatically by Scope Sentinel rule (`~/.claude/CLAUDE.md`) when the user picks "stash and switch" in case C
- Automatically by `vladyslav:add-feature` and `vladyslav:fix-bug` at defined checkpoints (see those skills' SKILL.md)

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
description: Use to resume a previously stashed task — reads the latest stash for the current wing from MemPalace and restores its open question, prior decisions, pending files, and deferred items into the conversation
---

# Unstash

## Overview

Restore a stashed conversation state into the current session. Reads the newest `stash` drawer for the current wing from MemPalace (Latest-wins), validates `pending_files` are still in the expected state on disk, and outputs a structured restoration so the user can continue exactly where they paused.

**Type:** Engineer (Sonnet)

**Semantics:** Latest-wins. No "active flag" — the drawer with the newest `created_at` (parsed from YAML content) is the active stash for the wing.

## When to use

- The user says `/unstash`, "unstash", "продовжимо stash", "відкрий stash", or equivalent.
- The session-start notification informed the user of a stash and the user wants to resume.

Do NOT use to "browse" stashes — there is no list/pop UI by design (one active per wing via Latest-wins). Older stashes can be searched manually via `mempalace_search` if needed.

## Process

### Step 0: Verify model

Check current model. If not Sonnet, stop and ask user to switch: `/model sonnet`. Do not proceed.

### Step 1: Detect canonical wing

Same logic as `vladyslav:stash` Step 1 (basename → strip leading dots → lowercase → platform prefix → match wings list; fallback to user prompt).

### Step 2: Find latest stash for this wing (Latest-wins)

1. Run `mempalace_search` with: `wing=<wing>`, `room="stash"`, `query="stash created_at"`, `limit=20`.
2. For each returned drawer:
   - Parse its `content` string as YAML.
   - Extract the top-level `created_at` field.
3. Select the drawer with the **newest `created_at`** (compare as ISO-8601 strings).
4. Branch:
   - **0 results** → output:
     > `No stash for wing <wing>.`
     > `Search other wings for stashes? (y/n)`
     If user says yes → run `mempalace_search` with `room="stash"` across all wings, list up to 10 most recent with `wing`, `created_at`, `task` fields; ask user to pick one. If picked → continue from Step 3 with that drawer. If user says no → stop here.
   - **1+ results** → use the newest drawer, continue.

### Step 3: Validate `pending_files` freshness

For each entry in the drawer's `pending_files` list:
1. Run `git status --short -- "<path>"` from the wing's repo root.
2. Check three states:
   - **File still has uncommitted changes** → mark as `[live]`.
   - **File is now clean** (no uncommitted changes) → mark as `[committed-since-stash]`.
   - **File does not exist** → mark as `[missing]`.
3. If git is unavailable → mark all as `[unverified — git unavailable]` and add a note in the output.

This implements the "before recommending from memory" rule from `~/.claude/CLAUDE.md`.

### Step 4: Restore into conversation

Output exactly this structure (substituting drawer fields). If `source` starts with `add-feature:auto:` or `fix-bug:auto:`, prefix the output with `*(auto-checkpoint from <skill> at <checkpoint-name>)*` on its own line before the body:

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

**Stash created:** <created_at> (source: <source>)

Ready to continue. What's next?
```

If a section's source list is empty, render it as `(none)` instead of an empty bullet list.

### Step 5: Wait for user input

Do NOT auto-act on the restored context. The user drives the next step (most often: answering the previously-open question, or saying "let's start with file X").

The stash drawer is NOT modified or deleted after unstash — Latest-wins semantics mean the drawer remains the current active stash until a new `/stash` creates a newer one.

## Failure modes

- **MemPalace unreachable** → STOP, output: `"MemPalace MCP unreachable. Cannot read stash. Restore the connection and try again."`
- **Wing detection ambiguous** → ask user (same fallback as `stash`).
- **Drawer content not valid YAML** (missing `created_at` or corrupt) → skip that drawer for Latest-wins comparison; if all drawers are corrupt → output the raw content of the most recent result with a warning: *"Stash drawer content is not parseable YAML. Showing raw content — interpret manually."* Do not invent values.
- **Drawer schema mismatch** (valid YAML but missing required fields like `task`) → show whatever fields are present and flag the missing ones explicitly.

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
git commit -m "chore: bump version to 1.7.0 (stash/unstash skills + auto-stash)"
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
Expected: a list of skills somewhere in the README. Identify a logical place to add stash/unstash entries (e.g. after `seed-mempalace` or in a new "Session Continuity" section).

- [ ] **Step 2: Edit README.md**

Add this section near the existing skills list (place it where it logically fits — likely under a new "Session Continuity" heading near `seed-mempalace`):

```markdown
### Session Continuity

- **`/vladyslav:stash`** — pause an in-progress task. Captures the current mental state (open question, decisions made, pending files, deferred items) to MemPalace as a `stash` drawer for the current wing.
- **`/vladyslav:unstash`** — resume a previously stashed task. Reads the latest stash (Latest-wins by `created_at`) for the current wing and restores its open question, prior work, pending files, and deferred items into the conversation. Validates `pending_files` against git state before showing them.

One active stash per wing via Latest-wins semantics — the newest `stash` drawer for a wing IS the active one. Older drawers remain as history (MemPalace drawer API is add-only). `vladyslav:add-feature` and `vladyslav:fix-bug` invoke `stash` automatically at defined checkpoints so incomplete runs are recoverable.

Companion to two global rules in `~/.claude/CLAUDE.md`: **Scope Sentinel** (catches scope creep mid-execution) and **Active Stash Notification** (informs you at session start if a stash exists for this wing).
```

- [ ] **Step 3: Edit SkillsManual.md**

Add this entry under the "Engineer (Sonnet)" section (find via `grep -n "Engineer" SkillsManual.md`):

```markdown
### Session Continuity

- **`/vladyslav:stash`** — pause-and-resume primitive. Snapshots the current conversation's mental state (task summary, open question, decisions made, pending files, deferred items) into a MemPalace `stash` drawer for the active wing. Use when you need to close a session mid-flight or switch to a separate task without losing context. Latest-wins: the newest drawer IS the active stash; older drawers remain as history.

- **`/vladyslav:unstash`** — restores the latest stash for the current wing into the conversation. Validates `pending_files` against git state (live / committed-since-stash / missing) before showing them. Use at the start of a session to resume previously-stashed work.

These pair with two global rules in `~/.claude/CLAUDE.md`:
- **Scope Sentinel** — catches "let's also add X" mid-execution; classifies as (A) clarification (silent), (B) extension (asks before expanding plan), or (C) separate task (offers to stash + switch).
- **Active Stash Notification** — at session start, if a stash exists for the current wing, prepends an informational line to the first response: `ℹ Latest stash: <task> (from <created_at>, source <source>). /unstash to resume.` — does not block.

`vladyslav:add-feature` and `vladyslav:fix-bug` invoke `vladyslav:stash` automatically at defined checkpoints (contract approval, plan approval, each subagent task complete, etc.) so incomplete runs still leave a recoverable stash.
```

- [ ] **Step 4: Edit docs/architecture/system.md**

Add a brief mention near the end of the architecture doc (find a "Continuity" or "Memory" section, or add a new one):

```markdown
## Continuity Primitive

`vladyslav:stash` / `vladyslav:unstash` (added in 1.7.0) provide explicit pause-and-resume across sessions. Persistence is in MemPalace as drawers with `room="stash"`; drawer `content` is YAML with an embedded `created_at`. Semantics are Latest-wins: the newest drawer per wing IS the active stash (drawer API is add-only — immutability drove this choice over a mutable `active` flag). Integration with other skills happens via two global rules in `~/.claude/CLAUDE.md` (Scope Sentinel + Active Stash Notification) and via auto-stash checkpoints inside `vladyslav:add-feature` and `vladyslav:fix-bug`.
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

## Task 6.5: Auto-stash integration in `vladyslav:add-feature`

**Files:**
- Modify: `skills/add-feature/SKILL.md`

**Goal:** Add auto-stash invocations at 4 checkpoints so that a paused or interrupted `add-feature` run leaves a recoverable stash.

- [ ] **Step 1: Read the existing add-feature skill**

```bash
wc -l /Users/vlad/.vladyslav-skills/skills/add-feature/SKILL.md
cat /Users/vlad/.vladyslav-skills/skills/add-feature/SKILL.md | head -80
```
Identify the section names corresponding to each checkpoint from the design:
- `contract-approved` — immediately after the step where the user approves the contract
- `plan-approved` — immediately after the step where the user approves the implementation plan
- `subagent-task-complete:N` — inside the subagent loop, after each task marked complete
- `auto-gate-blocker` — when the auto-gate (tests/review/security) reports a blocker

Record the exact line numbers where the auto-stash snippets must be inserted.

- [ ] **Step 2: Insert the auto-stash snippet after each checkpoint**

For each of the 4 locations identified in Step 1, insert this block immediately after the checkpoint is reached:

````markdown
#### Auto-stash checkpoint: `<checkpoint-name>`

Invoke the `vladyslav:stash` skill with the following metadata (best-effort; do NOT abort the parent flow on failure):

- `source`: `"add-feature:auto:<checkpoint-name>"`
- `task`: short one-liner of the feature being added
- `open_question`: `<checkpoint-specific open question — see table below>`
- `done_in_session`: last 3-5 significant events from this skill's internal step log
- `pending_files`: `git status --short` at this point
- `deferred`: items the user deferred so far in this run (if any)

If `mempalace_add_drawer` fails → print a warning inline: *"Auto-stash failed: `<reason>`. Continuing — run `/stash` manually if you want a guaranteed snapshot."* and continue the parent skill. Auto-stash is best-effort insurance; it MUST NOT break the primary workflow.

Checkpoint → `open_question` mapping:

| Checkpoint | `open_question` value |
|------------|------------------------|
| `contract-approved` | `"Contract approved — awaiting plan writing"` |
| `plan-approved` | `"Plan approved — awaiting execution start"` |
| `subagent-task-complete:N` | `"Subagent task <N> complete — awaiting task <N+1>"` (substitute the concrete N) |
| `auto-gate-blocker` | `"Auto-gate blocked on: <reason>"` |
````

Only insert the `open_question` line relevant to the local checkpoint — the full table is for reference; you do not need to repeat it in every insertion.

- [ ] **Step 3: Verify all 4 checkpoints are instrumented**

Run:
```bash
grep -n "Auto-stash checkpoint:" /Users/vlad/.vladyslav-skills/skills/add-feature/SKILL.md
```
Expected: 4 matches, one per checkpoint.

- [ ] **Step 4: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add skills/add-feature/SKILL.md
git commit -m "feat(add-feature): auto-stash at 4 checkpoints (contract, plan, per-subagent-task, auto-gate)"
```

---

## Task 6.6: Auto-stash integration in `vladyslav:fix-bug`

**Files:**
- Modify: `skills/fix-bug/SKILL.md`

**Goal:** Add auto-stash invocations at 3 checkpoints in the fix-bug workflow.

- [ ] **Step 1: Read the existing fix-bug skill**

```bash
wc -l /Users/vlad/.vladyslav-skills/skills/fix-bug/SKILL.md
cat /Users/vlad/.vladyslav-skills/skills/fix-bug/SKILL.md | head -80
```
Identify the section names corresponding to each checkpoint from the design:
- `reproduction-written` — immediately after the failing test reproducing the bug is committed
- `fix-applied` — immediately after the fix is committed and the test passes
- `regression-passed` — after the full test suite passes post-fix

Record the exact line numbers.

- [ ] **Step 2: Insert the auto-stash snippet after each checkpoint**

For each of the 3 locations, insert this block (mirrors Task 6.5's block, with fix-bug specifics):

````markdown
#### Auto-stash checkpoint: `<checkpoint-name>`

Invoke the `vladyslav:stash` skill with the following metadata (best-effort; do NOT abort the parent flow on failure):

- `source`: `"fix-bug:auto:<checkpoint-name>"`
- `task`: short one-liner of the bug being fixed
- `open_question`: `<checkpoint-specific open question — see table below>`
- `done_in_session`: last 3-5 significant events from this skill's internal step log
- `pending_files`: `git status --short` at this point
- `deferred`: items the user deferred so far in this run (if any)

If `mempalace_add_drawer` fails → print a warning inline and continue. Auto-stash is best-effort insurance.

Checkpoint → `open_question` mapping:

| Checkpoint | `open_question` value |
|------------|------------------------|
| `reproduction-written` | `"Reproduction test committed — awaiting fix"` |
| `fix-applied` | `"Fix applied and test passing — awaiting regression verification"` |
| `regression-passed` | `"Regression clean — ready to merge"` |
````

- [ ] **Step 3: Verify all 3 checkpoints are instrumented**

Run:
```bash
grep -n "Auto-stash checkpoint:" /Users/vlad/.vladyslav-skills/skills/fix-bug/SKILL.md
```
Expected: 3 matches.

- [ ] **Step 4: Commit**

```bash
cd /Users/vlad/.vladyslav-skills
git add skills/fix-bug/SKILL.md
git commit -m "feat(fix-bug): auto-stash at 3 checkpoints (reproduction, fix, regression)"
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
1. Run `mempalace_search` with `wing=<current-wing>, room="stash"`, query="stash created_at", limit=5. Parse each returned drawer's YAML `content` and extract `created_at`.
2. If at least one result exists, take the drawer with the **newest `created_at`** — this is the latest stash. Prefix the FIRST response in the session with:
   > ℹ Latest stash: `<task>` (from `<created_at>`, source `<source>`). `/unstash` to resume.
3. Then proceed with the user's actual request. Do NOT block, do NOT ask for confirmation. Pure information. Do NOT fetch or display older stashes.

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
   - Correctly identifies wing `vladyslav-skills` (strip-leading-dot rule fires)
   - Captures the open question (the unanswered "pick an option" question)
   - Captures `done_in_session` (the conversation context)
   - Reports `Stashed for wing vladyslav-skills.`
4. Verify in MemPalace via `mempalace_search` (`wing="vladyslav-skills"`, `room="stash"`) that a drawer exists with the captured YAML content and a `created_at` matching the stash time.

Expected: PASS. If any field is missing or the wrong wing → STOP and fix Task 3.

- [ ] **Step 3: Test session-start notification**

Close the session. Open a new one in `/Users/vlad/.vladyslav-skills/`. Send any message (e.g., "list files").

Expected: the first response begins with `ℹ Latest stash: <task> (from <created_at>, source manual). /unstash to resume.` followed by the actual response. If missing → STOP and verify Task 7 (CLAUDE.md edit) was applied correctly.

- [ ] **Step 4: Test unstash**

In the same session from Step 3, run `/unstash`.

Expected: the agent outputs the structured restoration block (Task / Where we stopped / Done previously / Pending files / Deferred / Stash created), with the open question matching what was stashed in Step 2. If the structure is wrong → STOP and fix Task 4.

- [ ] **Step 5: Test stash overwrite (Latest-wins)**

In the same session, have a brief new conversation establishing different state, then run `/stash` again. Then run `mempalace_search` with `wing="vladyslav-skills"`, `room="stash"`, `limit=10`.

Expected: 2+ drawers. The one with the newer `created_at` matches the latest `/stash`; the older one is untouched (MemPalace is immutable — no `archived_at` mutation needed). Run `/unstash` — it must restore the newer one.

If `/unstash` restores the older one → STOP and fix Task 4 Step 2 (Latest-wins sort).

- [ ] **Step 6: Test Scope Sentinel (case C)**

Start `/vladyslav:add-feature` (or any other long-running skill). Mid-execution, say "by the way, fix the typo in README.md".

Expected: the agent stops, recognizes this is a separate task (case C), and asks: *"Stash current work and switch, or finish current first?"* If it silently switches or silently continues → STOP and fix Task 7 (CLAUDE.md edit was incomplete or rule wording is unclear).

- [ ] **Step 7: Test auto-stash in `add-feature`**

Start `/vladyslav:add-feature` for a trivial feature. Let the skill reach the `contract-approved` checkpoint (answer "yes" to the contract). Before the plan is written, close the session abruptly (do not finish the flow).

Open a fresh session in `/Users/vlad/.vladyslav-skills/`. Verify:
1. Session-start notification says: `ℹ Latest stash: <task> (from <created_at>, source add-feature:auto:contract-approved). /unstash to resume.`
2. Run `/unstash` — the restoration block says `source: add-feature:auto:contract-approved` and `open_question: "Contract approved — awaiting plan writing"`.

If notification missing OR source is not `add-feature:auto:contract-approved` → STOP and fix Task 6.5.

- [ ] **Step 8: Test auto-stash in `fix-bug`**

Same pattern: run `/vladyslav:fix-bug`, let it commit the reproduction test (`reproduction-written` checkpoint), close session, verify auto-stash drawer exists with the correct `source` and `open_question`.

- [ ] **Step 9: Document any deviations**

If all 8 scenarios pass → mark this task complete.
If any scenario produced unexpected behavior → write findings to `docs/plans/2026-04-16-stash-unstash-scope-sentinel-followups.md`, list each failing scenario with actual vs expected behavior, and decide whether to: (a) fix in this PR, or (b) defer to a follow-up plan. The user makes this call.

---

## Task 9: Final commit and push

**Files:** Push to `origin/main` (or feature branch, depending on user's branch strategy).

- [ ] **Step 1: Verify clean working tree and check log**

Run:
```bash
cd /Users/vlad/.vladyslav-skills
git status
git log --oneline
```
Expected: working tree clean; log shows the 8 feature commits from Tasks 1, 2, 3, 4, 5, 6, 6.5, 6.6.

- [ ] **Step 2: Ask user before pushing**

This is a destructive-ish action (visible to others, hard to reverse). Ask: *"All commits are ready to push. Push to `origin/<branch>` now? (y/n)"*

- [ ] **Step 3: Push (only with user approval)**

```bash
cd /Users/vlad/.vladyslav-skills
git push -u origin <current-branch>
```

- [ ] **Step 4: Tag the release (only after merging to main)**

If the user has merged the branch to main:
```bash
cd /Users/vlad/.vladyslav-skills
git checkout main
git pull
git tag -a v1.7.0 -m "v1.7.0 — stash/unstash skills + continuity rules + auto-stash checkpoints"
git push origin v1.7.0
```

If still on a feature branch → defer tagging until after merge.

- [ ] **Step 5: Verify remote**

Run:
```bash
git ls-remote --tags origin v1.7.0
```
Expected: tag exists on remote (after Step 4).

---

## Self-Review

**1. Spec coverage:** Each section of the design doc maps to a task:

| Spec Section | Task |
|--------------|------|
| Component 1 — `vladyslav:stash` | Task 1 (command) + Task 3 (skill) |
| Component 2 — `vladyslav:unstash` | Task 2 (command) + Task 4 (skill) |
| Component 3 — Scope Sentinel | Task 7 (manual CLAUDE.md edit) |
| Component 4 — Active Stash Notification | Task 7 (manual CLAUDE.md edit) |
| Component 5 — MemPalace room convention | Task 0 (verify) + Task 3 Step 4 (`room="stash"` auto-registers) |
| Component 6 — Auto-stash integration | Task 6.5 (add-feature) + Task 6.6 (fix-bug) |
| Files Changed table | Tasks 1, 2, 3, 4, 5, 6, 6.5, 6.6, 7 |
| Resolved decision 1 (stash content) | Task 3, Step 2 (5 fields) |
| Resolved decision 2 (MemPalace only) | Task 3, Step 4 (no disk fallback) |
| Resolved decision 3 (Scope Sentinel iii) | Task 7 (rule text) |
| Resolved decision 4 (one active per wing) | Task 3, Step 4 (Latest-wins, no archive step) |
| Resolved decision 5 (notification = info, no block) | Task 7 (rule text), Task 8 Step 3 (verify) |
| Resolved decision 6a (Latest-wins) | Task 3 Step 4 (no archive), Task 4 Step 2 (newest `created_at`) |
| Resolved decision 6b (cwd → wing + strip leading dot + fallback) | Task 3, Step 1; Task 4, Step 1 |
| Resolved decision 7 (auto-stash in long-running skills) | Task 6.5, Task 6.6 |
| Out of Scope items | Not implemented (correct) |
| Open Questions | None at design time (still none) |

No gaps.

**2. Placeholder scan:** Searched for "TBD", "TODO", "implement later", "fill in details", "appropriate", "handle edge cases" — none found in the plan text. The only "TODO"-like references are in the *content* of the skills (where they describe user-facing concepts like `deferred` items), not in the plan instructions themselves.

**3. Type consistency:**
- Field names in drawer YAML (`created_at`, `source`, `task`, `open_question`, `done_in_session`, `pending_files`, `deferred`) match exactly across Task 3 (write), Task 4 (read), Task 6.5 and Task 6.6 (auto-stash metadata), and Task 7 (notification parsing). ✓
- Wing detection logic (basename → strip leading dots → lowercase → platform prefix) identical in Task 3 Step 1 and referenced by name in Task 4 Step 1. ✓
- Freshness flags in Task 4 Step 3 (`[live]`, `[committed-since-stash]`, `[missing]`, `[unverified]`) appear in Task 4 Step 4 output template. ✓
- Plugin version `1.7.0` consistent in Task 5 and Task 9. ✓
- `source` values consistent: `"manual"` (Task 3), `"add-feature:auto:<checkpoint>"` (Task 6.5), `"fix-bug:auto:<checkpoint>"` (Task 6.6), recognized by Task 4 for output prefixing and by Task 7 for notification display. ✓
- Latest-wins invariant: Task 3 Step 4 (no archive), Task 4 Step 2 (parse YAML → newest `created_at`), Task 7 Active Stash Notification (same Latest-wins parse), Task 8 Step 5 (behavioral verification). ✓

No issues found.
