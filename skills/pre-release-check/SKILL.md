---
name: pre-release-check
description: Use before any production deployment - runs verification checks on tasks, tests, configs, docs, translations, and (iOS only) a submission-phase Apple App Store review that blocks the release on any BLOCKER/HIGH finding
---

# Pre-Release Check

## Overview

Final gate before deployment. Combines automated checks with doc verification. Uses `superpowers:verification-before-completion` principles — evidence before assertions. This is when translations should be added.

**Type:** Engineer

## Process

### Step 0: Pre-flight (Opus main)

Interactive checks before dispatching the subagent.

1. Read `CLAUDE.md` in `pwd`. If missing → STOP: "No CLAUDE.md found in current directory. Are you in the right project?". Otherwise extract project name and identify the platform (iOS / web / backend / plugin / etc.) by looking for:
   - iOS signals: `swift/` directory, `*.xcodeproj`, `Package.swift` in project root, or CLAUDE.md mentions Swift / iOS / SwiftUI
   - Plugin signals: CLAUDE.md mentions "Claude Code plugin" or a `.claude-plugin/` directory
   - Web signals: `package.json`, `tailwind.config.*`, Next.js / React references
   - Backend signals: `backend/`, `requirements.txt`, `go.mod`, `Dockerfile` without iOS/web
   - Record `platform` as one of: `ios`, `web`, `backend`, `plugin`, `other`

2. Check input files:
   - `docs/plans/tasks.md` — **required** (task-completion check)
   - `docs/testing/manual-qa.md` — optional
   - `docs/architecture/system.md` — optional
   - Platform config file — optional, pick whichever applies: `.claude-plugin/plugin.json` (plugin), `package.json` (web), `backend/requirements.txt` or `backend/go.mod` (backend)

3. For the missing **required** file (`docs/plans/tasks.md`), ask user:
   > "Required input `docs/plans/tasks.md` is missing. Options: (a) create stub now / (b) abort. Which?"
   - On abort → exit cleanly, no dispatch.
   - On stub → create a placeholder file (`# Tasks\n\n*to be filled*\n`), proceed.

4. Read FULL content of all available input files. Record paths and content.

5. Get today's date (YYYY-MM-DD format) from the `currentDate` context or by running `date +%Y-%m-%d`.

6. Compose dispatch context: project name, platform, verified file paths + content, today's date.

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Run pre-release verification sweep"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs>`

Wait for return.

### Step 2: Present summary

Parse the YAML block in the subagent's response. Look for the last fenced ` ```yaml ` block. Treat as parse failure (status: unknown) if: (a) no ` ```yaml ` block is found, (b) the block does not contain a `status:` field, OR (c) the YAML is malformed (e.g., unbalanced indentation).

**If parse fails** → print the full subagent output, run `git status --short`, tell user: "Subagent returned unstructured response. Files on disk: `<git status>`. Review manually."

**If parse succeeds**, render based on `status`:

`status: success` →
```
✓ Engineer summary (pre-release-check)
  Wrote: <files_written paths joined>
  Warnings: <warnings, if any>
  Files unstaged. Review before commit.
  Next: <next_step_suggestion>
```

`status: partial` → same as success plus:
```
  Note: <files_skipped> were not generated. See warnings.
```

`status: scope_expansion_required` →
```
⚠ Engineer halted (pre-release-check)
  Subagent wanted to modify <path> (outside allowlist).
  Reason: <reason>

  Options:
    1. Approve — re-dispatch with extended allowlist
    2. Skip — leave file untouched
    3. Abort
```
Wait for user choice. On (1), re-dispatch: take the same subagent prompt template from Step 1, add the path from `scope_expansion_required[0].path` (and any additional entries) to the Output allowlist section of the prompt, re-invoke the Agent tool with this updated prompt and the same other parameters. Reuse pre-flight outputs already in memory — do NOT re-read input files. On (2), record the skipped path and proceed to next step. On (3), exit cleanly with no further action.

`status: error` →
```
✗ Engineer failed (pre-release-check)
  Error: <error message>
```
Best-effort: invoke `vladyslav:stash` skill with `source: "pre-release-check:error"`, `task: "Pre-release check"`, `open_question: "Subagent failed: <error>"`. If stash itself fails, log warning, continue.

---

## Subagent prompt template

````
You are a Sonnet subagent dispatched by the `pre-release-check` skill in the `vladyslav-skills` plugin. You have no conversation history with the user — this prompt is your full briefing. Do NOT call AskUserQuestion — all decisions have already been made in pre-flight.

