---
name: write-user-stories
description: Use when product or QA needs implemented features as user stories. Generates from code and docs with acceptance criteria.
---

# Write User Stories

**Type:** Engineer (light)

## Overview

Create or update `docs/product/user-stories.md` — a human-readable registry of implemented features for product owners and QA. Not for development planning — for verification of what is actually built.

This was a Heavy Engineer skill until v3.1.0. The dispatched Sonnet subagent's role was content generation (which legitimately needs a model), but the dispatch overhead, allowlist enforcement, and YAML-return parsing added cost without value. v3.1.0 runs the whole skill inline in Opus main — same outcome, simpler flow.

## Process

### Step 0: Pre-flight

1. Read `CLAUDE.md` from `pwd`. If missing → STOP: "No CLAUDE.md found — are you in the right project?" and extract the project name.

2. Verify input files:
   - **Required:** `docs/product/prd.md`
   - **Optional:** `docs/architecture/api.md`, `docs/architecture/system.md`, existing `docs/product/user-stories.md` (preserve any user-edited content)

3. For missing required file, ask the user:
   > "Required input `docs/product/prd.md` is missing. Options: (a) create stub now / (b) abort. Which?"
   - On abort → exit cleanly.
   - On stub → create `# Product Requirements\n\n*to be filled*\n` and continue.

### Step 1: Read inputs

Read the FULL content of every available input file (do not truncate). Read the codebase too — at minimum scan for route handlers, screen implementations, tests, UI wiring — to determine which features are **actually implemented** versus described in the PRD.

### Step 2: Generate user stories

Write or update `docs/product/user-stories.md`. If the file already exists, preserve any user-edited stories where reasonable — merge rather than overwrite.

Each story uses this format:

```markdown
## [Feature Area]

### US-NNN: [Short title]
**As** [role], **I can** [action], **so that** [benefit].

**Acceptance criteria:**
- [ ] [Specific verifiable check]
- [ ] [Specific verifiable check]

**Status:** ✅ Done / 🚧 Partial / ❌ Not started
**Implemented in:** [file paths or "not yet"]
```

Rules:

- **Human-readable language** — no implementation jargon, no internal class names. The product owner / QA tester is the reader.
- **Each acceptance criterion is independently verifiable** by QA without reading the code.
- **Status reflects actual code state, not plans.** ✅ means implementation exists AND tests cover it; 🚧 means partial; ❌ means not started.
- **Sort:** ✅ Done first, then 🚧 Partial, then ❌ Not started.
- **One section per feature area** (e.g. "Authentication", "Profile", "Payments"). Group related stories.

### Step 3: Summary

Render:

```
✓ write-user-stories complete
  File: docs/product/user-stories.md
  Stories: <total count>  (✅ <done> · 🚧 <partial> · ❌ <not-started>)
  Action: <created | updated>
  Next: /vladyslav:write-test-docs  — derive test plan from these stories
```

---

## Why this is a Light Engineer skill

- **Generation needs LLM** — translating code reality into product-language stories is semantic work. That stays in-model.
- **Dispatch overhead doesn't pay for itself** here. The generation step is one big write, not a multi-stage pipeline. A subagent dispatch adds ~30s of round-trip + structured-return parsing without giving anything back. v3.1.0 just does the write inline in Opus.
- **No allowlist enforcement needed.** The skill writes exactly one file (`docs/product/user-stories.md`) — no risk of scope creep.

## Output

Only one file: `docs/product/user-stories.md`.
