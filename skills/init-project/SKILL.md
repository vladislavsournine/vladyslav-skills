---
name: init-project
description: Use when creating a new project from scratch - interactive setup that creates directories, configs, docs, agents, and CLAUDE.md based on chosen stacks (python/go/flutter/swift/kotlin or custom "other" stacks)
---

# Init Project

## Overview

Bootstrap a new project with full Claude Code structure. Asks questions, then creates everything.

**Type:** Engineer

## Process

### Step 0: Pre-flight (Opus main)

Interactive setup and decision-gathering before dispatching the subagent.

1. **Verify working directory.** Run `ls -A` to check the current directory contents. If it is non-empty (anything other than `.git/` alone), ask via AskUserQuestion:
   > "The current directory is not empty. Contents: `<list>`. Continue and add project structure here, or abort?"
   - If user chooses abort → exit cleanly, no dispatch.
   - If user continues → proceed.

2. **AskUserQuestion — project name** (free text):
   > "What is the project called?"

3. **AskUserQuestion — backend stack** (single-select):
   > "Backend stack? Choose one: python / go / other / none"
   - If "other": ask via AskUserQuestion for label (e.g. "Rust backend"), directory name (e.g. `rust/`), and .gitignore entries (comma-separated).

4. **AskUserQuestion — frontend/mobile stacks** (multi-select):
   > "Frontend/mobile stacks? Select all that apply: flutter / swift / kotlin / other / none"
   - If "swift": ask via AskUserQuestion for Bundle ID (e.g. `com.vlad.AppName`) and deployment target (default: `17.0`).
   - If "other": for each "other" stack, ask via AskUserQuestion for label, directory name, and .gitignore entries.

5. **AskUserQuestion — domain** (free text, optional):
   > "Project domain? (e.g. `api.myapp.com`) — press Enter to skip"

6. **AskUserQuestion — private mode** (yes/no):
   > "Private mode? Gitignore AI workflow files (CLAUDE.md, .claude/, docs/plans/)? (yes/no)"

7. **AskUserQuestion — agents to install** (multi-select from available list):
   > "Which agents to install in `.claude/agents/`? Select all that apply: architect-reviewer / backend-engineer / ios-engineer / qa-reviewer / release-manager / none"
   - `backend-engineer` is available only if a backend stack (python/go/other) was selected.
   - `ios-engineer` is available only if swift was selected.

8. **Compose dynamic allowlist.** Based on all answers above, enumerate every path the subagent may create. This includes:
   - `CLAUDE.md`
   - `.gitignore`
   - `.claude/settings.json`
   - `.claude/agents/<agent>.md` for each chosen agent
   - `docs/` subdirectories and stub files (see subagent task for full list)
   - `docs/product/start-project.md`
   - Per backend stack: `backend/` tree (requirements.txt, src/, etc.) or go equivalent
   - If domain set and backend present: `infra/nginx/nginx.conf`
   - Per mobile/frontend stack: `flutter/`, `swift/`, `kotlin/` directories
   - Per "other" stack: user-specified directory
   - If swift: `project.yml`, `app/`, `app/Resources/`, `tests/`, `app/Info.plist`, `app/<name>App.swift`, `app/ContentView.swift`, `.claude/settings.local.json`
   - If UI stacks: `docs/design/system.md`
   - `ROADMAP.md` (conditional — only if user provides features in Step 9.5; include speculatively)

9. **Pass to subagent:** project name, backend stack (+ "other" stack details), frontend/mobile stacks, Swift bundle ID and deployment target (if applicable), domain, private mode, agents chosen, working directory path, dynamic allowlist.

### Step 1: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Bootstrap new project structure"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs>`

Wait for return.

### Step 2: Present summary

Parse the YAML block in the subagent's response. Look for the last fenced ` ```yaml ` block. Treat as parse failure (status: unknown) if: (a) no ` ```yaml ` block is found, (b) the block does not contain a `status:` field, OR (c) the YAML is malformed.