Apply `superpowers:verification-before-completion` principles throughout: every check must produce actual output (test results, grep output, file contents). Do NOT claim PASS without running the command and seeing the result.

## Project context

Working directory: <pwd>
Project name: <from CLAUDE.md>
Platform: <ios | web | backend | plugin | other>
Today's date: <YYYY-MM-DD from pre-flight>
Key facts from CLAUDE.md (extracted by pre-flight — project type, primary tech stack, platform, any release-relevant constraints):
<3-5 bullets>

## Verified inputs

docs/plans/tasks.md:
<content from pre-flight>

docs/testing/manual-qa.md (if available):
<content from pre-flight, or "not available">

docs/architecture/system.md (if available):
<content from pre-flight, or "not available">

Platform config file (if available):
<path and content from pre-flight, or "not available">

## Your task

Run the full pre-release verification sweep. For each check below, produce actual evidence (command output, file excerpts) and report PASS / FAIL / WARN with severity.

---

### Check 1: Tasks completion

Read `docs/plans/tasks.md`. Count tasks marked complete vs. total planned tasks.

- PASS: all planned tasks are marked complete
- WARN (severity: high): incomplete tasks remain — list them
- FAIL (severity: blocker): tasks.md is missing or empty

---

### Check 2: Tests configured

Detect the test command from the project stack:
- Python: `pytest` (check for `pytest.ini`, `pyproject.toml [tool.pytest...]`, or `tests/` directory)
- Go: `go test ./...`
- Flutter: `flutter test`
- Swift / iOS: `xcodebuild test` (check for `.xcodeproj` or `Package.swift`)
- Node/web: look for `npm test` or `yarn test` in `package.json`
- Plugin (no traditional test runner): check for any test files in `skills/` — note "plugin type, manual verification only"

If a test runner is found: run the test command and capture output.
- PASS: all tests pass (zero failures)
- FAIL (severity: blocker): one or more tests fail — include failure output
- WARN (severity: medium): no tests found / test runner not configured

---

### Check 3: Config sanity

Search for placeholder values in production config files:
```bash
grep -r "REPLACE_ME" . --include="*.env*" --include="*.yml" --include="*.yaml" --include="*.json" --include="*.toml" 2>/dev/null | grep -v ".git/"
```

- PASS: no `REPLACE_ME` found
- FAIL (severity: blocker): `REPLACE_ME` found — list every occurrence with file path and line

---

### Check 4: Documentation sync

Check each doc for placeholder content (all TBD / empty):

- `docs/testing/manual-qa.md` — WARN if missing or all `*to be filled*`
- `docs/release/changelog.md` — WARN if missing or empty; if empty/TBD, auto-generate from git log (see below)
- `docs/release/rollback.md` — WARN if missing or all `*to be filled*`
- `docs/product/user-stories.md` — WARN if missing or all TBD

**Auto-generate changelog if missing/empty:**
Run `git log --oneline` since last tag/release. Combine with completed tasks from tasks.md and any new user stories. Write a `docs/release/changelog.md` entry for this release — but only if the file is missing or has TBD content. If you auto-generate it, mark the file in `files_written` with `action: created`.

Severity for doc warnings: `low` (warn but do not block).

---

### Check 5: Translations reminder

```
╔══════════════════════════════════════════════════════╗
║  NOW is the time to add translations!               ║
║                                                      ║
║  All features are implemented and tested.            ║
║  Add all user-facing string translations now.        ║
╚══════════════════════════════════════════════════════╝
```

Check whether translations appear present:
- iOS: look for `.xcstrings` or `Localizable.strings` files
- Web: look for `i18n/`, `locales/`, `messages/` directories or `*.json` translation files
- Other: note "manual verification required"

Report PASS if translation files found, WARN (severity: low) if not found (translations may not apply to this project type).

---

### Check 6: Apple App Store review (iOS only)

**Skip this check entirely if `platform` is NOT `ios`.**

**Why this check exists:** `discover-apple-check` audits the IDEA before coding. This step audits the SHIPPED ARTIFACT — screenshots, metadata, final UI strings, privacy manifest, IAP wiring — against the same guidelines, plus anything new Apple has flagged in between.

1. **Read prior audit.** Open `docs/product/apple-review.md` (written by `discover-apple-check`). If missing, warn: "No pre-development Apple review found. Submission-phase check will only catch issues visible in the shipped artifact — earlier architectural risks may already be baked in." Continue anyway.

