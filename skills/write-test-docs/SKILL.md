---
name: write-test-docs
description: Use when test documentation is missing or outdated - generates test plan with coverage targets and manual QA checklist from PRD and user stories
---

# Write Test Docs

## Overview

Generate test plan and manual QA checklist from PRD, user stories, and architecture docs.

**Type:** Engineer (Sonnet)

## Process

### Step 0: Verify model

Check current model. If not Sonnet, switch: `/model sonnet`

### Step 1: Read context

Read:
- `docs/product/prd.md`
- `docs/product/user-stories.md`
- `docs/architecture/system.md`
- `docs/architecture/api.md` (if exists)
- Existing test files in the codebase

### Step 2: Generate test plan

Write `docs/testing/test-plan.md`:

```markdown
# Test Plan

## Unit Tests
- [Component]: [what to test] — target: [X]% coverage
- ...

## Integration Tests
- [Scenario]: [description]
- ...

## Edge Cases (from PRD)
- [Edge case]: [how to test]
- ...
```

### Step 3: Generate manual QA checklist

Write/update `docs/testing/manual-qa.md`:

```markdown
# Manual QA Checklist

## [User Flow Name]
- [ ] Happy path: [steps]
- [ ] Error: [what happens when X fails]
- [ ] Empty state: [what shows when no data]
- [ ] Loading state: [what shows during load]

## Device-Specific (if mobile)
- [ ] iOS [version]: [checks]
- [ ] Android [version]: [checks]
- [ ] Offline mode: [behavior]
```

### Step 4: Finish

Print engineer report:

```
✓ Engineer report:
- Test plan: docs/testing/test-plan.md
- QA checklist: docs/testing/manual-qa.md
- Coverage targets: <summary>

━━━ Next (Sonnet terminal) ━━━━━━━━━━━━━━━━
To write actual tests:
/superpowers:test-driven-development

Context:
"Test plan at docs/testing/test-plan.md.
Key areas: <summary>. Write tests per plan."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Or continue to documentation:
/vladyslav:write-project-docs

Context:
"Test docs updated. Generate human documentation
(README, onboarding, deployment)."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
