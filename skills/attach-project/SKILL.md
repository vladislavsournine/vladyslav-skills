---
name: attach-project
description: Use when adding Claude Code structure to an existing project - auto-detects stack, creates missing docs and agents, never overwrites existing files
---

# Attach Project

## Overview

Add Claude Code structure to an existing project. Never overwrites existing files. Auto-detects stacks.

**Type:** Engineer

## Process

### Step 0: Pre-flight (Opus main)

Interactive checks and setup before dispatching the subagent.

1. **Verify project root.** Check that `pwd` contains `.git/` or at least one recognizable project file:
   - `requirements.txt` or `pyproject.toml` — python
   - `go.mod` — go
   - `pubspec.yaml` — flutter
   - `Package.swift` or `*.xcodeproj` — swift
   - `build.gradle` or `build.gradle.kts` — kotlin
   - `package.json` — node/js

   If none of the above are found → STOP: "Not a project root — confirm the path or initialize git first".

2. **Auto-detect stacks.** Report detected stacks to the user:

   | File | Stack |
   |------|-------|
   | `requirements.txt` or `pyproject.toml` | python |
   | `go.mod` | go |
   | `pubspec.yaml` | flutter |
   | `Package.swift` or `*.xcodeproj` | swift |
   | `build.gradle` or `build.gradle.kts` | kotlin |

3. **AskUserQuestion — additional stacks** (multi-select):
   > "Detected stacks: `<detected>`. Want to add any stacks not detected?"
   > Options: python / go / flutter / swift / kotlin / other / none

4. **If "other" selected** → for each "other" stack, AskUserQuestion:
   - Label (e.g. "Rust backend")
   - Directory name (e.g. `rust/`)
   - .gitignore entries to add (comma-separated)

5. **AskUserQuestion — domain** (free-text, optional):
   > "What is the project domain? (e.g. 'iOS fitness app', 'Python data pipeline') — press Enter to skip"

6. **AskUserQuestion — private mode** (yes/no):
   > "Private mode? Gitignore AI workflow files (CLAUDE.md, .claude/, docs/)? (yes/no)"

7. **Compose dynamic allowlist** based on the answers above. The allowlist is the union of:
   - `CLAUDE.md` — only if it does not already exist
   - `.gitignore` — always included (append-only, never overwrite)
   - `.claude/agents/*.md` — only individual agent files that do not already exist
   - Per detected + selected stack directories and scaffolding files (e.g. `python/`, `go/`, `flutter/`, `swift/`, `kotlin/`, plus any "other" stack directories)
   - If private mode = no: `docs/architecture/system.md`, `docs/product/prd.md`, `docs/plans/tasks.md` — only files that do not already exist

   Scan the filesystem now and exclude any path that already exists, producing the final allowlist of files the subagent may create or modify.

8. **Pass to subagent:** detected stacks, additional stacks, "other" stack details, domain, private mode, project root path, final computed allowlist.

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Create missing Claude Code structure for the project"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs>`

Wait for return.

### Step 2: Present summary

Parse the YAML block in the subagent's response. Look for the last fenced ` ```yaml ` block. Treat as parse failure (status: unknown) if: (a) no ` ```yaml ` block is found, (b) the block does not contain a `status:` field, OR (c) the YAML is malformed (e.g., unbalanced indentation).

**If parse fails** → print the full subagent output, run `git status --short`, tell user: "Subagent returned unstructured response. Files on disk: `<git status>`. Review manually."

**If parse succeeds**, render based on `status`:

`status: success` →
```
✓ Engineer summary (attach-project)
  Wrote: <files_written paths joined>
  Skipped (already existed): <files_skipped paths joined>
  Warnings: <warnings, if any>
  Files unstaged. Review before commit.
  Next: <next_step_suggestion>
```

`status: partial` → same as success plus:
```
  Note: <files_skipped> were not created. See warnings.
```

`status: scope_expansion_required` →
```
⚠ Engineer halted (attach-project)
  Subagent wanted to modify <path> (outside allowlist).
  Reason: <reason>

  Options:
    1. Approve — re-dispatch with extended allowlist
    2. Skip — leave file untouched
    3. Abort
```
Wait for user choice. On (1), re-dispatch: take the same subagent prompt template from Step 1, add the path from `scope_expansion_required[0].path` (and any additional entries) to the Output allowlist section of the prompt, re-invoke the Agent tool with this updated prompt and the same other parameters. Reuse pre-flight outputs already in memory — do NOT re-scan the filesystem. On (2), record the skipped path and proceed to next step. On (3), exit cleanly with no further action.

