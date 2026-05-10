---
name: init-project
description: Use when creating a new project from scratch. Interactive Q&A on stack, then scaffolds directories, docs, agents, and CLAUDE.md.
---

# Init Project

**Type:** Engineer

## Overview

Bootstrap a new project with full Claude Code structure. Pre-flight Q&A in Opus main collects decisions and stack choices, then a Sonnet subagent writes the entire scaffold in one pass.

Stack-specific instructions live in `references/stack-<name>.md` and are composed into the subagent prompt only for the stacks the user selected. File templates live in `assets/`.

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
   - If "other": ask via AskUserQuestion for label (e.g. "Rust backend"), directory name (e.g. `rust/`), and `.gitignore` entries (comma-separated).

4. **AskUserQuestion — frontend/mobile stacks** (multi-select):
   > "Frontend/mobile stacks? Select all that apply: flutter / swift / kotlin / other / none"
   - If "swift": ask via AskUserQuestion for Bundle ID prefix (e.g. `com.vlad`) and deployment target (default: `17.0`).
   - If "other": for each "other" stack, ask via AskUserQuestion for label, directory name, and `.gitignore` entries.

5. **AskUserQuestion — domain** (free text, optional):
   > "Project domain? (e.g. `api.myapp.com`) — press Enter to skip"

6. **AskUserQuestion — private mode** (yes/no):
   > "Private mode? Gitignore AI workflow files (CLAUDE.md, .claude/, docs/plans/)? (yes/no)"

7. **AskUserQuestion — agents to install** (multi-select from available list):
   > "Which agents to install in `.claude/agents/`? Select all that apply: architect-reviewer / backend-engineer / ios-engineer / qa-reviewer / release-manager / none"
   - `backend-engineer` is available only if a backend stack (python/go/other) was selected.
   - `ios-engineer` is available only if swift was selected.

8. **Compose dynamic allowlist.** Based on all answers above, enumerate every path the subagent may create. The allowlist must include every concrete path mentioned in the cross-stack subagent prompt below **plus** every concrete path mentioned in each composed `references/stack-<name>.md` fragment. The subagent rejects any write outside this list (`status: scope_expansion_required`).

### Step 1: Compose stack fragments (Opus main)

For each stack the user selected, read the corresponding `references/` file (relative to this skill directory) and concatenate the fragments into a single string, in this order:

1. `references/stack-python.md` — only if backend == `python`
2. `references/stack-go.md` — only if backend == `go`
3. `references/backend-shared.md` — only if backend in (`python`, `go`)
4. `references/stack-swift.md` — only if `swift` is in frontend/mobile stacks
5. `references/stack-flutter.md` — only if `flutter` is in frontend/mobile stacks
6. `references/stack-kotlin.md` — only if `kotlin` is in frontend/mobile stacks
7. `references/stack-other.md` — once per "other" stack (backend or frontend), with `<label>`, `<dir>`, `<gitignore_entries>` substituted from pre-flight

The concatenation is the value of `<STACK_FRAGMENTS>` in the subagent prompt. If no stacks were selected (all `none`), `<STACK_FRAGMENTS>` is the literal string `"(no stack-specific scaffolding requested)"`.

### Step 2: Dispatch to Sonnet subagent

Invoke the Agent tool with:
- `subagent_type: "general-purpose"`
- `model: "sonnet"`
- `description: "Bootstrap new project structure"`
- `prompt: <subagent prompt template below, filled with pre-flight outputs and composed STACK_FRAGMENTS>`

Wait for return.

### Step 3: Present summary

Pipe the subagent response through `<plugin>/scripts/parse-yaml-return.sh`. Then render the human-facing summary as specified in `<plugin>/skills/_shared/references/present-summary.md` (substitute `<skill-name>` → `init-project`). That reference defines the four `status` branches (`success`, `partial`, `scope_expansion_required`, `error`) verbatim — follow it without paraphrasing.

On `status: scope_expansion_required` and user approval, re-dispatch with an extended allowlist (add `scope_expansion_required[0].path`); reuse pre-flight outputs, do NOT re-run AskUserQuestion.

---

## Subagent prompt template

The full subagent prompt is composed by Opus main from these fragments, in order:

1. **Preamble** — verbatim contents of `<plugin>/skills/_shared/references/subagent-preamble.md` (substitute `<X>` → `init-project`).
2. **Project context** + **Task steps** — defined inline below.
3. **YAML return contract** — verbatim contents of `<plugin>/skills/_shared/references/yaml-return.md`.

Concatenate the three into a single string and pass as `prompt:` to the Agent tool.

The inline part of the prompt template (steps 2):

````
## Project context

Working directory: <pwd>
Project name: <project name from pre-flight>
Backend stack: <python | go | other (<label>, dir: <dir>, gitignore: <entries>) | none>
Frontend/mobile stacks: <flutter | swift | kotlin | other (<label>, dir: <dir>, gitignore: <entries>) | none — comma-separated>
Swift bundle ID prefix: <e.g. com.vlad — or N/A>
Swift deployment target: <e.g. 17.0 — or N/A>
Domain: <domain or "not specified">
Private mode: <yes | no>
Agents to install: <comma-separated list of agent names, or "none">