**If parse fails** → print the full subagent output, run `git status --short`, tell user: "Subagent returned unstructured response. Files on disk: `<git status>`. Review manually."

**If parse succeeds**, render based on `status`:

`status: success` →
```
✓ Engineer summary (init-project)
  Wrote: <files_written paths joined>
  Skipped: <files_skipped, if any>
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
⚠ Engineer halted (init-project)
  Subagent wanted to modify <path> (outside allowlist).
  Reason: <reason>

  Options:
    1. Approve — re-dispatch with extended allowlist
    2. Skip — leave file untouched
    3. Abort
```
Wait for user choice. On (1), re-dispatch: add the path from `scope_expansion_required[0].path` to the allowlist in the subagent prompt and re-invoke the Agent tool. Reuse pre-flight outputs already in memory — do NOT re-run AskUserQuestion. On (2), record the skipped path and proceed. On (3), exit cleanly.

`status: error` →
```
✗ Engineer failed (init-project)
  Error: <error message>
```
Best-effort: invoke `vladyslav:stash` skill with `source: "init-project:error"`, `task: "Init project"`, `open_question: "Subagent failed: <error>"`. If stash itself fails, log warning, continue.

---

## Subagent prompt template

````
You are a Sonnet subagent dispatched by the `init-project` skill in the `vladyslav-skills` plugin. You have no conversation history with the user — this prompt is your full briefing. Do NOT call AskUserQuestion — all decisions have already been made in pre-flight.

## Project context

Working directory: <pwd>
Project name: <project name from pre-flight>
Backend stack: <python | go | other (<label>, dir: <dir>, gitignore: <entries>) | none>
Frontend/mobile stacks: <flutter | swift | kotlin | other (<label>, dir: <dir>, gitignore: <entries>) | none — comma-separated>
Swift bundle ID: <bundle ID or N/A>
Swift deployment target: <e.g. 17.0 or N/A>
Domain: <domain or "not specified">
Private mode: <yes | no>
Agents to install: <comma-separated list of agent names, or "none">

## Your task

Create the full Claude Code project scaffold. Follow these rules without exception:

1. **Allowlist enforcement:** Only create or modify files listed in the Output allowlist section below. If you determine a file outside the allowlist is needed — STOP, do NOT make the change, return `status: scope_expansion_required` with the path and reason.
2. **No AskUserQuestion.** All decisions have been made. Do not prompt the user for anything.
3. **Git init and initial commit** at the end (Step 10 below).

---

### Step 1: Create directories

Always create:
```
.claude/agents/
docs/product/
docs/architecture/adr/
docs/ux/
docs/plans/
docs/testing/
docs/release/
docs/operations/
docs/marketing/
```

If backend is python or go:
```
backend/admin/
backend/src/
backend/migrations/
backend/secrets/
```

If domain is set and backend is python/go:
```
infra/nginx/
```

For each mobile/frontend stack:
```
flutter/    # if flutter
swift/      # if swift
kotlin/     # if kotlin
```

For each "other" stack (backend or frontend):
```
<user-specified-dir>/
```

---

### Step 2: Create `.gitignore`

Write `.gitignore` with base entries:
```
.DS_Store
.AppleDouble
.idea/
.vscode/
*.swp
*.swo
.claude/settings.local.json
.env
.env.*
!.env.example
secrets/
*.log
logs/
build/
dist/
coverage/
```

Add stack-specific entries:

**Python:** `__pycache__/`, `*.pyc`, `.venv/`

**Go:** `/tmp/`, `vendor/`

