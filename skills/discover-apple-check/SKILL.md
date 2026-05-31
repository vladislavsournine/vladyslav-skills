---
name: discover-apple-check
description: Use for iOS projects to pre-validate against Apple App Store Review Guidelines before development. Fills the rejection-risk checklist in start-project.md.
---

# Discover — Apple Check

## Overview

Pre-development Apple App Store review. Instead of discovering rejection risks after 3 months of coding, this sub-skill surfaces them **before** the first commit. Invokes the `apple-appstore-reviewer` skill, cross-references lessons from the `swift-calories` wing (the one app that passed Apple review), and consolidates all known Apple rejection patterns — including the newer ones Apple announces piecemeal in separate review cycles.

Standalone or part of `/vladyslav:discover`. Fills section 11 of `docs/product/start-project.md`.

**Scope:** iOS only. Do not run for web / Android / non-Apple projects.

**Type:** Architect

## Process

### Step 1: Verify iOS project

Run `<plugin>/scripts/detect-stack.sh .` and parse JSON. If `.ios` is false → STOP: "This skill is iOS-only. Detected stacks: <list>." (List from the JSON keys that are `true`.)

If `.ios` is true → record the project name from `CLAUDE.md` and proceed to Step 2.

### Step 2: Read context

Read:
- `docs/product/start-project.md` — sections 1 (ідея), 2 (проблема), 3 (audience), 4 (MVP scope), 7 (tech constraints)
- `CLAUDE.md` — project rules
- Any existing `docs/product/apple-review.md`

### Step 3: MemPalace — pull swift-calories lessons

**Crucial:** `swift-calories` is the wing of the one app that actually passed Apple review. Its lessons are the canonical reference for "what Apple actually rejects."

Run these searches as **one parallel batch** (independent reads — see `_shared/references/orchestration-conventions.md`) and surface ALL hits to the user:

```
mempalace_search wing=swift-calories "apple review"
mempalace_search wing=swift-calories "rejection"
mempalace_search wing=swift-calories "guideline"
mempalace_search wing=swift-calories "privacy manifest"
mempalace_search wing=swift-calories "IAP"
mempalace_search wing=swift-calories "demo account"
```

Also cross-wing:
```
mempalace_search "apple rejection"
mempalace_search "app store review"
```

Compile the findings into a "known-risk list" to feed Step 4.

If `swift-calories` has zero apple-review records, warn the user:

> "The swift-calories wing has no apple-review records seeded yet. This sub-skill will still run, but the output will only contain generic Apple guideline advice — not the curated rejection patterns from the one app that actually passed review.
>
> Options:
> 1. Pause here, run `/vladyslav:ingest` in the swift-calories project to populate the wing, come back — **recommended**
> 2. Continue with generic advice only (weaker, but functional)
> 3. Abort"

Proceed based on their choice. Do not silently skip this — the warning is load-bearing.

### Step 4: Invoke apple-appstore-reviewer