`status: error` →
```
✗ Engineer failed (attach-project)
  Error: <error message>
```
---

## Subagent prompt template

````
You are a Sonnet subagent dispatched by the `attach-project` skill in the `vladyslav-skills` plugin. You have no conversation history with the user — this prompt is your full briefing.

## Project context

Working directory: <pwd>
Detected stacks: <auto-detected stacks from pre-flight>
Additional stacks chosen by user: <additional stacks>
Other stacks (user-defined): <label, directory, .gitignore entries per stack — or "none">
Domain: <domain entered by user, or "not specified">
Private mode: <yes/no>

## Your task

Create missing Claude Code structure for this project. Apply the following rules without exception:

1. **Skip every file that already exists.** Pre-flight has already computed the allowlist to include only non-existing files, but if you encounter an existing file while writing — stop and skip it. Never overwrite.
2. **`.gitignore` is append-only.** Read the existing `.gitignore` content first. Identify which entries are already present. Add ONLY the missing entries for the detected stacks at the end. Never remove or rewrite existing lines.
3. **`CLAUDE.md`** — create only if absent (pre-flight checks this; it will appear in allowlist only if missing).
4. **`.claude/agents/`** — create only the individual agent files that do not already exist.

### Files to create (based on stacks)

For each detected/selected stack, create the standard Claude Code scaffold:

- **python:** `python/` directory; standard python entries in `.gitignore` (`__pycache__/`, `*.pyc`, `.venv/`, `dist/`, `*.egg-info/`)
- **go:** `go/` directory; standard go entries in `.gitignore` (`/bin/`, `*.exe`, `*.test`, `*.out`)
- **flutter:** `flutter/` directory; standard flutter entries in `.gitignore` (`.dart_tool/`, `build/`, `.flutter-plugins`, `.flutter-plugins-dependencies`)
- **swift:** `swift/` or `ios/` directory; standard swift/xcode entries in `.gitignore` (`.build/`, `*.xcuserstate`, `DerivedData/`, `*.ipa`, `Pods/`)
- **kotlin/android:** `android/` directory; standard android entries in `.gitignore` (`*.apk`, `*.aab`, `local.properties`, `.gradle/`, `build/`)
- **other (user-defined):** `<directory name from user>` directory; `.gitignore` entries supplied by user

For `CLAUDE.md` (if absent), use this template:
```markdown
# <project name from directory>

## Project Type

<domain if provided, else: "to be filled">

## Stack

<detected + added stacks>

## Source of Truth

| Doc | Purpose |
|-----|---------|
| `docs/architecture/system.md` | Architecture overview |
| `docs/product/prd.md` | Product requirements |
| `docs/plans/tasks.md` | Active tasks |

## Working Rules

- <add project-specific rules here>
```

For `docs/` structure (if private mode = no), create stubs only for files that do not exist:
- `docs/architecture/system.md` → `# System Architecture\n\n*to be filled*\n`
- `docs/product/prd.md` → `# Product Requirements\n\n*to be filled*\n`
- `docs/plans/tasks.md` → `# Tasks\n\n*to be filled*\n`

For `.claude/agents/` (create directory if missing; create each agent stub only if the individual file is absent):
- `docs-agent.md` — documentation agent
- `code-review-agent.md` — code review agent

## Output allowlist

You may ONLY create or modify the files listed in the allowlist below (computed by pre-flight based on the user's stack choices and filesystem state):

<allowlist from pre-flight — one path per line>

Do NOT touch any file not in this list. If you determine that a file outside this list is needed — STOP, do NOT make the change, return `status: scope_expansion_required` with the path and reason.

## Required return format

End your response with EXACTLY one YAML block:

```yaml
status: success | partial | scope_expansion_required | error
files_written:
  - path: <path>
    action: created | modified
files_skipped:
  - <paths that already existed and were skipped>
warnings:
  - <non-blocking issue, if any>
scope_expansion_required:
  - path: <if applicable>
    reason: <if applicable>
next_step_suggestion: /vladyslav:analyze-project
summary: |
  <1-3 sentence human-readable description>
```
````
