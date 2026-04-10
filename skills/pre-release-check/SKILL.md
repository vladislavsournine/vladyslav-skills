---
name: pre-release-check
description: Use before any production deployment - runs verification checks on tasks, tests, configs, docs, translations, and (iOS only) a submission-phase Apple App Store review that blocks the release on any BLOCKER/HIGH finding
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

### Step 4: Apple App Store review (iOS only)

**Skip this step for non-iOS projects.** Signals of an iOS project:
- `swift/` directory, `*.xcodeproj`, or `Package.swift` in project root
- `CLAUDE.md` mentions Swift / iOS / SwiftUI

If none → skip to Step 5.

**Why this step exists:** `discover-apple-check` audits the IDEA before coding. This step audits the SHIPPED ARTIFACT — screenshots, metadata, final UI strings, privacy manifest, IAP wiring — against the same guidelines, plus anything new Apple has flagged in between.

1. **Read prior audit.** Open `docs/product/apple-review.md` (written by `discover-apple-check`). If missing, warn: "No pre-development Apple review found. Submission-phase check will only catch issues visible in the shipped artifact — earlier architectural risks may already be baked in." Continue anyway.

2. **Refresh rejection patterns.** Run cross-wing searches to pick up anything new since the pre-dev check:
   ```
   mempalace_search wing=swift-calories "apple rejection"
   mempalace_search wing=swift-calories "review feedback"
   mempalace_search "apple rejection 2025"
   mempalace_search "apple rejection 2026"
   ```
   Compile findings — anything not in `docs/product/apple-review.md` is new and must be checked.

3. **Invoke `apple-appstore-reviewer`.** Read the skill at `~/.claude/skills/apple-appstore-reviewer/SKILL.md` (plain prompt-based skill, not a plugin skill — use Read, not Skill tool). Apply it against the shipped artifact with this input:

   ```
   You are reviewing a shipped iOS app BEFORE submission to App Store Connect.
   This is the LAST gate before upload.

   Prior audit (pre-development): <paste docs/product/apple-review.md summary>
   New rejection patterns since prior audit: <paste MemPalace findings>

   Audit the shipped artifact against Apple App Store Review Guidelines, with
   emphasis on things that can ONLY be verified after implementation:

   A. Guideline 2.1 — demo account: credentials in App Store Connect reviewer notes
   B. Guideline 2.3 — screenshots match shipped UI (no placeholders, no mockups)
   C. Guideline 5.1.1 — privacy: PrivacyInfo.xcprivacy exists, all tracked APIs declared,
      third-party SDK privacy manifests present
   D. Guideline 5.1.2 — Info.plist usage descriptions for every requested permission
   E. Guideline 3.1.1 — IAP: no external payment links for digital goods, no
      "subscribe on website" text
   F. Guideline 4.0 — accessibility: VoiceOver labels, dynamic type, dark mode
   G. AI-content disclosure (if any LLM features) — visible UI disclosure, not
      just App Store description
   H. Guideline 4.2 — minimum functionality: does the shipped app do more than
      a web wrapper / simple list?
   I. Guideline 5.1.5 — background modes and location justifications in Info.plist
      match actual usage

   For EACH finding, report:
   - Severity: BLOCKER / HIGH / MEDIUM / LOW
   - Where in the artifact: file path or App Store Connect field
   - Exact fix (not "consider adding X" — give the text/code)

   Also verify each item from the pre-dev audit's "decisions locked in" list is
   actually in the shipped code.
   ```

4. **Process findings:**
   - **BLOCKER or HIGH** → Overall result = FAIL, regardless of other checks. Block the release.
   - **MEDIUM** → WARN in summary, let user decide.
   - **LOW** → list in summary as FYI.

5. **Write findings** to `docs/release/apple-review-submission.md` (new file). Format:
   ```
   # Apple App Store Submission Review — <date>

   ## Blockers
   - <severity> <guideline> — <what> → <exact fix>

   ## Warnings
   - ...

   ## FYI
   - ...

   ## Pre-dev audit verification
   - [x] <decision from apple-review.md> — verified in <file>
   - [ ] <decision> — NOT implemented (BLOCKER)
   ```

6. **MemPalace writeback.** If you discovered NEW rejection patterns during this audit (patterns not in `swift-calories` wing), write them there via `mempalace_add_drawer`:
   - **wing:** `swift-calories`
   - **room:** `problem`
   - **content:** `[WHAT] New Apple rejection pattern: <name>. [DETAILS] <trigger>. [DISCOVERED DURING] <project> submission review, <date>.`
   - **added_by:** `pre-release-check`

   Check duplicates first with `mempalace_check_duplicate`.

### Step 5: Generate changelog

If `docs/release/changelog.md` is empty or TBD, generate it from:
- Git log since last tag/release
- Completed tasks from tasks.md
- New user stories

### Step 6: Print summary

```
═══ Pre-Release Check Summary ═══

Tasks:        ✅ PASS (12/12 complete)
Tests:        ✅ PASS (47 passed, 0 failed)
Config:       ✅ PASS (no REPLACE_ME found)
Docs:         ⚠️  WARN (rollback.md is TBD)
Apple review: ✅ PASS (iOS only — 0 blockers, 1 warning)
Translations: ✅ PASS
Changelog:    ✅ PASS

Overall: WARN — fix warnings before deploy

Files updated:
- docs/release/changelog.md
- docs/release/apple-review-submission.md (iOS only)

If PASS:
━━━ Ready for deploy ━━━━━━━━━━━━━━━━━━━━━━
All checks passed. Ready for production.
- Deploy: docs/deployment.md
- Rollback: docs/release/rollback.md
- iOS submission: docs/release/apple-review-submission.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If FAIL (tests failing OR Apple BLOCKER/HIGH):
━━━ Fix needed (Opus terminal) ━━━━━━━━━━━━━
/vladyslav:fix-bug

Context:
"Pre-release check failed. <failure details>.
Diagnose and fix before deploy."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Apple review integration — why it's a hard gate

Apple BLOCKER/HIGH findings make the whole check FAIL even if tests/config/docs all pass. Reasoning: shipping an iOS build that will be rejected is worse than holding a release — rejection means a review cycle lost (typically a week) and a worse signal to Apple about the project. Better to catch it at this step than after upload.

If you find yourself wanting to override this — STOP. The right move is to fix the finding, not weaken the gate.
