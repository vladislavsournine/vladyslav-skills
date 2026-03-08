---
name: write-test-docs
description: Use when test documentation is missing or outdated - generates test plan with coverage targets and manual QA checklist from PRD and user stories
---

# Write Test Docs

## Overview

Generate test plan and manual QA checklist from PRD, user stories, and architecture docs.

**Recommended model:** Sonnet (`vd-tests` command uses it automatically)

## Process

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

```
✓ Test documentation updated.

Files:
- docs/testing/test-plan.md
- docs/testing/manual-qa.md

Next: Use superpowers:test-driven-development to write actual tests.

Remember:
- /exit to close this session
```
