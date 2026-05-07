---
name: stash
description: Use to pause an in-progress task — captures current mental state (open question, work done, pending files, deferred items) into MemPalace so a future session can resume exactly where you stopped
---

# Stash

## Overview

Snapshot the current conversation's mental state to MemPalace as a `stash` drawer for the active wing. Future sessions can restore this state via `/vladyslav:unstash`.

This is a continuity primitive — it captures the **point in the conversation**, not just the work done. If the user paused mid-question (e.g. you asked them to choose between A/B/C and they have not decided), the open question is preserved verbatim.

**Type:** Engineer (light)

**Semantics:** Latest-wins. MemPalace drawers are immutable; the newest stash drawer per wing IS the active one. Older stashes remain as history.

## When to use

- The user says `/stash`, "stash this", "збережи стан", "зробити stash", or any equivalent.
- The user explicitly indicates they want to pause and resume later.
- Triggered by Scope Sentinel rule (case C — separate task) when the user picks "stash and switch".
- Invoked internally by other `vladyslav:*` skills at defined auto-stash checkpoints (e.g. `vladyslav:add-feature`, `vladyslav:fix-bug`). In that case the caller passes `source: "<skill>:auto:<checkpoint>"`.

Do NOT use when the user simply says "let's stop" without intending to resume — confirm intent first.

## Process

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
