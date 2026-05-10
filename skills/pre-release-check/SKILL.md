---
name: pre-release-check
description: Use before any production deployment. Verifies tasks, tests, configs, docs, translations, and iOS Apple-review readiness.
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

Pipe the subagent response through `<plugin>/scripts/parse-yaml-return.sh`. Then render the human-facing summary as specified in `<plugin>/skills/_shared/references/present-summary.md` (substitute `<skill-name>` → `pre-release-check`). That reference defines the four `status` branches (`success`, `partial`, `scope_expansion_required`, `error`) verbatim — follow it without paraphrasing.

On `status: scope_expansion_required` and user approval, re-dispatch with an extended allowlist (add `scope_expansion_required[0].path`); reuse pre-flight outputs, do NOT re-run AskUserQuestion.

---

## Subagent prompt template

The full subagent prompt is composed by Opus main from these fragments, in order:

1. **Preamble** — verbatim contents of `<plugin>/skills/_shared/references/subagent-preamble.md` (substitute `<X>` → `pre-release-check`).
2. **Project context** + **Task steps** — defined inline below.
3. **YAML return contract** — verbatim contents of `<plugin>/skills/_shared/references/yaml-return.md`.

Concatenate the three into a single string and pass as `prompt:` to the Agent tool.

The inline part of the prompt template (item 2):

````
Apply `superpowers:verification-before-completion` principles throughout: every check must produce actual output (test results, grep output, file contents). Do NOT claim PASS without running the command and seeing the result.

Rules and reporting contract are in the preamble (above) and YAML return block (at the end).

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

If `platform: ios`, read `<plugin>/skills/pre-release-check/references/ios-apple-check.md` and apply its checks in addition to the cross-platform checks above. The reference file is the canonical instruction set for this check — do NOT paraphrase.

For all non-iOS platforms (`web`, `backend`, `plugin`, `other`), skip Check 6 entirely and report `Apple review: N/A (not iOS)` in the summary.

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

Set `next_step_suggestion` in the YAML return: if `overall_result` is PASS or WARN (no blockers) → `/vladyslav:write-project-docs`; if FAIL (blockers present) → empty string (user must fix blockers before proceeding).
````

## Apple review integration

For the iOS Apple review check (Check 6) and rationale for it being a hard gate, see `<plugin>/skills/pre-release-check/references/ios-apple-check.md`.