## Your task

Create the full Claude Code project scaffold. Rules and reporting contract are in the preamble (above) and YAML return block (at the end).

---

### Step 1: Base directories (cross-stack)

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

Stack-specific directories are added in Step 3 below.

### Step 2: Base `.gitignore` (cross-stack)

Write `.gitignore` with these base entries:

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

If `private mode = yes`, also append:

```
CLAUDE.md
.claude/
docs/plans/
docs/operations/
docs/marketing/
```

Stack-specific `.gitignore` lines are appended in Step 3 below.

### Step 3: Stack-specific scaffolding

Apply the following stack-specific instructions in order. Each fragment may add directories, append `.gitignore` entries, and create files. Treat each fragment as authoritative for its stack — do not improvise outside what it specifies.

<STACK_FRAGMENTS>

### Step 4: `CLAUDE.md`

Adapt content based on selected stacks:
- If backend: include API, Docker, DB references in the source-of-truth table.
- If mobile: include app structure references.
- If domain: include admin panel references.
- Always include the source-of-truth doc list and working rules.
- Always include the rule: **"Do not add translations until the finalization phase (pre-release-check)"**.

Template:

```markdown
# <ProjectName>

## Project Type

<domain if provided, else "to be filled">

## Stack

<one bullet per selected stack — for "other" stacks use the label and dir>

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

### Step 5: `.claude/settings.json`

```json
{
  "env": {
    "PROJECT_DOCS_ROOT": "docs"
  }
}
```

(`.claude/settings.local.json` is created by the Swift fragment in Step 3 if Swift was selected — do not duplicate it here.)

### Step 6: Agents

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

**`backend-engineer.md`** (only if a backend stack was selected):

```markdown
---
name: backend-engineer
description: Implements backend features following the project's API and DB schema
---

Read CLAUDE.md, docs/architecture/api.md, and docs/architecture/db-schema.sql before
implementing any feature. Follow existing patterns in backend/src/. Write or update
tests alongside implementation. Do not modify frontend/mobile code.
```

**`ios-engineer.md`** (only if swift was selected):

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

### Step 7: `docs/product/start-project.md` (discovery template)

Read `<plugin>/skills/init-project/assets/StartProject.md` and write to `docs/product/start-project.md`, replacing `<PROJECT_NAME>` in the first heading with the actual project name.

If the asset cannot be located, return `status: error`: `"Cannot find skills/init-project/assets/StartProject.md in vladyslav-skills plugin. Please reinstall or run git pull."` Do not fabricate the template.

### Step 8: `docs/design/system.md` (UI projects only)

Skip for backend-only / CLI projects. Run if ANY of these stacks were selected: `swift`, `kotlin`, `flutter`, or an "other" stack whose label mentions web/UI/frontend.

1. Create `docs/design/`.
2. Read `<plugin>/templates/DesignSystem.md` (this template lives at the repo root because it is shared with the `design-sync` skill).
3. Write to `docs/design/system.md`, replacing `<PROJECT_NAME>` and filling the "Platform & scope" section:
   - **Платформа:** selected stack (iOS / Flutter / Android / web / cross if multiple)
   - **Код source of truth:** `Assets.xcassets` (Swift), `tailwind.config.ts` (web), `ThemeData` (Flutter), `colors.xml + themes.xml` (Kotlin)
   - **Останній design-sync:** `<never>`
4. For non-iOS stacks, prepend at the top: `> NOTE: This template is iOS-leaning. Run /vladyslav:design-sync to adapt it to your stack's conventions.`

If the template cannot be located, return `status: error`: `"Cannot find templates/DesignSystem.md in vladyslav-skills plugin. Please reinstall or run git pull."`

### Step 9: Doc stubs

Create these files with TBD content (`# <Title>\n\n*to be filled*\n`):

```
docs/product/idea.md
docs/product/competitors.md
docs/product/prd.md
docs/product/user-stories.md
docs/architecture/system.md
docs/architecture/api.md         (skip if no backend)
docs/architecture/db-schema.sql  (skip if no backend)
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

`docs/operations/docker.md` is written with real content by the `backend-shared` fragment in Step 3 — skip it here if it already exists.

### Step 10: `ROADMAP.md` (only if features were provided)

The dispatch context may include a `roadmap_features` field. If it is non-empty, generate `ROADMAP.md` at the project root using this format:

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

Distribute features across phases based on description (MVP = core functionality, Post-MVP = enhancements). If `roadmap_features` is empty or not set, skip this step entirely — do not create `ROADMAP.md`.

### Step 11: Git init and initial commit

Run `<plugin>/scripts/init-git-repo.sh "<ProjectName>" .` — creates the repo if missing, makes one initial commit `chore: bootstrap <ProjectName>`. Idempotent: no-ops if a repo with commits already exists.

---

## Output allowlist

You may ONLY create or modify the files listed in the allowlist below (computed by pre-flight based on the user's stack choices):

<allowlist from pre-flight — one path per line>

Do NOT touch any file not in this list. If you determine that a file outside this list is needed — STOP, do NOT make the change, return `status: scope_expansion_required` with the path and reason. Set `next_step_suggestion: /vladyslav:discover`.
````
