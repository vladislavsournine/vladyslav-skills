---
name: init-project
description: Use when creating a new project from scratch - interactive setup that creates directories, configs, docs, agents, and CLAUDE.md based on chosen stacks (python/go/flutter/swift/kotlin or custom "other" stacks)
---

# Init Project

## Overview

Bootstrap a new project with full Claude Code structure. Asks questions, then creates everything.

**Recommended model:** Sonnet (`vd-init` command uses it automatically)

## Process

### Step 1: Gather requirements

Ask these questions one at a time using the AskUserQuestion tool:

1. **Project name** — what is the project called?
2. **Backend stack** — python (default) / go / other / none
   - If "other": ask for label (e.g. "Go + Nakama"), directory name (e.g. `server/`), .gitignore entries (optional)
3. **Frontend/mobile stacks** — flutter / swift / kotlin / other / none (multi-select)
   - If "other": for each, ask for label (e.g. "React"), directory name (e.g. `frontend/`), .gitignore entries (optional)
4. **Domain** — optional, skip if no backend selected. Press Enter to skip.
5. **Private mode** — gitignore AI workflow files? (CLAUDE.md, .claude/, docs/plans/)

### Step 2: Create directories

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

If domain is set:
```
infra/nginx/
```

For each mobile/frontend stack selected:
```
flutter/    # if flutter
swift/      # if swift
kotlin/     # if kotlin
```

For each "other" stack:
```
<user-specified-dir>/    # e.g. frontend/, web/, game-server/
```

**"Other" stack handling:**
- Create the user-specified directory
- Add user-specified .gitignore entries (if any)
- Add to CLAUDE.md with the user-provided label
- Create doc stubs referencing the label
- Do NOT generate Dockerfile, docker-compose, or starter code — user sets up themselves

### Step 3: Create .gitignore

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

**Python:**
```
__pycache__/
*.pyc
.venv/
```

**Go:**
```
/tmp/
vendor/
```

**Flutter:**
```
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
*.iml
.metadata
```

**Swift:**
```
DerivedData/
*.xcuserstate
*.xcworkspace/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/
Pods/
```

**Kotlin:**
```
.gradle/
out/
```

If private mode:
```
# AI workflow (private mode)
CLAUDE.md
.claude/
docs/plans/
docs/operations/
docs/marketing/
```

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

app = FastAPI(title="PROJECT_NAME")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def root():
    return {"status": "running"}
```

`backend/Dockerfile`: multi-stage with dev (uvicorn --reload) and prod (gunicorn) targets.

`backend/docker-compose.yml`: app + postgres + redis + adminer services.

`backend/docker-compose.prod.yml`: app + nginx, no local DB (use managed services).

`backend/.env.example`: APP_ENV, APP_PORT, APP_SECRET_KEY, DATABASE_URL, REDIS_URL. If domain set: add APP_DOMAIN, ADMIN_URL, GOOGLE_CLIENT_ID/SECRET. If no domain: APP_DOMAIN=localhost.

`backend/.env`: stub with "DO NOT COMMIT" comment.

`backend/secrets/.gitkeep`: empty.

**For go — create:**

`backend/go.mod`, `backend/cmd/server/main.go`, `backend/.air.toml` — Go equivalents of above.

### Step 5: Create nginx config (if domain set)

Only if backend is python/go AND domain is provided.

`infra/nginx/nginx.conf`: reverse proxy with API and admin subdomains.

### Step 6: Create CLAUDE.md

Adapt content based on stacks:
- If backend: include API, Docker, DB references
- If mobile: include app structure references
- If domain: include admin panel references
- Always include: source of truth doc list, working rules
- Always include rule: **"Do not add translations until the finalization phase (pre-release-check)"**

### Step 7: Create .claude/settings.json

```json
{
  "env": {
    "PROJECT_DOCS_ROOT": "docs"
  }
}
```

### Step 8: Create agents

Write these agent files to `.claude/agents/`:

- `architect-reviewer.md` — reviews changes against PRD, architecture, tasks
- `backend-engineer.md` — implements backend features (skip if no backend)
- `ios-engineer.md` — implements iOS features (if swift selected)
- `qa-reviewer.md` — generates test scenarios and QA plans
- `release-manager.md` — prepares release docs

Each agent has frontmatter (name, description) and instructions to read CLAUDE.md and relevant docs before acting.

### Step 9: Create doc stubs

Create these files with TBD content:
```
docs/product/idea.md
docs/product/competitors.md
docs/product/prd.md
docs/product/user-stories.md
docs/architecture/system.md
docs/architecture/api.md           (skip if no backend)
docs/architecture/db-schema.sql    (skip if no backend)
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

### Step 10: Git init and commit

```bash
git init
git add -A
git commit -m "chore: bootstrap PROJECT_NAME"
```

### Step 11: Finish

Print summary of what was created. Then:

```
✓ Project ready.

Next steps:
1. If backend: fill in backend/.env (grep REPLACE_ME)
2. Run: vd-analyze (if existing code) or start with superpowers:brainstorming

Remember:
- Do NOT add translations until vd-release phase
- /exit to close this session
```
