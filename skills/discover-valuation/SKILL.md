---
name: discover-valuation
description: Use to validate the product idea and fill section 9 of docs/product/start-project.md - invokes c-level-skills:cpo-advisor (PMF scoring) and ceo-advisor (strategy analysis) to produce a green/yellow/red idea-validation verdict with TAM/SAM/SOM estimates
---

# Discover — Valuation

## Overview

Validates the product idea before code: PMF scoring, TAM/SAM/SOM rough sizing, customer-development prompts, and a green/yellow/red verdict. Standalone or part of `/vladyslav:discover`. Fills section 9 of `docs/product/start-project.md`.

**Type:** Architect (Opus)

## Process

### Step 0: Verify model

Check current model. If not Opus: `/model opus`.

### Step 1: Read context

Read `docs/product/start-project.md`, focusing on sections 1 (ідея), 2 (проблема), 3 (audience), 4 (MVP scope), 6 (competitors — if filled), 8 (monetization — if filled).

**Hard stops:**
- File missing → tell user to run `/vladyslav:init-project` first
- Sections 1-4 empty → stop, ask user to fill the foundation first

### Step 2: MemPalace search

Search current wing for `"idea validation"`, `"PMF"`, `"TAM"`, `"customer development"`. Cross-wing search for validation attempts in similar categories (success + failure patterns are both useful).

### Step 3: Invoke cpo-advisor for PMF scoring

Invoke `c-level-skills:cpo-advisor` via the Skill tool with:

```
Score this product idea against product-market fit criteria:
- Idea: <section 1>
- Problem severity: <section 2 — how acute is the pain>
- Audience size + reachability: <section 3>
- MVP scope: <section 4>

Produce:
1. PMF score estimate (weak / emerging / strong) — based on:
   - Problem intensity (how badly the audience wants it solved)
   - Audience accessibility (can you find them affordably)
   - Willingness to pay (signals from section 8 if present)
   - Substitutes (do they already have "good enough" alternatives)
2. The single biggest risk to PMF
3. 3-5 customer-development questions to ask REAL users before coding (not market-research questions, action-intent questions)
4. Red flags from the founder-coach angle (overconfidence, solution-in-search-of-problem, etc.)

Use the pmf_scorer framework. Do NOT invent market data — only reason from what's in the input.
```

### Step 4: Invoke ceo-advisor for strategic sizing

Invoke `c-level-skills:ceo-advisor` via the Skill tool with:

```
Estimate market sizing for this product:
- Idea: <section 1>
- Audience: <section 3>
- Monetization: <section 8 — if known>

Produce:
1. TAM (top-down) — order-of-magnitude estimate, citing which public stats you're using as anchors
2. SAM — realistic addressable market given language, geography, and channel constraints
3. SOM — first-year realistic obtainable market (be aggressive-realistic, not founder-optimistic)
4. Sensitivity — what would change the SOM by 10x?
5. Go/no-go lens: if SOM at year 1 × monetization price < founder's minimum viable income → red flag

Use Tree of Thought reasoning. If any number requires data you don't have, label it "ROUGH — verify" not "confident".
```

### Step 5: Synthesize verdict

Combine both outputs into a green/yellow/red status:

- **GREEN** — PMF score ≥ emerging, SOM covers minimum viable income, no red flags
- **YELLOW** — PMF is weak OR SOM is tight OR 1-2 red flags — proceed with explicit validation plan first
- **RED** — PMF is weak AND SOM is questionable OR 3+ red flags — recommend pivot or kill

Write the section 9 update:

- **Desk research:** `<TAM / SAM / SOM with "ROUGH" markers>`
- **Customer development questions:** `<3-5 from cpo-advisor>`
- **Red flags:** `<from both advisors>`
- **Verdict:** `<green / yellow / red>` — `<one-line reason>`

### Step 6: Update files

1. Overwrite section 9 of `docs/product/start-project.md`. Preserve all other sections unchanged.
2. If verdict is **yellow** or **red**: also create `docs/product/validation-plan.md` with a step-by-step plan for the user (customer development calls, landing page test, concierge MVP, etc.) — this is the path out of yellow/red before committing to code.

### Step 7: MemPalace record

`mempalace_check_duplicate` first. If new, `mempalace_add_drawer`:

- **wing:** current project
- **room:** `decision`
- **content:**
  ```
  [WHAT] Idea validation verdict: <GREEN|YELLOW|RED>
  [WHY] PMF score: <weak|emerging|strong>, SOM year 1: <rough $>
  [RISKS] <top red flags>
  [NEXT] <customer development count> interviews needed
  [FILES] docs/product/start-project.md#9, docs/product/validation-plan.md (if yellow/red)
  [DATE] <today>
  ```
- **added_by:** `discover-valuation`

### Step 8: Architect report

```
✓ Architect report — Discover Valuation
- PMF score: <weak|emerging|strong>
- TAM/SAM/SOM (rough): $<X>M / $<X>M / $<X>M
- Verdict: <GREEN|YELLOW|RED>
- Top risk: <one line>
- Customer dev interviews to run: <count>
- Files updated:
  - docs/product/start-project.md (section 9)
  - docs/product/validation-plan.md (if yellow/red)
- MemPalace record added

━━━ Next ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
If GREEN: /vladyslav:discover-marketing
If YELLOW or RED: work through docs/product/validation-plan.md BEFORE continuing to code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Never replace "rough" estimates with false precision. `$5M ROUGH` is honest; `$5.2M` is a lie.
- A RED verdict is a gift — it saves months of building the wrong thing. Treat it as a win, not a failure.
- Customer development questions must be action-intent ("When did you last try to solve X?"), not opinion ("Would you use an app that does X?").