The `apple-appstore-reviewer` skill lives at `~/.claude/skills/apple-appstore-reviewer/SKILL.md`. Read it via the Read tool (not Skill tool — it's a plain prompt-based skill, not a plugin skill) and apply its guidance to the idea + MVP scope described in `start-project.md`.

Feed the reviewer this input:

```
You are auditing a planned iOS app BEFORE development begins. Review against Apple App Store Review Guidelines:

Idea: <section 1 of start-project.md>
Problem: <section 2>
Audience: <section 3>
MVP scope: <section 4>
Tech constraints: <section 7>

Known-risk list from swift-calories wing (the one app that passed review):
<insert MemPalace findings from Step 3>

Produce a prioritized list of rejection risks, covering ALL of these areas (not just the obvious ones):

1. Guideline 4.2 — minimum functionality (is this "web wrapper" or "simple list" territory?)
2. Guideline 5.1.1 + 5.1.2 — privacy: what data, privacy manifest, third-party SDK declarations
3. Guideline 3.1.1 — payments: IAP vs external for digital goods, no workarounds
4. Guideline 2.1 — demo account: will reviewers need credentials? (auth / paywall / premium features)
5. Guideline 1.2 — UGC moderation: reporting, blocking, takedown
6. AI-generated content disclosure (2024-2025 rejection pattern)
7. Guideline 5.1.5 — location access, background modes, justification
8. Guideline 4.0 — design: accessibility, dark mode, dynamic type, iPad support claims
9. Guideline 2.3 — metadata: screenshots must match, no placeholder content

For EACH risk, produce:
- Severity: high / medium / low
- What to decide NOW (before coding) — architectural decisions that lock in compliance
- What to verify DURING development — checkpoints in add-feature
- What to verify BEFORE submission — in pre-release-check

CRITICAL: Apple gives feedback piecemeal across separate review cycles. Consolidate ALL known patterns upfront so the first submission covers everything at once.
```

### Step 5: Synthesize the rejection-risk checklist

Produce a structured section 11 replacement with:

- **Risk status:** `<green | yellow | red>` based on severity count:
  - GREEN: 0 high-severity risks, ≤2 medium
  - YELLOW: 1 high-severity OR 3+ medium
  - RED: 2+ high-severity
- **High-severity risks:** bullet list with "decide now" actions
- **Medium-severity risks:** bullet list
- **Low-severity risks:** bullet list
- **Demo account plan:** if auth is in MVP, plan credentials now
- **Privacy manifest plan:** list the data types and third-party SDKs that will need declaration
- **Link to full analysis:** `docs/product/apple-review.md`

### Step 6: Update files

1. Overwrite section 11 of `docs/product/start-project.md` with the risk summary. Preserve all other sections.
2. Create/overwrite `docs/product/apple-review.md` with the full apple-appstore-reviewer output plus the consolidated risk list.

### Step 7: MemPalace record

`mempalace_check_duplicate` first. If new, `mempalace_add_drawer`:

- **wing:** current project (NOT swift-calories — each project gets its own record)
- **room:** `decision`
- **content:**
  ```
  [WHAT] Pre-development Apple review for <project>
  [STATUS] <GREEN|YELLOW|RED>
  [HIGH RISKS] <count> — <one-line per risk>
  [DECISIONS LOCKED IN] <bullets of architectural decisions>
  [FILES] docs/product/apple-review.md, docs/product/start-project.md#11
  [SOURCE] swift-calories wing + apple-appstore-reviewer
  [DATE] <today>
  ```
- **added_by:** `discover-apple-check`

Also: if you discovered NEW rejection patterns not already in the `swift-calories` wing, write them there too so the knowledge base grows:

- **wing:** `swift-calories`
- **room:** `problem`
- **content:** `[WHAT] New Apple rejection pattern: <name>. [DETAILS] <what triggers it>. [DISCOVERED DURING] <project> pre-review, <date>.`
- **added_by:** `discover-apple-check`

### Step 8: Architect report

```
✓ Architect report — Discover Apple Check
- Risk status: <GREEN|YELLOW|RED>
- High-severity risks: <count>
- Medium: <count>
- Low: <count>
- Decisions locked in: <count>
- Demo account planned: <yes|no>
- Privacy manifest items: <count>
- Files updated:
  - docs/product/start-project.md (section 11)
  - docs/product/apple-review.md (new)
- MemPalace records: <project> wing + <count> new patterns in swift-calories wing

Next steps:
- /vladyslav:add-feature — start building once Apple risk status is GREEN or YELLOW (high-severity resolved)
- /vladyslav:design-sync — canonize the design system before committing to screen layouts
```

## Notes

- **The swift-calories wing is the canonical Apple knowledge base.** Treat it as the source of truth for "what Apple actually rejects in 2025+". When you discover new patterns, write them back there.
- **Apple gives feedback piecemeal.** A first submission might get rejected for reason A, a second for reason B. This sub-skill's job is to front-load ALL known reasons so the first submission covers everything — turning the review cycle from N-iterations into 1.
- **AI-content disclosure is a new pattern (2024-2025).** Apps that generate responses/content via LLMs must disclose this in the UI, not just in the app description. Rejection is silent if missed.
- **Don't run this on non-iOS projects.** The Step 1 check is a hard stop — Apple guidelines don't apply to web or Android.
