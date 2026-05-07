---
name: analyze-project
description: Use after attaching to an existing project or when docs are out of sync with code - scans codebase to document architecture, endpoints, schema, and dependencies for Claude
---

# Analyze Project

## Overview

Analyze an existing codebase and generate/update architecture documentation so Claude can work with the project effectively.

**Type:** Architect

## Process

### Step 1: Read existing docs

Read CLAUDE.md and any existing docs in `docs/architecture/`. Note what's already documented.

### Step 2: Scan project structure

If project has 2+ independent components (e.g. backend + mobile app), use `superpowers:dispatching-parallel-agents` to analyze them in parallel.

Use Glob and Grep to understand the codebase:

1. **Directory tree** — `ls` key directories, understand the layout
2. **Dependencies** — read package files (requirements.txt, go.mod, pubspec.yaml, Podfile, build.gradle)
3. **Entry points** — find main files, app entry points
4. **Configuration** — .env files, config files, docker-compose

### Step 3: Analyze architecture

For each detected component, analyze:

**Backend (if exists):**
- Framework and version
- Route/endpoint definitions — find all routes, methods, paths
- Database models/schema — find model definitions, migrations
- Auth mechanism — how auth works (JWT, sessions, OAuth)
- Background jobs/queues — any async processing
- External API calls — third-party integrations
- Middleware chain

**Mobile apps (if exist):**
- Framework version
- Screen/view structure
- State management approach
- API client setup
- Navigation structure
- Local storage

**Infrastructure:**
- Docker setup
- CI/CD config
- Deployment target

### Step 4: Update docs

Write findings to:

1. `docs/architecture/system.md` — full system overview with real components
2. `docs/architecture/api.md` — all discovered endpoints with methods and paths (if backend)
3. `docs/architecture/db-schema.sql` — current schema from models/migrations (if backend)
4. Update `CLAUDE.md` — accurate repository structure section

### Step 5: Finish

Print architect report:

```
✓ Architect report:
- Stacks: <detected>
- Endpoints: <count> (see docs/architecture/api.md)
- DB: <schema summary>
- Auth: <mechanism>
- External APIs: <list>

Updated:
- docs/architecture/system.md
- docs/architecture/api.md
- CLAUDE.md

Review generated docs for accuracy.

Next steps:
- /vladyslav:add-feature — start adding features
- /vladyslav:write-project-docs — generate human-readable docs
- /vladyslav:write-user-stories — registry of implemented features
```
