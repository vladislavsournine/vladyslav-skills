---
name: compact-save
description: Snapshot current task state to MemPalace before context compaction — called automatically via PreCompact hook or manually to preserve intra-session continuity
type: Engineer (light)
---

# Compact-Save

**Type:** Engineer (light)  
**Requires:** MemPalace MCP server

Snapshot the current conversation's task state to MemPalace so work context survives context compaction. Unlike the old stash/unstash pair, this is a minimal automated record — no manual resume step needed.

## When this runs

- **Automatically** — via `PreCompact` hook before Claude Code compacts the context window
- **Manually** — user says `/compact-save`, "save state", or "збережи стан"

## Steps

### Step 1: Detect wing

Derive wing from working directory basename (strip leading dots → lowercase → match wings list). If ambiguous, prompt the user.

### Step 2: Collect state from conversation context

- **`task`** — 1–2 sentences: what is the active task right now?
- **`files_modified`** — list of files edited or created this session (from recent tool calls)
- **`last_decision`** — the most recent key decision or finding (1 sentence)
- **`next`** — the immediate next action after restore

### Step 3: Save to MemPalace

Call `mempalace_add_drawer` with:

- `wing`: detected wing
- `room`: `"compact-save"`
- `name`: `"compact-save-<ISO timestamp>"`
- `content`: a single YAML string:

```yaml
task: "<task>"
files_modified:
  - <path>
last_decision: "<last_decision>"
next: "<next>"
created_at: "<ISO 8601 timestamp>"
```

If `files_modified` or any optional field is empty → include the key with an empty string or empty list. Do not omit keys.

### Step 4: Confirm

For **manual invocation**: output `Compact-save recorded for wing <wing>.`

For **automatic invocation** (PreCompact hook): execute silently — no user-facing output needed.

## Failure modes

- **MemPalace unreachable** → output a one-line warning and continue. Compact-save is insurance, never a blocker.
