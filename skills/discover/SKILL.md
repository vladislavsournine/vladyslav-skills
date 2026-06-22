---
name: discover
description: Use after init-project to fill docs/product/start-project.md with AI research on competitors, monetization, valuation, and marketing.
---

# Discover — Product Discovery

## Overview

Fills sections 6, 8, 9, 10 (and 11 for iOS) of `docs/product/start-project.md` using AI-research and `c-level-skills:*` advisory skills. Runs sequentially so each section builds on the previous one — monetization references competitor pricing, valuation references unit economics, marketing references SOM constraints.

> **Orchestration:** the section chain (Steps 4→5→6→7) is a genuine dependency pipeline — do **not** fan it out, the cross-references would break (`_shared/references/orchestration-conventions.md` → "NOT safe to parallelize"). The only safe parallelism here is the read-only MemPalace search batch in Step 2. Research stays on the `c-level-skills` (they pick their own model).

**Type:** Architect

## When to use

- After `/vladyslav:init-project` — once sections 1-5 of `docs/product/start-project.md` are filled in manually
- Mid-project pivot — when the business model or target audience changes
- Before fundraising — for a consolidated discovery bundle

## Prerequisites

- `docs/product/start-project.md` exists with sections 1-5 filled (ідея, проблема, audience, MVP scope, non-goals)
- At least section 1 must be non-empty — empty StartProject is a hard stop

## Process

### Step 1: Read context

Read:
- `CLAUDE.md` — project-level rules (derive project name from the `# <name>` title; fall back to the current directory basename)
- `docs/product/prd.md` (if exists)
- `docs/product/start-project.md` — full file, primary input for all sections

**If `docs/product/start-project.md` is missing — self-seed it:**

1. Resolve the plugin root: Glob `~/.claude/plugins/cache/vladyslav-marketplace/vladyslav/*/skills/discover/SKILL.md` and take the directory two levels up. If Glob returns nothing, fall back to `/Volumes/DevSSD/Development/vladyslav-skills`.
2. Read `<plugin-root>/skills/init-project/assets/StartProject.md`.
   - If that template is also missing → stop with: *"Template `skills/init-project/assets/StartProject.md` not found in the vladyslav-skills plugin. Please reinstall or run `git pull`."*
3. Replace every occurrence of `<PROJECT_NAME>` in the template with the project name derived from CLAUDE.md (or directory basename).
4. Create `docs/product/` if it does not exist, then write the substituted content to `docs/product/start-project.md`.
5. Inform the user: *"Created `docs/product/start-project.md` from template. Sections 1–5 still contain placeholder text — please fill in your idea, problem statement, audience, MVP scope, and non-goals before the research sections are filled."*
6. Continue with Step 2 below (do not stop — proceed into MemPalace search and section detection).

**Hard stop (applies whether file existed or was just created):**
- Sections 1-5 still contain `<...>` placeholders → stop, ask user to fill the foundation first

### Step 2: MemPalace — batch search

Apply the verify-working-directory contract from `<plugin>/skills/_shared/references/verify-pwd.md`: confirms CLAUDE.md exists, derives the canonical MemPalace wing name, warns on stale-wing duplicates, and establishes the mandatory path-validation rule for the rest of this skill's MemPalace reads.

Run all searches upfront as **parallel reads** (independent, no shared state — dispatch in one batch):

```
mempalace_search wing=<wing> "competitors"
mempalace_search wing=<wing> "monetization pricing"
mempalace_search wing=<wing> "idea validation PMF"
mempalace_search wing=<wing> "marketing channels"
```

Cross-wing search by category keywords from section 1 (e.g. for a tax app → "tax accounting").

Surface hits — prior research for any dimension shouldn't be re-done.

### Step 3: Detect scope

Use `<plugin>/scripts/section-status.sh docs/product/start-project.md` to get `{filled: [...], pending: [...]}` as JSON. The "skip done" mode auto-skips any section listed in `filled`.

Ask the user which sections to fill:

- **All** (default) — runs Steps 4 → 5 → 6 → 7 in order
- **Custom** — user picks specific steps
- **Skip done** — auto-detect which sections are already filled (non-empty, no `<...>` markers) and skip those