**Flutter:** `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, `.packages`, `*.iml`, `.metadata`

**Swift:**
```
DerivedData/
*.xcuserstate
*.xcworkspace/xcuserdata/
*.xcodeproj/
Pods/
```
Note: `.xcodeproj/` is gitignored because it is generated by xcodegen from `project.yml`. Only `project.yml` is committed.

**Kotlin:** `.gradle/`, `out/`

For each "other" stack: add the user-specified .gitignore entries (comma-separated list from pre-flight).

If private mode = yes, append:
```
CLAUDE.md
.claude/
docs/plans/
docs/operations/
docs/marketing/
```

---

### Step 3: xcodegen setup (Swift only)

**Only if swift was selected:**

**Install xcodegen if missing:**
```bash
which xcodegen || brew install xcodegen
```

**Create `project.yml`:** Read `templates/swift/project.yml` from the plugin directory (located via the same pattern as `templates/StartProject.md` — find vladyslav-skills plugin directory via `~/.claude/plugins/` or the directory where this skill was loaded from). Write it to `project.yml` in the project root, replacing:
- `PROJECT_NAME` → actual project name
- `BUNDLE_ID_PREFIX` → bundle ID prefix from pre-flight (e.g. `com.vlad`)
- `PROJECT_NAME_LOWER` → lowercased project name
- `DEPLOYMENT_TARGET` → deployment target from pre-flight (default: `17.0`)

If `templates/swift/project.yml` cannot be located, stop: "Cannot find templates/swift/project.yml in vladyslav-skills plugin. Please reinstall or run `git pull`." Return `status: error`.

**Create source directories:** `app/`, `app/Resources/`, `tests/`

**Create `app/Info.plist`:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UILaunchScreen</key>
    <dict/>
</dict>
</plist>
```

**Create `app/<ProjectName>App.swift`** (replace `<ProjectName>` with actual project name):
```swift
import SwiftUI

@main
struct <ProjectName>App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Create `app/ContentView.swift`:**
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

**Create `.claude/settings.local.json`** (allow build tools):
```json
{
  "permissions": {
    "allow": ["Bash(xcodegen:*)", "Bash(xcodebuild:*)"]
  }
}
```

**Generate the project:**
```bash
xcodegen generate
```

Confirm `.xcodeproj` was created. If xcodegen fails, return `status: error` with the error message.

---

### Step 4: Create backend files (if python or go)

**For python — create:**

`backend/requirements.txt`:
```
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
gunicorn>=23.0.0
psycopg2-binary>=2.9.9
redis>=5.0.0
```

`backend/src/__init__.py`: empty file

`backend/src/main.py`:
```python
from fastapi import FastAPI

app = FastAPI(title="<ProjectName>")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def root():
    return {"status": "running"}
```
Replace `<ProjectName>` with the actual project name.

`backend/Dockerfile`: multi-stage with dev (uvicorn --reload) and prod (gunicorn) targets.

`backend/.env.example`: APP_ENV, APP_PORT, APP_SECRET_KEY, DATABASE_URL, REDIS_URL. If domain set: add APP_DOMAIN, ADMIN_URL, GOOGLE_CLIENT_ID/SECRET. If no domain: APP_DOMAIN=localhost.

`backend/.env`: stub with comment `# DO NOT COMMIT — copy .env.example and fill values`.

`backend/secrets/.gitkeep`: empty file.

**Docker compose files** — read each from the plugin's `templates/backend/` directory and write to `backend/`:
- `templates/backend/docker-compose.yml` → `backend/docker-compose.yml` (no substitutions)
- `templates/backend/docker-compose.prod.yml` → `backend/docker-compose.prod.yml`
  - If no domain: remove the `certbot` service and `certbot_*` volumes; nginx uses port 80 only
- `templates/backend/docker-compose.prod-selfhosted.yml` → `backend/docker-compose.prod-selfhosted.yml`
  - Same certbot rule applies

If any template cannot be located, return `status: error`: "Cannot find templates/backend/<name> in vladyslav-skills plugin. Please reinstall or run `git pull`."

**For go — create:**

`backend/go.mod`, `backend/cmd/server/main.go`, `backend/.air.toml` — Go equivalents of the Python files above.

