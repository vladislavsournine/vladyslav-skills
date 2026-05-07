---
name: discover
description: Use after init-project or when filling docs/product/start-project.md - runs AI-research across competitors, monetization, valuation, and marketing to auto-fill discovery sections; for iOS also invokes discover-apple-check
---

# Discover — Product Discovery

## Overview

Fills sections 6, 8, 9, 10 (and 11 for iOS) of `docs/product/start-project.md` using AI-research and `c-level-skills:*` advisory skills. Runs sequentially so each section builds on the previous one — monetization references competitor pricing, valuation references unit economics, marketing references SOM constraints.

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
- `docs/product/start-project.md` — full file, primary input for all sections
- `CLAUDE.md` — project-level rules
- `docs/product/prd.md` (if exists)

**Hard stops:**
- `start-project.md` missing → stop, tell user to run `/vladyslav:init-project` first
- Sections 1-5 still contain `<...>` placeholders → stop, ask user to fill the foundation first

### Step 2: MemPalace — batch search

Determine the project wing from `pwd` / `CLAUDE.md`. Run all searches upfront:

```
mempalace_search wing=<wing> "competitors"
mempalace_search wing=<wing> "monetization pricing"
mempalace_search wing=<wing> "idea validation PMF"
mempalace_search wing=<wing> "marketing channels"
```

Cross-wing search by category keywords from section 1 (e.g. for a tax app → "tax accounting").

Surface hits — prior research for any dimension shouldn't be re-done.

### Step 3: Detect scope

Ask the user which sections to fill:

- **All** (default) — runs Steps 4 → 5 → 6 → 7 in order
- **Custom** — user picks specific steps
- **Skip done** — auto-detect which sections are already filled (non-empty, no `<...>` markers) and skip those

**iOS auto-detection:** if the project has a `swift/` directory OR `CLAUDE.md` mentions Swift/iOS/SwiftUI → also run Step 8 (apple-check) after Step 7.

---

### Step 4: Competitive landscape → section 6

Invoke `c-level-skills:competitive-intel` via the Skill tool:

```
Analyze the competitive landscape for this product:
- Idea: <section 1>
- Problem: <section 2>
- Audience: <section 3>
- Platform: <section 7 tech constraints>

Produce:
1. Direct competitors (same problem, same audience)
2. Indirect competitors (same problem, different approach)
3. Substitutes (how the audience currently solves this without our category)
4. For top 3 direct: model, strengths, weaknesses, our edge
5. Positioning map (2-axis, e.g. price vs sophistication)

Use WebSearch for current data. If unsure about a company, say "unknown, requires primary research" — do NOT hallucinate names, funding, or features.
```

**Synthesize into:**
- Markdown table for section 6: `Name | Model | Strength | Weakness | Our edge`
- `docs/product/competitors.md` — deeper battlecards for top 3

Any field that's unknown → write `TBD`, not fabricated data.

**Update files:**
1. Overwrite section 6 of `start-project.md`. Preserve all other sections.
2. Create/overwrite `docs/product/competitors.md`.

**MemPalace record** (`mempalace_check_duplicate` first):
```
[WHAT] Competitive landscape: <top 3 names>
[EDGE] <one-sentence differentiator>
[FILES] docs/product/competitors.md, start-project.md#6
[DATE] <today>
```
room: `decision`, added_by: `discover`

---

### Step 5: Monetization → section 8

> Prerequisite: section 6 should be filled (for price benchmarking). If empty, warn the user — pricing without competitor data is a coin flip. Ask whether to proceed (risky) or fill competitors first.

**Invoke `c-level-skills:cpo-advisor`** for pricing strategy:

```
Propose a pricing hypothesis:
- Idea: <section 1>
- Audience: <section 3>
- Competitor pricing: <section 6>
- Platform: <section 7>

Produce:
1. Monetization model (subscription / one-time / freemium / ads / B2B / marketplace)
2. Price point hypothesis with reasoning
3. Why not 2x higher or 2x lower — explicit trade-offs
4. Willingness-to-pay signals
5. Red flags — why this price might fail
```

**Invoke `c-level-skills:cfo-advisor`** for unit economics:

```
Given pricing hypothesis: <cpo-advisor output>
And infra budget: <section 7>

Produce:
1. Rough CAC estimate (organic vs paid)
2. LTV estimate (retention × price × gross margin)
3. LTV:CAC ratio vs target (flag if below 3:1)
4. Break-even: paying users needed to cover infra + operating costs
5. Cash risk: how long the founder can run without external revenue
```

**Synthesize section 8:**
```
Як заробляємо: <model>
Цінова гіпотеза: $X/<unit> — <1-line rationale>
Unit economics (грубо): CAC ~$X, LTV ~$X, ratio N:1
Точка беззбитковості: N paying users
WTP signals: <bullets>
Red flags: <bullets>
```

