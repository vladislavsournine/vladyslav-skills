---
name: write-test-docs
description: Use when test docs are missing or outdated. Generates test plan and manual QA checklist from PRD and user stories.
---

# Write Test Docs

**Type:** Engineer (light)

## Overview

Generate `docs/testing/test-plan.md` and `docs/testing/manual-qa.md` — the automated test plan and the manual QA checklist that QA runs before each release.

This was a Heavy Engineer skill until v3.1.0. The Sonnet dispatch + YAML-return contract paid no rent for what is essentially "read inputs, write two markdown files". v3.1.0 runs inline in Opus.

## Process

### Step 0: Pre-flight

1. Read `CLAUDE.md` from `pwd`. If missing → STOP: "No CLAUDE.md found — are you in the right project?" and extract the project name and stack.

2. Verify input files:
   - **Required:** `docs/product/prd.md`, `docs/product/user-stories.md`
   - **Optional:** `docs/architecture/api.md`, existing `docs/testing/test-plan.md`, existing `docs/testing/manual-qa.md` (preserve user-edited sections)

3. For each missing **required** file, ask the user:
   > "Required input `<path>` is missing. Options: (a) run `/vladyslav:write-user-stories` first / (b) create stub and continue / (c) abort"
   - On (a) → exit and let user run that skill first. Do not write anything.
   - On (b) → create the stub and continue (the resulting test plan will be skeletal).
   - On (c) → exit cleanly.

### Step 1: Read inputs

Read the FULL content of every available input file. Optionally also peek at the test runner config (`pytest.ini` / `pyproject.toml` / `package.json` test script / xcodeproj scheme) to align the plan with the actual stack.

### Step 2: Generate the test plan

Write `docs/testing/test-plan.md`. If it exists, preserve user-edited sections and merge.

Structure:

```markdown
# Test Plan

## Coverage targets

| Layer | Target | Current | Owner |
|-------|--------|---------|-------|
| Unit | 70% | TBD | <stack-specific runner> |
| Integration | core flows covered | TBD | — |
| E2E | smoke path only | TBD | — |

## Test categories

### Unit
- [feature area] — [what to cover]

### Integration
- [feature area] — [what to cover]

### E2E (smoke)
- [critical user path 1]
- [critical user path 2]

## Stack notes

- Test runner: `<command>` (e.g. `pytest`, `go test ./...`, `xcodebuild test`)
- CI hook: <how tests run in CI, or "not yet wired">
- Fixtures location: <path>
```

Derive each category's contents from the user-stories file. Every ✅ Done story gets at least one entry in either Unit or Integration. Every 🚧 Partial story gets a `[ ]` task.

### Step 3: Generate manual QA checklist

Write `docs/testing/manual-qa.md`. Same preserve-on-update behaviour.

Structure:

```markdown
# Manual QA Checklist

> Run before every release. Each item is a happy-path or edge-case verification that a human performs in the running app.

## Pre-flight

- [ ] Latest build is installed on the test device / running locally
- [ ] Test data is seeded
- [ ] Logs are visible (Console.app / docker logs / browser devtools)

## [Feature Area 1]

### Happy path
- [ ] [Specific user action] → [expected observable result]

### Edge cases
- [ ] [Edge case action] → [expected result]
- [ ] Empty state — [what to verify]

## [Feature Area 2]
...

## Cross-cutting

- [ ] Dark mode renders correctly on every screen (iOS / web)
- [ ] Dynamic type / browser zoom up to 200% does not break layout
- [ ] VoiceOver / screen reader reaches every interactive element
- [ ] All user-facing strings have translations (if multi-language)
- [ ] No console errors during the happy path
```

Cross-cutting checks adapt to the stack (iOS: Dark Mode + VoiceOver; web: zoom + screen reader; backend-only: skip cross-cutting).

### Step 4: Summary

Render:

```
✓ write-test-docs complete
  Files: docs/testing/test-plan.md, docs/testing/manual-qa.md
  Action: <created | updated> (per file)
  Coverage targets: <"set" | "kept stub — please fill manually">
  Next: /vladyslav:pre-release-check  — verify the release before deployment
```

---

## Why this is a Light Engineer skill

- **Generation is LLM work**, but it's one synthesis pass per file — not a multi-stage pipeline. Dispatch overhead is pure tax.
- **Two output files, both predictable paths.** No allowlist enforcement needed.
- **Preservation logic** (don't overwrite user-edited sections) is the only nuance — and it's a single semantic step Opus can handle without ceremony.

## Output

- `docs/testing/test-plan.md`
- `docs/testing/manual-qa.md`
