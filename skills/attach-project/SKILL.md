---
name: attach-project
description: Use when adding Claude Code structure to an existing project - auto-detects stack, creates missing docs and agents, never overwrites existing files
---

# Attach Project

## Overview

Add Claude Code structure to an existing project. Never overwrites existing files. Auto-detects stacks.

**Recommended model:** Sonnet (`vd-attach` command uses it automatically)

## Process

### Step 1: Verify project root

Check that current directory has `.git/` or recognizable project files. If not, warn the user.

### Step 2: Auto-detect stacks

Scan for existing files to detect stacks:

| File | Stack |
|------|-------|
| `requirements.txt` or `pyproject.toml` | python |
| `go.mod` | go |
| `pubspec.yaml` | flutter |
| `Package.swift` or `*.xcodeproj` | swift |
| `build.gradle` or `build.gradle.kts` | kotlin |

Report what was detected.

### Step 3: Gather additional requirements

Ask using AskUserQuestion:

1. **Additional stacks** — want to add any stacks not detected? (multi-select: python/go/flutter/swift/kotlin/other/none)
   - If "other": for each, ask for label, directory name, .gitignore entries
2. **Domain** — optional, press Enter to skip
3. **Private mode** — gitignore AI workflow files?

### Step 4: Create missing structure

Follow the same creation logic as init-project, but:
- **Check before every file/directory** — skip if exists
- **Append to .gitignore** — never overwrite, only add missing entries
- **CLAUDE.md** — only create if missing
- **Agents** — only copy if individual agent file doesn't exist

### Step 5: Finish

```
✓ Claude structure attached.

Next steps:
1. Review and update CLAUDE.md with project-specific details
2. Run: vd-analyze to analyze existing code and fill architecture docs

Remember:
- Do NOT add translations until vd-release phase
- /exit to close this session
```