If depth warrants it, write full analysis to `docs/product/monetization.md` and leave section 8 as a summary pointing at it.

**Update files:**
1. Overwrite section 8 of `start-project.md`. Preserve all other sections.
2. Create/overwrite `docs/product/monetization.md` (if substantial).

**MemPalace record:**
```
[WHAT] Monetization hypothesis: <model> @ $<price>/<unit>
[UNIT ECONOMICS] CAC ~$X, LTV ~$X, break-even at N users
[RED FLAGS] <bullets>
[FILES] start-project.md#8
[DATE] <today>
```
room: `decision`, added_by: `discover`

---

### Step 6: Idea validation → section 9

**Invoke `c-level-skills:cpo-advisor`** for PMF scoring:

```
Score this product idea against PMF criteria:
- Idea: <section 1>
- Problem severity: <section 2>
- Audience: <section 3>
- MVP scope: <section 4>
- Monetization: <section 8>

Produce:
1. PMF score: weak / emerging / strong — based on problem intensity, audience accessibility,
   willingness to pay, and quality of substitutes
2. Single biggest risk to PMF
3. 3-5 customer-development questions (action-intent, not opinion)
4. Red flags from the founder-coach angle
```

**Invoke `c-level-skills:ceo-advisor`** for market sizing:

```
Estimate market sizing:
- Idea: <section 1>
- Audience: <section 3>
- Monetization: <section 8>

Produce:
1. TAM (top-down, cite anchors used)
2. SAM (constrained by language, geography, channel)
3. SOM year 1 (aggressive-realistic)
4. Sensitivity: what changes SOM by 10x?
5. Go/no-go lens: if SOM × price < founder's minimum viable income → red flag

Label uncertain numbers "ROUGH — verify", not "confident".
```

**Synthesize verdict:**
- **GREEN** — PMF ≥ emerging, SOM covers min viable income, ≤0 red flags
- **YELLOW** — PMF weak OR SOM tight OR 1-2 red flags
- **RED** — PMF weak AND SOM questionable OR 3+ red flags

**Update files:**
1. Overwrite section 9 of `start-project.md`.
2. If verdict is YELLOW or RED: create `docs/product/validation-plan.md` (customer dev calls, landing page test, concierge MVP steps).

**MemPalace record:**
```
[WHAT] Idea validation verdict: <GREEN|YELLOW|RED>
[PMF] <weak|emerging|strong>, SOM year 1: ~$X ROUGH
[RISKS] <top red flags>
[NEXT] <N> customer-dev interviews needed
[FILES] start-project.md#9
[DATE] <today>
```
room: `decision`, added_by: `discover`

---

### Step 7: Marketing hypothesis → section 10

**Invoke `c-level-skills:cmo-advisor`:**

```
Build a marketing hypothesis:
- Idea: <section 1>
- Audience (primary + secondary): <section 3>
- Pricing: <section 8>
- SOM constraint: <section 9>

Produce:
1. Channel hypothesis — 2-3 channels ranked by fit, with audience-specific rationale
   (organic: SEO / content / Reddit / community / PH / cold outreach;
    paid: platform fit + rough CPM/CPC; partnerships)
2. First 100 users plan — concrete week-by-week actions, not aspirations
3. Retention hook — what brings users back day 2, 7, 30
4. Virality assessment — inherent vs bolted-on vs none
5. 5 specific content angles (titles/angles, not topics)
6. Red flags — channels that sound good but won't work for this audience

Demand audience-specific channel reasoning. Generic "we'll do SEO + Reddit" is a non-answer.
```

**Synthesize section 10:**
```
Канали (ranked): 1. <channel — why>, 2. <channel — why>, 3. <channel — why>
Перший 100 юзерів: <concrete week-1 actions>
Retention hook: <one-line>
Віральність: <inherent|bolted-on|none> — <reason>
Content seeds: <5 specific angles>
Red flags: <bullets>
```

**Update files:**
1. Overwrite section 10 of `start-project.md`.
2. Create/overwrite `docs/product/marketing-plan.md` (if substantial).

**MemPalace record:**
```
[WHAT] Marketing hypothesis — channels: <top 3>
[FIRST 100] <one-line week-1 summary>
[RETENTION HOOK] <one-line>
[VIRALITY] <inherent|bolted-on|none>
[FILES] start-project.md#10
[DATE] <today>
```
room: `decision`, added_by: `discover`

---

### Step 8: Apple Check → section 11 (iOS only)

**Skip if non-iOS project.** If iOS detected (Step 3):

Invoke the `vladyslav:discover-apple-check` skill via the Skill tool. It handles section 11, `docs/product/apple-review.md`, and its own MemPalace record independently.

---

### Step 9: Final synthesis

1. Re-read `docs/product/start-project.md` — confirm all targeted sections are filled
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
