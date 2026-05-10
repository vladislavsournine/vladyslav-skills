# Discover — Per-Section Update Pattern

This file is the canonical instruction set for Steps 4, 5, 6, 7 of `discover`. The orchestrator (`SKILL.md`) replaces each step body with a thin stanza pointing at the corresponding section of this file.

---

## Generic flow (applies to every section)

For each section update step:

### 1. Check prerequisites

If the step's "Prerequisite" line below is non-empty, verify it. If the prerequisite section is empty or contains `<...>` placeholders, warn the user that running this step without the prerequisite is risky and ask whether to proceed or fill the prerequisite first.

### 2. Invoke the c-level-skill(s)

Use the Skill tool to invoke each c-level-skill listed for the step. Pass the prompt verbatim — do NOT improvise. If multiple skills, invoke sequentially and feed earlier outputs into later inputs as the prompts specify.

### 3. Synthesize

Combine the c-level-skill outputs into the structured section content per the format prescribed below.

Rules:
- Any field that is unknown → write `TBD`, never fabricate.
- Any uncertain number → mark `ROUGH — verify`, never `confident`.
- If the analysis is substantial, write the deeper version to the side file the step lists, and leave the section as a summary pointing to it.

### 4. Update files

1. **Overwrite the target section** of `start-project.md` (number specified per step). Preserve all other sections.
2. **Create/overwrite any side file(s)** the step lists.

### 5. Write a MemPalace `decision` record

Run `mempalace_check_duplicate` first. If not duplicate, run `mempalace_add_drawer` with:
- **wing:** the project wing (from Step 1 / `pwd`)
- **room:** `decision`
- **added_by:** `discover`
- **content:** the per-step template below

If a duplicate is reported, skip the write and note the existing drawer ID in the report.

---

## Step 4 — Competitive landscape (section 6)

**Section:** 6 of `start-project.md`
**Prerequisite:** none
**c-level-skills:** `c-level-skills:competitive-intel`
**Side file:** `docs/product/competitors.md`

### Prompt for `competitive-intel`

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

### Synthesis format

- Markdown table for section 6: `Name | Model | Strength | Weakness | Our edge`
- `docs/product/competitors.md` — deeper battlecards for top 3

Any field that's unknown → `TBD`, not fabricated data.

### MemPalace template

```
[WHAT] Competitive landscape: <top 3 names>
[EDGE] <one-sentence differentiator>
[FILES] docs/product/competitors.md, start-project.md#6
[DATE] <today>
```

---

## Step 5 — Monetization (section 8)

**Section:** 8 of `start-project.md`
**Prerequisite:** section 6 should be filled (for price benchmarking). If empty, warn the user — pricing without competitor data is a coin flip. Ask whether to proceed (risky) or fill competitors first.
**c-level-skills:** `c-level-skills:cpo-advisor` (pricing), then `c-level-skills:cfo-advisor` (unit economics)
**Side file:** `docs/product/monetization.md` (only if substantial)

### Prompt for `cpo-advisor` (pricing)

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

### Prompt for `cfo-advisor` (unit economics)

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

### Synthesis format (section 8)

```
Як заробляємо: <model>
Цінова гіпотеза: $X/<unit> — <1-line rationale>
Unit economics (грубо): CAC ~$X, LTV ~$X, ratio N:1
Точка беззбитковості: N paying users
WTP signals: <bullets>
Red flags: <bullets>
```

If depth warrants it, write full analysis to `docs/product/monetization.md` and leave section 8 as a summary pointing at it.

### MemPalace template

```
[WHAT] Monetization hypothesis: <model> @ $<price>/<unit>
[UNIT ECONOMICS] CAC ~$X, LTV ~$X, break-even at N users
[RED FLAGS] <bullets>
[FILES] start-project.md#8
[DATE] <today>
```

---

## Step 6 — Idea validation (section 9)

**Section:** 9 of `start-project.md`
**Prerequisite:** none (uses sections 1-4, 8)
**c-level-skills:** `c-level-skills:cpo-advisor` (PMF scoring), then `c-level-skills:ceo-advisor` (market sizing)
**Side file:** `docs/product/validation-plan.md` (only if verdict is YELLOW or RED)

### Prompt for `cpo-advisor` (PMF scoring)

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

### Prompt for `ceo-advisor` (market sizing)

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

### Synthesis verdict

- **GREEN** — PMF ≥ emerging, SOM covers min viable income, ≤0 red flags
- **YELLOW** — PMF weak OR SOM tight OR 1-2 red flags
- **RED** — PMF weak AND SOM questionable OR 3+ red flags

If verdict is YELLOW or RED, create `docs/product/validation-plan.md` (customer dev calls, landing page test, concierge MVP steps).

### MemPalace template

```
[WHAT] Idea validation verdict: <GREEN|YELLOW|RED>
[PMF] <weak|emerging|strong>, SOM year 1: ~$X ROUGH
[RISKS] <top red flags>
[NEXT] <N> customer-dev interviews needed
[FILES] start-project.md#9
[DATE] <today>
```

---

## Step 7 — Marketing hypothesis (section 10)

**Section:** 10 of `start-project.md`
**Prerequisite:** none (uses sections 1, 3, 8, 9)
**c-level-skills:** `c-level-skills:cmo-advisor`
**Side file:** `docs/product/marketing-plan.md` (only if substantial)

### Prompt for `cmo-advisor`

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

### Synthesis format (section 10)

```
Канали (ranked): 1. <channel — why>, 2. <channel — why>, 3. <channel — why>
Перший 100 юзерів: <concrete week-1 actions>
Retention hook: <one-line>
Віральність: <inherent|bolted-on|none> — <reason>
Content seeds: <5 specific angles>
Red flags: <bullets>
```

### MemPalace template

```
[WHAT] Marketing hypothesis — channels: <top 3>
[FIRST 100] <one-line week-1 summary>
[RETENTION HOOK] <one-line>
[VIRALITY] <inherent|bolted-on|none>
[FILES] start-project.md#10
[DATE] <today>
```
