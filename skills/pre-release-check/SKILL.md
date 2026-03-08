---
name: pre-release-check
description: Use before any production deployment - runs verification checks on tasks, tests, configs, docs, and reminds to add translations before release
---

# Pre-Release Check

## Overview

Final gate before deployment. Combines automated checks with doc verification. Uses `superpowers:verification-before-completion` principles — evidence before assertions. This is when translations should be added.

**Type:** Engineer (Sonnet)

## Process

### Step 0: Verify model and invoke verification discipline

Check current model. If not Sonnet, switch: `/model sonnet`

Apply `superpowers:verification-before-completion` — every check must produce actual output (test results, grep output, file contents). Do NOT claim PASS without running the command and seeing the result.

### Step 1: Read release context

Read:
- `docs/plans/tasks.md`
- `docs/release/checklist.md`
- `docs/testing/manual-qa.md`
- `docs/product/user-stories.md`
- `docs/release/rollback.md`

### Step 2: Run checks

For each check, report PASS / FAIL / WARN:

**Tasks:**
- [ ] All planned tasks in tasks.md are marked complete

**Tests:**
- [ ] Run test command (detect from stack: `pytest`, `go test ./...`, `flutter test`)
- [ ] All tests pass

**Config:**
- [ ] No `REPLACE_ME` in production config files
- [ ] Search: `grep -r "REPLACE_ME" backend/ --include="*.env*" --include="*.yml" --include="*.yaml"`

**Documentation:**
- [ ] `docs/product/user-stories.md` is up to date (not all TBD)
- [ ] `docs/testing/manual-qa.md` has been filled in
- [ ] `docs/release/rollback.md` has release-specific rollback steps

**Release files:**
- [ ] `docs/release/changelog.md` has entries for this release

### Step 3: Translations reminder

```
╔══════════════════════════════════════════════════════╗
║  NOW is the time to add translations!               ║
║                                                      ║
║  All features are implemented and tested.            ║
║  Add all user-facing string translations now.        ║
╚══════════════════════════════════════════════════════╝
```

Ask: "Have translations been added? (yes/skip)"

### Step 4: Generate changelog

If `docs/release/changelog.md` is empty or TBD, generate it from:
- Git log since last tag/release
- Completed tasks from tasks.md
- New user stories

### Step 5: Print summary

```
═══ Pre-Release Check Summary ═══

Tasks:        ✅ PASS (12/12 complete)
Tests:        ✅ PASS (47 passed, 0 failed)
Config:       ✅ PASS (no REPLACE_ME found)
Docs:         ⚠️  WARN (rollback.md is TBD)
Translations: ✅ PASS
Changelog:    ✅ PASS

Overall: WARN — fix warnings before deploy

Files updated:
- docs/release/changelog.md

If PASS:
━━━ Ready for deploy ━━━━━━━━━━━━━━━━━━━━━━
All checks passed. Ready for production.
- Deploy: docs/deployment.md
- Rollback: docs/release/rollback.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If FAIL (tests failing):
━━━ Fix needed (Opus terminal) ━━━━━━━━━━━━━
/vladyslav:fix-bug

Context:
"Pre-release check failed. <failure details>.
Diagnose and fix before deploy."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
