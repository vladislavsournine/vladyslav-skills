---
name: init-project
description: Use when creating a new project from scratch. Interactive Q&A on stack, then scaffolds directories, docs, agents, and CLAUDE.md.
---

# Init Project

**Type:** Engineer (light)

## Overview

Bootstrap a new project with a full Claude Code structure. Pre-flight Q&A in Opus main collects the user's choices, then `scripts/scaffold-project.sh` writes the entire scaffold in one second of pure bash — no Sonnet subagent, no LLM cost for the mechanical work.

This was a Heavy Engineer skill until v3.0.0. The Sonnet subagent dispatch spent ~8 minutes and ~43k tokens doing `mkdir` + `cp` + `sed` + `git init`. None of that needs LLM thinking, so it was lifted into `scripts/scaffold-project.sh`. The skill keeps the interactive part (where the user's input genuinely matters) and delegates everything else to bash.

## Process

### Step 0: Pre-flight (Opus main)

Collect every decision needed by the scaffolder. All Q&A happens here via AskUserQuestion.

1. **Verify working directory.** Run `ls -A`. If it is non-empty (anything other than `.git/` alone), ask:
   > "The current directory is not empty. Contents: `<list>`. Continue and add project structure here, or abort?"
   - If user chooses **abort** → exit cleanly. Do not call the script.
   - If user chooses **continue** → proceed. The scaffolder is idempotent and will skip existing files.

2. **AskUserQuestion — project name** (free text):
   > "What is the project called?"

3. **AskUserQuestion — backend stack** (single-select):
   > "Backend stack?"
   - Options: `python`, `go`, `other`, `none`
   - If `other`: ask three follow-ups via AskUserQuestion for `label`, `dir`, `gitignore` (comma-separated entries).

4. **AskUserQuestion — frontend/mobile stacks** (single-select for simplicity in v3.0.0; multi-select via AskUserQuestion had schema issues):
   > "Frontend/mobile stack?"
   - Options: `flutter`, `swift`, `kotlin`, `other`, `none`
   - If `swift`: ask via AskUserQuestion for `bundle ID prefix` (default `com.vlad`) and `deployment target` (default `17.0`).
   - If `other`: ask for `label`, `dir`, `gitignore`.

5. **AskUserQuestion — domain** (free text, optional):
   > "Project domain? (e.g. `api.myapp.com`) — type `none` to skip"

6. **AskUserQuestion — private mode** (single-select):
   > "Private mode? Gitignore AI workflow files (CLAUDE.md, .claude/, docs/plans/)?"
   - Options: `yes`, `no`

7. **AskUserQuestion — agents to install** (single-select per agent, run a small loop):
   For each of these in turn — ask `install <name>?` yes/no:
   - `architect-reviewer` (always available)
   - `backend-engineer` (only ask if backend stack ≠ `none`)
   - `ios-engineer` (only ask if `swift` was selected)
   - `qa-reviewer` (always available)
   - `release-manager` (always available)

   Collect the `yes` answers into a comma-separated string.

8. **Resolve the plugin root.** The scaffolder needs `<plugin-root>` to read `assets/`. Determine it by:
   - Glob for `~/.claude/plugins/cache/vladyslav-marketplace/vladyslav/*/scripts/scaffold-project.sh` and take the directory two levels up.
   - Fall back to `/Volumes/DevSSD/Development/vladyslav-skills` if Glob returns nothing (development clone).
   - Verify the resolved path has `skills/init-project/assets/` inside.

### Step 1: Run the scaffolder

Execute (via the Bash tool):

```bash
<plugin-root>/scripts/scaffold-project.sh \
    --pwd <project pwd from Step 0.1> \
    --name <name from Step 0.2> \
    --plugin-root <plugin-root from Step 0.8> \
    --backend <python|go|other|none> \
    [--backend-other-label "<label>"] \
    [--backend-other-dir <dir>] \
    [--backend-other-gitignore "<entries>"] \
    --frontend <flutter|swift|kotlin|other|none> \
    [--swift-bundle-id-prefix com.vlad] \
    [--swift-deployment-target 17.0] \
    [--frontend-other-label "<label>"] \
    [--frontend-other-dir <dir>] \
    [--frontend-other-gitignore "<entries>"] \
    --domain "<domain-or-empty>" \
    --private-mode <yes|no> \
    --agents "<comma list, or empty for none>"
```

The script emits a single line of JSON on stdout:

```json
{
  "status": "success" | "partial" | "error",
  "files_written": [<paths>],
  "files_skipped": [<paths>],
  "warnings": [<msgs>],
  "error": "<msg if status=error>"
}
```

Capture this output.

### Step 2: Present summary

Parse the JSON. Render to the user:

**`status: success`** (or `partial` with no skipped paths):

```
✓ init-project complete
  Project: <name> in <pwd>
  Stack: <human-readable summary, e.g. "Python backend, no frontend">
  Files written: <count> (see git log -1 for the manifest)
  Warnings: <warnings list, if any>
  Next: /vladyslav:discover  — fill docs/product/start-project.md with research
```

**`status: partial`** (with files_skipped non-empty — usually pre-existing files preserved):

Same as success, plus:
```
  Skipped (already existed): <list>
```

**`status: error`**:

```
✗ init-project failed
  Error: <error from JSON>
  Files written before failure: <list, if any>
```

Do not retry automatically. Surface the error.

---

## Why this is a Light Engineer skill

- **No subagent dispatch.** Heavy Engineer pattern's value is when each step requires reading existing code, semantic decisions, or narrative composition. Scaffolding a fresh project tree from user-provided parameters is none of that — it's pure mechanics.
- **Idempotent.** Re-running the script on an existing project will skip everything already present (returns those paths in `files_skipped`). Safe to re-run after manual changes.
- **Deterministic.** Same inputs always produce the same scaffold. No model variability.
- **~1 second, 0 LLM tokens** for the scaffold step itself. Q&A in Step 0 is the only model-driven part.

## Stack-specific scaffolding details

The bash scaffolder handles every stack inline. For developers debugging the script:
- Python backend logic: lines ~210-270 in `scripts/scaffold-project.sh`
- Go backend logic: lines ~272-340
- Swift frontend logic (xcodegen + Info.plist + App.swift): lines ~360-420
- Flutter / Kotlin / "other" frontends: lines ~422-460
- Shared backend infra (docker-compose, optional nginx with domain): lines ~340-358

The `references/stack-<name>.md` files from v2.3.x are retained for human reading and historical reference but are no longer composed into a subagent prompt — the same content is implemented directly in the bash scaffolder.

## Output allowlist (informational)

For users who need to audit what `init-project` may create. The scaffolder will only write to paths from this list (relative to the project pwd):

```
.gitignore
CLAUDE.md
.claude/settings.json
.claude/settings.local.json                    (Swift only)
.claude/agents/<chosen>.md                     (per agent selection)
docs/product/{idea,competitors,prd,user-stories,start-project}.md
docs/architecture/{system,api,db-schema.sql}.md   (api/db only if backend)
docs/architecture/adr/                            (empty dir)
docs/ux/{screens,flows}.md
docs/plans/{implementation,tasks,backlog-next}.md
docs/testing/{test-plan,manual-qa}.md
docs/release/{checklist,changelog,rollback}.md
docs/operations/{docker,incidents}.md             (docker only if backend)
docs/marketing/launch-notes.md
docs/design/system.md                              (UI projects only)
backend/{requirements.txt, src/{__init__.py, main.py}, Dockerfile, .env, .env.example, secrets/.gitkeep}   (Python backend)
backend/docker-compose{,prod,prod-selfhosted}.yml  (Python or Go backend)
backend/{go.mod, cmd/server/main.go, .air.toml, ...}   (Go backend)
infra/nginx/nginx.conf                              (backend + domain)
project.yml, app/Info.plist, app/<Name>App.swift, app/ContentView.swift   (Swift)
flutter/.gitkeep                                    (Flutter)
kotlin/.gitkeep                                     (Kotlin)
<other-dir>/.gitkeep                                ("other" stacks)
```

The scaffolder never modifies pre-existing files — it skips them and reports the path in `files_skipped`.