---

### Step 4b: Create Docker operations doc (if backend is python or go)

Read `templates/docs/operations/docker.md` from the plugin directory and write to `docs/operations/docker.md` (no substitutions).

---

### Step 5: Create nginx config (if domain set and backend is python/go)

Read `templates/infra/nginx.conf` from the plugin directory. Write to `infra/nginx/nginx.conf`, replacing every occurrence of `APP_DOMAIN` with the actual domain.

---

### Step 6: Create `CLAUDE.md`

Adapt content based on stacks:
- If backend: include API, Docker, DB references
- If mobile: include app structure references
- If domain: include admin panel references
- Always include: source of truth doc list, working rules
- Always include rule: **"Do not add translations until the finalization phase (pre-release-check)"**

Template:
```markdown
# <ProjectName>

## Project Type

<domain if provided, else "to be filled">

## Stack

<list of selected stacks>

## Source of Truth

| Doc | Purpose |
|-----|---------|
| `docs/product/prd.md` | Product requirements |
| `docs/product/user-stories.md` | User stories |
| `docs/architecture/system.md` | Architecture overview |
| `docs/plans/tasks.md` | Active tasks |
<!-- add docs/architecture/api.md if backend present -->
<!-- add docs/architecture/db-schema.sql if backend present -->

## Working Rules

- Do not add translations until the finalization phase (pre-release-check)
- <add project-specific rules here>
```

---

### Step 7: Create `.claude/settings.json`

```json
{
  "env": {
    "PROJECT_DOCS_ROOT": "docs"
  }
}
```

(Only create this file; `.claude/settings.local.json` is created in Step 3 for Swift projects.)

---

### Step 8: Create agents

For each agent in the chosen agents list, write the corresponding `.md` file to `.claude/agents/`:

**`architect-reviewer.md`:**
```markdown
---
name: architect-reviewer
description: Reviews changes against PRD, architecture docs, and active tasks
---

Read CLAUDE.md and the source-of-truth docs listed there before reviewing any change.
Verify the change aligns with the PRD, doesn't violate architecture decisions, and
updates docs/plans/tasks.md if the change closes a task.
```

**`backend-engineer.md`** (only if backend stack selected):
```markdown
---
name: backend-engineer
description: Implements backend features following the project's API and DB schema
---

Read CLAUDE.md, docs/architecture/api.md, and docs/architecture/db-schema.sql before
implementing any feature. Follow existing patterns in backend/src/. Write or update
tests alongside implementation. Do not modify frontend/mobile code.
```

**`ios-engineer.md`** (only if swift selected):
```markdown
---
name: ios-engineer
description: Implements iOS features following SwiftUI conventions and project architecture
---

Read CLAUDE.md and docs/architecture/system.md before implementing any feature.
Follow SwiftUI best practices. Use only tokens defined in docs/design/system.md.
Do not hard-code colors, fonts, or spacing. Support Dark Mode and Dynamic Type.
```

**`qa-reviewer.md`:**
```markdown
---
name: qa-reviewer
description: Generates test scenarios and QA plans from PRD and user stories
---

Read CLAUDE.md, docs/product/prd.md, and docs/product/user-stories.md.
Generate test scenarios covering happy path, error cases, edge cases, and empty states.
Write to docs/testing/ files.
```

**`release-manager.md`:**
```markdown
---
name: release-manager
description: Prepares release documentation and runs pre-release checklist
---

Read CLAUDE.md, docs/plans/tasks.md, docs/testing/manual-qa.md, and
docs/release/checklist.md. Verify all tasks are complete, tests pass, and
docs are up to date. Update docs/release/changelog.md with the release summary.
```

---

### Step 8.5: Write StartProject.md discovery template

Find the vladyslav-skills plugin directory and read `templates/StartProject.md`. Write to `docs/product/start-project.md`, replacing `<PROJECT_NAME>` in the first heading with the actual project name.