**iOS auto-detection:** run `<plugin>/scripts/detect-stack.sh .` and check `.ios == true` in the JSON output. If true → schedule Step 8 (Apple Check) after Step 7.

---

> **Per-section flow:** Steps 4-7 below all follow the same shape — invoke c-level-skill(s), synthesize, overwrite the target section of `start-project.md`, write a MemPalace `decision` record. The shared flow plus per-step prompts, synthesis formats, and MemPalace templates live in `<plugin>/skills/discover/references/discover-section.md`. For each step below, read that reference's matching block and apply it.

### Step 4: Competitive landscape → section 6

Apply the per-section flow from `<plugin>/skills/discover/references/discover-section.md` → "Step 4 — Competitive landscape (section 6)". Inputs: `start-project.md` sections 1, 2, 3, 7. Output: section 6 of `start-project.md` plus `docs/product/competitors.md`.

---

### Step 5: Monetization → section 8

Apply the per-section flow from `<plugin>/skills/discover/references/discover-section.md` → "Step 5 — Monetization (section 8)". Prerequisite: section 6 should be filled. Inputs: `start-project.md` sections 1, 3, 6, 7. Output: section 8 plus optional `docs/product/monetization.md`.

---

### Step 6: Idea validation → section 9

Apply the per-section flow from `<plugin>/skills/discover/references/discover-section.md` → "Step 6 — Idea validation (section 9)". Inputs: `start-project.md` sections 1, 2, 3, 4, 8. Output: section 9 plus `docs/product/validation-plan.md` (only if verdict is YELLOW or RED).

---

### Step 7: Marketing hypothesis → section 10

Apply the per-section flow from `<plugin>/skills/discover/references/discover-section.md` → "Step 7 — Marketing hypothesis (section 10)". Inputs: `start-project.md` sections 1, 3, 8, 9. Output: section 10 plus optional `docs/product/marketing-plan.md`.

---

### Step 8: Apple Check → section 11 (iOS only)

**Skip if non-iOS project.** If iOS detected (Step 3):

Invoke the `vladyslav:discover-apple-check` skill via the Skill tool. It handles section 11, `docs/product/apple-review.md`, and its own MemPalace record independently.

---

### Step 9: Final synthesis

1. Re-run `<plugin>/scripts/section-status.sh docs/product/start-project.md` to confirm all targeted sections are now filled. Any path returning to `pending` is a regression to investigate.

   Re-read `docs/product/start-project.md` — confirm all targeted sections are filled
2. Identify contradictions (e.g. monetization assumes $20/mo but SOM from valuation can't support that price). Flag each contradiction to the user: reopen the relevant step or accept as "known tension"
3. Write `docs/product/discovery-summary.md` — 1-page executive view:
   - Idea + core thesis
   - Top 3 competitor threats + our edge
   - Pricing hypothesis + unit economics gist
   - Validation status (green/yellow/red) + top risk
   - Marketing channels + first-100 plan gist
   - Apple-check status (iOS only)
4. Write MemPalace `milestone` record: `"Discovery pass complete for <project>, <date>. Key findings: <3 bullets>"`

### Step 10: Report

```
✓ Architect report — Discovery
- Steps run: <list>
- Steps skipped: <list + why>
- Contradictions found: <count>
- Validation verdict: <GREEN|YELLOW|RED>
- MemPalace records added: <count>
- Files updated:
  - docs/product/start-project.md (sections 6, 8, 9, 10[, 11])
  - docs/product/competitors.md
  - docs/product/discovery-summary.md
  - docs/product/monetization.md (if created)
  - docs/product/marketing-plan.md (if created)
  - docs/product/validation-plan.md (if yellow/red)
  - docs/product/apple-review.md (iOS only)

Next steps:
- /vladyslav:add-feature — start building once discovery verdict is GREEN
- /vladyslav:write-user-stories — document the validated feature set
```

## Notes

- Never fabricate competitor data or market numbers. `TBD` and `ROUGH` are honest; invented figures are traps.
- A RED validation verdict is a gift — it saves months of building the wrong thing.
- Customer-dev questions must be action-intent ("When did you last try to solve X?"), not opinion ("Would you use an app?").
- Running discover twice refreshes research but won't duplicate MemPalace records (`check_duplicate` guards each write).
