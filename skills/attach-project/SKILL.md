---
name: attach-project
description: Use when adding Claude Code structure to an existing project. Auto-detects stack, creates only missing files.
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

Pipe the subagent response through `<plugin>/scripts/parse-yaml-return.sh`. Then render the human-facing summary as specified in `<plugin>/skills/_shared/references/present-summary.md` (substitute `<skill-name>` → `attach-project`). That reference defines the four `status` branches (`success`, `partial`, `scope_expansion_required`, `error`) verbatim — follow it without paraphrasing.

On `status: scope_expansion_required` and user approval, re-dispatch with an extended allowlist (add `scope_expansion_required[0].path`); reuse pre-flight outputs, do NOT re-run AskUserQuestion.

---

## Subagent prompt template

The full subagent prompt is composed by Opus main from these fragments, in order:

1. **Preamble** — verbatim contents of `<plugin>/skills/_shared/references/subagent-preamble.md` (substitute `<X>` → `attach-project`).
2. **Project context** + **Task steps** — defined inline below.
3. **YAML return contract** — verbatim contents of `<plugin>/skills/_shared/references/yaml-return.md`.

Concatenate the three into a single string and pass as `prompt:` to the Agent tool.

The inline part of the prompt template (item 2):

````
## Project context

Working directory: <pwd>
Detected stacks: <auto-detected stacks from pre-flight>
Additional stacks chosen by user: <additional stacks>
Other stacks (user-defined): <label, directory, .gitignore entries per stack — or "none">
Domain: <domain entered by user, or "not specified">
Private mode: <yes/no>

## Your task

Create missing Claude Code structure for this project. Rules and reporting contract are in the preamble (above) and YAML return block (at the end).

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

Do NOT touch any file not in this list. If you determine that a file outside this list is needed — STOP, do NOT make the change, return `status: scope_expansion_required` with the path and reason. Set `next_step_suggestion: /vladyslav:analyze-project` in the YAML return.
````
