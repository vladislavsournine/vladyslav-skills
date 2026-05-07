---
name: unstash
description: Use to resume a previously stashed task — reads the latest stash for the current wing from MemPalace and restores its open question, prior decisions, pending files, and deferred items into the conversation
---

# Unstash

## Overview

Restore a stashed conversation state into the current session. Reads the newest `stash` drawer for the current wing from MemPalace (Latest-wins), validates `pending_files` are still in the expected state on disk, and outputs a structured restoration so the user can continue exactly where they paused.

**Type:** Engineer (light)

**Semantics:** Latest-wins. No "active flag" — the drawer with the newest `created_at` (parsed from YAML content) is the active stash for the wing.

## When to use

- The user says `/unstash`, "unstash", "продовжимо stash", "відкрий stash", or equivalent.
- The session-start notification informed the user of a stash and the user wants to resume.

Do NOT use to "browse" stashes — there is no list/pop UI by design (one active per wing via Latest-wins). Older stashes can be searched manually via `mempalace_search` if needed.

## Process

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
