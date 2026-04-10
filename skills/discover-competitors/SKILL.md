---
name: discover-competitors
description: Use to research competitors and fill section 6 of docs/product/start-project.md - invokes c-level-skills:competitive-intel, cross-references MemPalace lessons, and produces battlecards for the top 3 competitors
---

# Discover — Competitors

## Overview

Systematic competitor research for a new project. Can be invoked standalone or as part of `/vladyslav:discover`. Fills section 6 of `docs/product/start-project.md` with a comparison table and produces `docs/product/competitors.md` with battlecards for the top 3.

**Type:** Architect (Opus)

## Process

### Step 0: Verify model

Check current model. If not Opus: `/model opus`.

### Step 1: Read context

Read `docs/product/start-project.md`, focusing on sections 1 (ідея), 2 (проблема), 3 (audience), 7 (tech constraints).

**Hard stops:**
- File missing → tell user to run `/vladyslav:init-project` first
- Section 1 is empty or still `<...>` placeholder → stop, ask user to fill in the idea first

### Step 2: MemPalace search

1. Search current wing for `"competitors"`, `"competitive analysis"`, `"market research"`
2. Cross-wing search by category keywords from section 1 (e.g. for a tax app → search for "tax", "accounting")
3. Surface hits to the user — prior research may already exist

### Step 3: Invoke competitive-intel

Invoke `c-level-skills:competitive-intel` via the Skill tool with this input:

```
Analyze the competitive landscape for this product:
- Idea: <section 1 of start-project.md>
- Problem: <section 2>
- Audience: <section 3>
- Platform: <section 7 platform>

Produce:
1. Direct competitors (same problem, same audience)
2. Indirect competitors (same problem, different approach)
3. Substitutes (how the audience currently solves this without our category)
4. For top 3 direct competitors: model, strengths, weaknesses, our edge
5. Positioning map (2-axis, e.g. price vs sophistication)

Use WebSearch for current data. If unsure about a specific company, say "unknown, requires primary research" — do NOT hallucinate names, funding, or features.
```

### Step 4: Synthesize

From the `competitive-intel` output, produce:
- A markdown table for **section 6** of `start-project.md`: `Name | Model | Strength | Weakness | Our edge`
- `docs/product/competitors.md` with deeper battlecards for the top 3 (separate file — section 6 stays scannable)

If any field is `unknown, requires primary research`, write `TBD` in the table, not fabricated data.

### Step 5: Update files

1. Overwrite section 6 of `docs/product/start-project.md` with the new table. Preserve sections 1-5 and 7-12 **unchanged** — Blast Radius Rule.
2. Create or overwrite `docs/product/competitors.md` with the battlecards.

### Step 6: MemPalace record

Call `mempalace_check_duplicate` first. If not a duplicate, `mempalace_add_drawer`:

- **wing:** current project wing
- **room:** `decision`
- **content:**
  ```
  [WHAT] Competitive landscape: <top 3 names>
  [WHY] Discovery phase research for <project>
  [EDGE] <one-sentence differentiator>
  [FILES] docs/product/competitors.md, docs/product/start-project.md#6
  [DATE] <today>
  ```
- **added_by:** `discover-competitors`

### Step 7: Architect report

```
✓ Architect report — Discover Competitors
- Direct competitors identified: <count>
- Top 3 battlecards: <names>
- Our edge (one line): <text>
- Unknown fields (TBD): <count> — needs primary research
- Files updated:
  - docs/product/start-project.md (section 6)
  - docs/product/competitors.md (new or overwritten)
- MemPalace record added: wing <name>

━━━ Next ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Review docs/product/competitors.md — verify battlecards against reality.
Continue discovery: /vladyslav:discover-monetization
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Never fabricate specific competitor data. `TBD` is honest; a made-up competitor is a trap.
- Running this twice refreshes research but won't duplicate MemPalace records (`check_duplicate` guards it).
- This sub-skill is independently callable via `/vladyslav:discover-competitors`.
