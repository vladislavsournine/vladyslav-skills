---
name: discover-monetization
description: Use to research monetization model and fill section 8 of docs/product/start-project.md - invokes c-level-skills:cfo-advisor (unit economics) and cpo-advisor (pricing strategy) to produce a pricing hypothesis, CAC/LTV gist, and break-even point
---

# Discover — Monetization

## Overview

Builds the monetization hypothesis for a new project: pricing, unit economics, break-even point. Standalone or part of `/vladyslav:discover`. Fills section 8 of `docs/product/start-project.md` and may produce `docs/product/monetization.md` if deeper analysis is warranted.

**Type:** Architect (Opus)

## Process

### Step 0: Verify model

Check current model. If not Opus: `/model opus`.

### Step 1: Read context

Read `docs/product/start-project.md`, focusing on sections 1 (ідея), 3 (audience), 6 (конкуренти — for price benchmarking), 7 (tech constraints).

**Hard stops:**
- File missing → tell user to run `/vladyslav:init-project` first
- Section 3 (audience) is empty → stop, ask user to fill audience first (you can't price without knowing willingness-to-pay signals)
- Section 6 (competitors) is empty → warn the user; pricing without competitor data is a coin flip. Ask whether to proceed (risky) or run `/vladyslav:discover-competitors` first (recommended).

### Step 2: MemPalace search

Search current wing for `"pricing"`, `"monetization"`, `"unit economics"`, `"business model"`. Cross-wing search for similar categories (SaaS, one-time, freemium) for pattern reuse.

### Step 3: Invoke cpo-advisor for pricing strategy

Invoke `c-level-skills:cpo-advisor` via the Skill tool with:

```
Propose a pricing hypothesis for this product:
- Idea: <section 1>
- Audience: <section 3> (primary + secondary)
- Competitor pricing: <section 6 — if known; otherwise "not yet researched">
- Platform: <section 7>

Produce:
1. Monetization model (subscription / one-time / freemium / ads / B2B license / marketplace)
2. Price point hypothesis ($X/mo or $X one-time) with reasoning
3. Why not 2x higher or 2x lower — explicit trade-offs
4. Willingness-to-pay signals (what evidence supports the hypothesis)
5. Red flags — why this price might fail

Use first-principles reasoning. Reference the CPO reasoning framework.
```

### Step 4: Invoke cfo-advisor for unit economics

Invoke `c-level-skills:cfo-advisor` via the Skill tool with:

```
Given this pricing hypothesis: <cpo-advisor output from Step 3>
And infrastructure budget: <section 7 infra budget>

Produce:
1. Rough CAC estimate (by channel — organic vs paid)
2. LTV estimate (retention assumption × price × gross margin)
3. LTV:CAC ratio target vs hypothesis
4. Break-even point: how many paying users to cover infra + basic operating costs
5. Burn rate if user pays for own development time at $X/hour equivalent
6. Cash risk: how long the founder can run this without external revenue

If the LTV:CAC ratio is below 3:1 → flag as "questionable unit economics", explain why.
```

### Step 5: Synthesize

Combine both outputs into a concise monetization section for `start-project.md`:

- **Як заробляємо:** <model>
- **Цінова гіпотеза:** `$X/<unit>` — <1-line rationale>
- **Unit economics (грубо):** CAC ~<$X>, LTV ~<$X>, ratio <N>:1
- **Точка беззбитковості:** <N> paying users
- **WTP signals:** <bullets>
- **Red flags:** <bullets>

If there's significant depth (e.g. multiple pricing tiers to compare), write a separate `docs/product/monetization.md` with the full analysis and leave section 8 as a summary pointing at it.

### Step 6: Update files

1. Overwrite section 8 of `docs/product/start-project.md`. Preserve all other sections unchanged — Blast Radius Rule.
2. If deep analysis: create/overwrite `docs/product/monetization.md`.

### Step 7: MemPalace record

`mempalace_check_duplicate` first. If new, `mempalace_add_drawer`:

- **wing:** current project
- **room:** `decision`
- **content:**
  ```
  [WHAT] Monetization hypothesis: <model> @ $<price>/<unit>
  [WHY] CAC ~$<X>, LTV ~$<X>, break-even at <N> users
  [RED FLAGS] <bullets>
  [FILES] docs/product/start-project.md#8, docs/product/monetization.md (if exists)
  [DATE] <today>
  ```
- **added_by:** `discover-monetization`

### Step 8: Architect report

```
✓ Architect report — Discover Monetization
- Model: <model>
- Price: $<X>/<unit>
- Unit economics: CAC ~$<X>, LTV ~$<X>, ratio <N>:1
- Break-even: <N> paying users
- Red flags: <count>
- Files updated:
  - docs/product/start-project.md (section 8)
  - docs/product/monetization.md (if created)
- MemPalace record added

━━━ Next ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Continue discovery: /vladyslav:discover-valuation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- If competitors (section 6) are unresearched, this sub-skill will still run but its hypotheses will be weaker. Prefer running `/vladyslav:discover-competitors` first.
- Pricing is a hypothesis — not a commitment. Treat the output as a starting point, not gospel.
- The cpo + cfo combo is intentional: cpo frames the strategic pricing story, cfo quantifies it. Skipping either leaves a gap.
