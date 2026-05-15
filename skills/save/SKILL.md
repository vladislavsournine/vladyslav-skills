---
name: save
description: Save a knowledge record (decision, preference, milestone, or problem) to MemPalace for the current project wing. Use at end of session or any time after a key insight — no compaction needed.
type: Engineer (light)
---

# Save

**Type:** Engineer (light)
**Requires:** MemPalace MCP server

Save a knowledge record to MemPalace for the current project wing. Unlike `compact-save`, this is for capturing *semantic knowledge* (decisions, preferences, milestones, problems) — not task state before compaction.

## When this runs

- User says `/vladyslav:save`, "save to MemPalace", "remember this", "запам'ятай це", "збережи в MemPalace"
- Explicitly triggered at the end of a session when the user wants to persist a key insight without compacting

## Steps

### Step 1: Detect wing

Derive wing from working directory basename (strip leading dots → lowercase → match wings list in `~/.claude/CLAUDE.md`). If ambiguous or outside a known project, prompt the user to confirm or specify the wing.

### Step 2: Identify content and type

If the user provided the content to save in their message → use it directly.

If no content was provided → ask:

> "What should I save to MemPalace? Please describe it briefly, and tell me the type: **decision**, **preference**, **milestone**, or **problem**."

Classify the room type based on the content:
- **decision** — architectural or design choice with rationale ("we use X because Y")
- **preference** — how the user wants things done ("always do X", "never do Y")
- **milestone** — completed work worth remembering ("shipped feature X")
- **problem** — known issue, gotcha, or constraint ("Z breaks when W")

Default to `decision` if the type is unclear.

### Step 3: Check for duplicates

Call `mempalace_check_duplicate` with `wing` = detected wing and `query` = first 80 characters of content.

If a similar record exists → show it to the user and ask:
> "A similar record already exists: `<existing name>`. Update it, save a new one, or cancel?"

### Step 4: Save to MemPalace

Call `mempalace_add_drawer` with:

- `wing`: detected wing
- `room`: classified room type (`decision` / `preference` / `milestone` / `problem`)
- `name`: short kebab-case slug from the content (max 40 chars), e.g. `use-vitest-not-jest`
- `content`: a plain-text record including the date:

```
[WHAT] <one sentence summary>
[WHY] <rationale or context, if known>
[DATE] <today's date ISO 8601>
```

Omit `[WHY]` if no rationale was provided.

### Step 5: Confirm

Output one line: `Saved to MemPalace — wing:<wing>  room:<room>  "<name>"`

## Failure modes

- **MemPalace unreachable** → output a one-line warning and suggest the user save the note manually. Never block on this.
- **Wing undetectable** → prompt the user before saving. Never guess a wing silently.
