---
name: discover-marketing
description: Use to research marketing channels and fill section 10 of docs/product/start-project.md - invokes c-level-skills:cmo-advisor to produce a channel hypothesis, first-100-users plan, retention hook, and virality assessment
---

# Discover — Marketing

## Overview

Builds the marketing hypothesis for a new project: which channels, how to get the first 100 users, what makes people come back on day 2, and whether there's a natural virality loop. Standalone or part of `/vladyslav:discover`. Fills section 10 of `docs/product/start-project.md`.

**Type:** Architect (Opus)

## Process

### Step 0: Verify model

Check current model. If not Opus: `/model opus`.

### Step 1: Read context

Read `docs/product/start-project.md`, focusing on sections 1 (ідея), 3 (audience), 8 (monetization — for channel sizing), 9 (valuation — for SOM constraints).

**Hard stops:**
- File missing → tell user to run `/vladyslav:init-project` first
- Section 3 (audience) empty → stop, ask user to fill audience first — channels without audience is guessing

### Step 2: MemPalace search

Search current wing for `"marketing"`, `"channels"`, `"retention"`, `"acquisition"`, `"first users"`. Cross-wing search for channel playbooks that worked or failed in similar categories.

### Step 3: Invoke cmo-advisor

Invoke `c-level-skills:cmo-advisor` via the Skill tool with:

```
Build a marketing hypothesis for this product:
- Idea: <section 1>
- Audience (primary + secondary): <section 3>
- Pricing: <section 8 — if known>
- SOM constraint: <section 9 — if known>

Produce:
1. Channel hypothesis — which 2-3 channels to try first, ranked by fit:
   - Organic: SEO, content, Reddit, community, ProductHunt, cold outreach
   - Paid: which platforms match audience, rough CPM/CPC expectations
   - Partnerships: integration partners, bundles, affiliate
   - For each: why this channel fits THIS audience, not a generic pitch
2. First 100 users plan — concrete actions, not aspirations:
   - Week 1: what exactly happens
   - Week 2-4: follow-up
   - Who founders should talk to by name/profile
3. Retention hook — what makes users come back on day 2, day 7, day 30
4. Virality assessment — is there a natural reason to share (inherent virality vs bolted-on referral)?
5. Content angles — 5 specific content pieces (not topics — actual titles/angles) that fit the audience
6. Red flags — channels that sound good but likely won't work

Use Recursion of Thought reasoning. Reference marketing-skills domain if deeper analysis is needed.
```

### Step 4: Synthesize

Combine the cmo-advisor output into section 10:

- **Канали (ranked):** `1. <channel> — <why>, 2. <channel> — <why>, 3. <channel> — <why>`
- **Перший 100 юзерів:** `<concrete week-1 actions>`
- **Retention hook:** `<one-line>`
- **Віральність:** `<inherent | bolted-on | none>` — `<reason>`
- **Content seeds:** `<bullet list of 5 specific angles>`
- **Red flags:** `<bullets>`

If the plan is substantial, write a full `docs/product/marketing-plan.md` and keep section 10 as a summary that points at it.

### Step 5: Update files

1. Overwrite section 10 of `docs/product/start-project.md`. Preserve all other sections.
2. If substantial: create/overwrite `docs/product/marketing-plan.md`.

### Step 6: MemPalace record

`mempalace_check_duplicate` first. If new, `mempalace_add_drawer`:

- **wing:** current project
- **room:** `decision`
- **content:**
  ```
  [WHAT] Marketing hypothesis — channels: <top 3>
  [FIRST 100] <one-line summary of week-1 plan>
  [RETENTION HOOK] <one-line>
  [VIRALITY] <inherent|bolted-on|none>
  [FILES] docs/product/start-project.md#10, docs/product/marketing-plan.md (if exists)
  [DATE] <today>
  ```
- **added_by:** `discover-marketing`

### Step 7: Architect report

```
✓ Architect report — Discover Marketing
- Top 3 channels: <list>
- First 100 users plan: <one-line summary>
- Retention hook: <one-line>
- Virality: <inherent|bolted-on|none>
- Content seeds: <count> specific angles
- Files updated:
  - docs/product/start-project.md (section 10)
  - docs/product/marketing-plan.md (if created)
- MemPalace record added

━━━ Next ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For iOS projects: /vladyslav:discover-apple-check
Otherwise: run /vladyslav:discover (back to main) for final synthesis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- Demand channels that are **specific to this audience**. Generic "we'll do SEO + Reddit" is a non-answer.
- The first-100-users plan must contain concrete week-1 actions, not "we'll launch on ProductHunt" alone.
- If the cmo-advisor output contains generic template language, reject it and re-ask for product-specific detail.
