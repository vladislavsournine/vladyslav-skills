---
name: analyze-project
description: Use after attaching to an existing project to scan and document architecture, endpoints, schema, and dependencies.
---

# Analyze Project

## Overview

Analyze an existing codebase and generate/update architecture documentation so Claude can work with the project effectively.

**Type:** Architect

## Process

### Step 1: Read existing docs

Read CLAUDE.md and any existing docs in `docs/architecture/`. Note what's already documented.

### Step 2: Gather architecture inventory via bash

Run `<plugin>/scripts/scan-architecture.sh --pwd .`. Returns JSON:

```json
{
  "stacks": {<from detect-stack.sh>},
  "entry_points": [<paths>],
  "routes": {"framework": "fastapi|flask|express|gin|go-stdlib|none", "handlers": [{"method": "...", "path": "...", "file": "..."}]},
  "schema_files": [<paths to SQL migrations / Prisma schemas / etc.>],
  "deps": {<manifest path>: <summary string>},
  "doc_files": [<paths under docs/>]
}
```

This replaces the manual "read package.json, ls directories, grep for routes" pass. The script is deterministic and fast (~0.1s).

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