2. **Refresh rejection patterns.** Run cross-wing MemPalace searches to pick up anything new since the pre-dev check:
   ```
   mempalace_search wing=swift-calories "apple rejection"
   mempalace_search wing=swift-calories "review feedback"
   mempalace_search "apple rejection 2025"
   mempalace_search "apple rejection 2026"
   ```
   Compile findings — anything not in `docs/product/apple-review.md` is new and must be checked.

3. **Apply apple-appstore-reviewer checklist.** Read the skill at `~/.claude/skills/apple-appstore-reviewer/SKILL.md` (plain prompt-based skill — use Read tool, not Skill tool). Apply it against the shipped artifact with this input:

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
   - **BLOCKER or HIGH** → Apple check = FAIL (severity: blocker), regardless of other checks. Block the release.
   - **MEDIUM** → Apple check = WARN (severity: medium), let user decide.
   - **LOW** → list in summary as FYI.

5. **Write findings** to `docs/release/apple-review-submission.md` (new file). Format:
   ```markdown
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

6. **MemPalace writeback.** If you discovered NEW rejection patterns during this audit (patterns not already in `swift-calories` wing), write them via `mempalace_add_drawer`:
   - **wing:** `swift-calories`
   - **room:** `problem`
   - **content:** `[WHAT] New Apple rejection pattern: <name>. [DETAILS] <trigger>. [DISCOVERED DURING] <project> submission review, <date>.`
   - **added_by:** `pre-release-check`

   Check duplicates first with `mempalace_check_duplicate`.

---

### Overall result

Compute overall result from all checks:

- **FAIL** if ANY check is severity `blocker`
- **WARN** if any check is severity `high` or `medium` (no blockers)
- **PASS** if all checks are severity `low` or better

Print summary:

```
═══ Pre-Release Check Summary ═══

Tasks:        <✅ PASS | ⚠️ WARN | ❌ FAIL> (<detail>)
Tests:        <✅ PASS | ⚠️ WARN | ❌ FAIL> (<detail>)
Config:       <✅ PASS | ⚠️ WARN | ❌ FAIL> (<detail>)
Docs:         <✅ PASS | ⚠️ WARN | ❌ FAIL> (<detail>)
Translations: <✅ PASS | ⚠️ WARN | N/A>
Apple review: <✅ PASS | ⚠️ WARN | ❌ FAIL | N/A (not iOS)>

Overall: <PASS | WARN | FAIL> — <one-line reason>
```

---

## Output allowlist

You may ONLY create or modify these files:
- `docs/release/pre-release-report-<YYYY-MM-DD>.md` (replace with today's date)

Exception: if the Apple review check runs (iOS only), you may also write:
- `docs/release/apple-review-submission.md`

If the changelog auto-generation ran (Check 4), you may also write:
- `docs/release/changelog.md`

If you discover need to touch any other file — STOP, do NOT make the change, return `status: scope_expansion_required`.

**Write the pre-release report** to `docs/release/pre-release-report-<YYYY-MM-DD>.md` (today's date). The report must include:
- Per-check PASS/FAIL/WARN with severity and evidence
- Overall result
- Blocker list (if any)
- Recommended next action

---

## Required return format

End your response with EXACTLY one YAML block:

```yaml
status: success | partial | scope_expansion_required | error
files_written:
  - path: docs/release/pre-release-report-<YYYY-MM-DD>.md
    action: created
overall_result: PASS | WARN | FAIL
blockers:
  - <blocker description, if any>
warnings:
  - <non-blocking issue, if any>
files_skipped: []
scope_expansion_required:
  - path: <if applicable>
    reason: <if applicable>
next_step_suggestion: /vladyslav:write-project-docs
summary: |
  <1-3 sentence human-readable description of findings>
```

**`next_step_suggestion` rule:** if `overall_result` is PASS or WARN (no blockers) → `/vladyslav:write-project-docs`; if FAIL (blockers present) → empty string (user must fix blockers before proceeding).
````

## Apple review integration — why it's a hard gate

Apple BLOCKER/HIGH findings make the whole check FAIL even if tests/config/docs all pass. Reasoning: shipping an iOS build that will be rejected is worse than holding a release — rejection means a review cycle lost (typically a week) and a worse signal to Apple about the project. Better to catch it at this step than after upload.

If you find yourself wanting to override this — STOP. The right move is to fix the finding, not weaken the gate.
