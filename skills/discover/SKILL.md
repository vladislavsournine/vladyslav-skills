---
name: discover
description: Use after init-project or when filling docs/product/start-project.md - orchestrates AI-research across competitors, monetization, valuation, marketing, and Apple-check (for iOS) to auto-fill discovery sections of StartProject template
---

# Discover — Product Discovery Orchestrator

## Overview

Runs 5 discovery sub-flows on top of `docs/product/start-project.md` (created by `init-project` from `templates/StartProject.md`). Each sub-flow fills one discovery dimension using AI-research, the `c-level-skills:*` advisory skills, MemPalace lessons, and — for iOS — the `apple-appstore-reviewer` skill.

Can be run as one monster flow OR via individual sub-commands:

- `/vladyslav:discover-competitors` — competitive landscape + battlecards
- `/vladyslav:discover-monetization` — pricing, unit economics, business model
- `/vladyslav:discover-valuation` — idea validation, PMF scoring, TAM/SAM/SOM
- `/vladyslav:discover-marketing` — channels, retention, first-100-users plan
- `/vladyslav:discover-apple-check` — pre-development iOS review (App Store guidelines)

**Type:** Architect (Opus)

## When to use

- After `/vladyslav:init-project` — once sections 1-5 of `docs/product/start-project.md` are filled in manually
- Mid-project pivot — when the business model or target audience changes and you need fresh research
- Before fundraising — for a consolidated discovery bundle (competitors + valuation + monetization)

## Prerequisites

- `docs/product/start-project.md` exists and has sections 1-5 filled in (ідея, проблема, audience, MVP scope, non-goals)
- At least section 1 must be non-empty — empty StartProject is a hard stop, nothing to research against

## Process

### Step 0: Verify model

Check current model. If not Opus, switch: `/model opus`. Discovery is judgment-heavy — don't run on Sonnet.

### Step 1: Read context

Read:
- `docs/product/start-project.md` — the primary input
- `CLAUDE.md` — project-level rules
- `docs/product/prd.md` (if exists)

**Hard stops:**
- If `start-project.md` is missing → stop, tell user to run `/vladyslav:init-project` first (or copy from `~/.vladyslav-skills/templates/StartProject.md`).
- If sections 1-5 still contain template placeholders (`<...>` markers) → stop, ask user to fill in the foundation, then re-run.

### Step 2: Identify wing and search MemPalace

1. Determine project wing from `pwd` / `CLAUDE.md`
2. Run `mempalace_search` within the wing with queries: `"idea validation"`, `"competitors"`, `"monetization"`, `"marketing"`
3. Cross-wing search for any prior similar products (by category keywords from section 1)
4. Surface hits to the user — prior research shouldn't be re-done

### Step 3: Detect scope

Ask the user which sub-flows to run:

- **All** (default, recommended) — competitors → monetization → valuation → marketing → (iOS only) apple-check
- **Custom** — pick specific ones
- **Skip done** — auto-detect which sections of `start-project.md` are already filled and only run the empty ones

**iOS auto-detection:** if the project has a `swift/` directory OR `CLAUDE.md` mentions Swift/iOS/SwiftUI → include `apple-check` in "All". Otherwise skip it.

### Step 4: Run sub-flows sequentially

For each selected sub-flow, ⏸ stop and tell the user:

> "Step 4.<n> — run `/vladyslav:discover-<name>` in your terminal. When done, come back and say 'done' to continue."

Do NOT run all sub-flows automatically. Each sub-flow writes to `start-project.md` and to MemPalace — the user should see and approve each step.

**Order matters:**

1. `discover-competitors` — foundational, feeds into the others
2. `discover-monetization` — references competitors for price benchmarking
3. `discover-valuation` — references competitors + monetization for realism checks
4. `discover-marketing` — references valuation for channel sizing
5. `discover-apple-check` — independent (iOS only), run last for cleanest sequencing

### Step 5: Final synthesis

After all selected sub-flows complete:

1. Re-read `docs/product/start-project.md` — confirm all targeted sections are filled
2. Identify contradictions between sections (e.g. monetization assumes $20/mo but valuation says TAM can't support that pricing)
3. If contradictions: flag to the user, ask whether to reopen the relevant sub-flow or accept as "known tension"
4. Write `docs/product/discovery-summary.md` — 1-page executive view:
   - Idea + core thesis
   - Top 3 competitor threats + our edge
   - Pricing hypothesis + unit economics gist
   - Validation status (green/yellow/red)
   - Marketing plan gist
   - Apple-check status (for iOS)
5. Write a MemPalace `milestone` record: `"Discovery pass complete for <project>, <date>, key findings: <3 bullets>"`

### Step 6: Architect report

```
✓ Architect report — Discovery
- Sub-flows run: <list>
- Sub-flows skipped: <list + why>
- Contradictions found: <count>
- New MemPalace records: <count>
- Files updated:
  - docs/product/start-project.md
  - docs/product/discovery-summary.md

━━━ Next steps ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Review docs/product/discovery-summary.md with stakeholders
2. If green/yellow: /superpowers:brainstorming to trim MVP
3. If red: reopen sections of start-project.md, iterate
4. When ready: /vladyslav:add-feature for the first feature
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Each sub-flow is independently callable — you don't need to go through `discover` to use them
- Sub-flows are idempotent — running them twice refreshes the research but won't duplicate MemPalace records (they use `mempalace_check_duplicate`)
- `apple-check` is skipped by default for non-iOS projects — don't run it unnecessarily
- The main `discover` flow is just an orchestrator; the real work happens in the 5 sub-skills