If `templates/StartProject.md` cannot be located, return `status: error`: "Cannot find templates/StartProject.md in vladyslav-skills plugin. Please reinstall or run `git pull`." Do not fabricate the template.

---

### Step 8.6: Write DesignSystem.md (UI projects only)

**Skip for backend-only / CLI projects.** Run if ANY of these stacks were selected: `swift`, `kotlin`, `flutter`, or an "other" stack whose label mentions web/UI/frontend.

1. Create `docs/design/` directory.
2. Find the plugin directory and read `templates/DesignSystem.md`.
3. Write to `docs/design/system.md`, replacing `<PROJECT_NAME>` and filling the "Platform & scope" section:
   - **Платформа:** selected stack (iOS / Flutter / Android / web / cross if multiple)
   - **Код source of truth:** `Assets.xcassets` (Swift), `tailwind.config.ts` (web), `ThemeData` (Flutter), `colors.xml + themes.xml` (Kotlin)
   - **Останній design-sync:** `<never>`
4. For non-iOS stacks, add at the top: `> NOTE: This template is iOS-leaning. Run /vladyslav:design-sync to adapt it to your stack's conventions.`

If `templates/DesignSystem.md` cannot be located, return `status: error`: "Cannot find templates/DesignSystem.md in vladyslav-skills plugin. Please reinstall or run `git pull`." Do not fabricate.

---

### Step 9: Create doc stubs

Create these files with TBD content (`# <Title>\n\n*to be filled*\n`):
```
docs/product/idea.md
docs/product/competitors.md
docs/product/prd.md
docs/product/user-stories.md
docs/architecture/system.md
docs/architecture/api.md        (skip if no backend)
docs/architecture/db-schema.sql (skip if no backend)
docs/ux/screens.md
docs/ux/flows.md
docs/plans/implementation.md
docs/plans/tasks.md
docs/plans/backlog-next.md
docs/testing/test-plan.md
docs/testing/manual-qa.md
docs/release/checklist.md
docs/release/changelog.md
docs/release/rollback.md
docs/operations/incidents.md
docs/marketing/launch-notes.md
```

> `docs/operations/docker.md` is written with real content in Step 4b — skip it here.

---

### Step 9.5: Roadmap (if features provided)

The pre-flight dispatch context will include a `roadmap_features` field. If it is non-empty, generate `ROADMAP.md` at the project root using this format:

```markdown
# Roadmap: <Project Name>

> Created: <today's date YYYY-MM-DD>

## Phase 1: MVP
**Done when:** <one sentence criteria>

- [ ] <Feature from user>
- [ ] <Feature from user>

## Phase 2: Post-MVP
**Done when:** <one sentence criteria>

- [ ] <Feature from user>
<!-- Add Phase 3, 4… as needed — one phase per logical milestone -->
```

Distribute features across phases based on their description (MVP = core functionality, Post-MVP = enhancements). If `roadmap_features` is empty or not set, skip this step and do not create `ROADMAP.md`.

---

### Step 10: Git init and commit

```bash
git init
git add -A
git commit -m "chore: bootstrap <ProjectName>"
```

---

## Output allowlist

You may ONLY create or modify the files listed in the allowlist below (computed by pre-flight based on the user's stack choices):

<allowlist from pre-flight — one path per line>

Do NOT touch any file not in this list. If you determine that a file outside this list is needed — STOP, do NOT make the change, return `status: scope_expansion_required` with the path and reason.

---

## Required return format

End your response with EXACTLY one YAML block:

```yaml
status: success | partial | scope_expansion_required | error
files_written:
  - path: <path>
    action: created | modified
files_skipped:
  - <paths that were skipped, if any>
warnings:
  - <non-blocking issue, if any>
scope_expansion_required:
  - path: <if applicable>
    reason: <if applicable>
next_step_suggestion: /vladyslav:discover
summary: |
  <1-3 sentence human-readable description>
```
````
