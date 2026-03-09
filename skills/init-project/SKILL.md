---
name: init-project
description: Use when creating a new project from scratch - interactive setup that creates directories, configs, docs, agents, and CLAUDE.md based on chosen stacks (python/go/flutter/swift/kotlin or custom "other" stacks)
---

# Init Project

## Overview

Bootstrap a new project with full Claude Code structure. Asks questions, then creates everything.

**Type:** Engineer (Sonnet)

## Process

### Step 0: Verify model

Check current model. If not Sonnet, switch: `/model sonnet`

### Step 1: Gather requirements

Ask these questions one at a time using the AskUserQuestion tool:

1. **Project name** — what is the project called?
2. **Backend stack** — python (default) / go / other / none
   - If "other": ask for label, directory name, .gitignore entries
3. **Frontend/mobile stacks** — flutter / swift / kotlin / other / none (multi-select)
   - If "other": for each, ask for label, directory name, .gitignore entries
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

`backend/docker-compose.yml`:
```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      target: dev
    volumes:
      - .:/app
    ports:
      - "${APP_PORT:-8000}:8000"
    env_file: .env
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
      POSTGRES_USER: ${POSTGRES_USER:-appuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-apppassword}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-appuser}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  adminer:
    image: adminer
    ports:
      - "8080:8080"
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

`backend/docker-compose.prod.yml` (managed DB/Redis — use when cloud DB and Redis are available):
```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      target: prod
    env_file: .env
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - web

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../infra/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - certbot_certs:/etc/letsencrypt:ro
      - certbot_webroot:/var/www/certbot:ro
    restart: always
    depends_on:
      - app
    networks:
      - web

  certbot:
    image: certbot/certbot
    volumes:
      - certbot_certs:/etc/letsencrypt
      - certbot_webroot:/var/www/certbot
    entrypoint: /bin/sh -c "trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done"

volumes:
  certbot_certs:
  certbot_webroot:

networks:
  web:
```

> Note: If no domain is set, omit the `certbot` service and the `certbot_*` volumes. nginx still uses port 80 only.

`backend/docker-compose.prod-selfhosted.yml` (self-hosted — use when running postgres and redis on the same VPS):
```yaml
# Self-hosted variant — includes DB and Redis. Use when no managed services available.
version: "3.8"

services:
  app:
    build:
      context: .
      target: prod
    env_file: .env
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - web

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
      POSTGRES_USER: ${POSTGRES_USER:-appuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-apppassword}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-appuser}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - web

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: always
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - web

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ../infra/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - certbot_certs:/etc/letsencrypt:ro
      - certbot_webroot:/var/www/certbot:ro
    restart: always
    depends_on:
      - app
    networks:
      - web

  certbot:
    image: certbot/certbot
    volumes:
      - certbot_certs:/etc/letsencrypt
      - certbot_webroot:/var/www/certbot
    entrypoint: /bin/sh -c "trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done"

volumes:
  postgres_data:
  redis_data:
  certbot_certs:
  certbot_webroot:

networks:
  web:
```

`backend/.env.example`: APP_ENV, APP_PORT, APP_SECRET_KEY, DATABASE_URL, REDIS_URL. If domain set: add APP_DOMAIN, ADMIN_URL, GOOGLE_CLIENT_ID/SECRET. If no domain: APP_DOMAIN=localhost.

`backend/.env`: stub with "DO NOT COMMIT" comment.

`backend/secrets/.gitkeep`: empty.

**For go — create:**

`backend/go.mod`, `backend/cmd/server/main.go`, `backend/.air.toml` — Go equivalents of above.

### Step 4b: Create Docker operations doc (if backend is python or go)

`docs/operations/docker.md`:
````markdown
# Docker Operations

## Dev environment

```bash
# Start all services
docker compose up -d

# View app logs
docker compose logs -f app

# Run migrations (Python/FastAPI example)
docker compose exec app alembic upgrade head

# Open a shell in the app container
docker compose exec app bash

# Stop all services
docker compose down
```

## Production — managed DB/Redis

```bash
# Deploy
docker compose -f backend/docker-compose.prod.yml up -d --build

# View logs
docker compose -f backend/docker-compose.prod.yml logs -f app

# Rebuild app after code change
docker compose -f backend/docker-compose.prod.yml build app
docker compose -f backend/docker-compose.prod.yml up -d app
```

## Production — self-hosted (VPS, no managed services)

```bash
docker compose -f backend/docker-compose.prod-selfhosted.yml up -d --build
```

## SSL — initial certificate issuance

Run once after first deploy (replace yourdomain.com):

```bash
docker compose -f backend/docker-compose.prod.yml run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  -d yourdomain.com -d www.yourdomain.com \
  --email admin@yourdomain.com --agree-tos --no-eff-email
```

Then reload nginx:

```bash
docker compose -f backend/docker-compose.prod.yml exec nginx nginx -s reload
```

## SSL — renewal

Certbot auto-renews every 12h in the background. To force-renew manually:

```bash
docker compose -f backend/docker-compose.prod.yml run --rm certbot renew
docker compose -f backend/docker-compose.prod.yml exec nginx nginx -s reload
```

## Env vars

Copy and fill in before first run:

```bash
cp backend/.env.example backend/.env
```
````

### Step 5: Create nginx config (if domain set)

Only if backend is python/go AND domain is provided.

`infra/nginx/nginx.conf`:
```nginx
events {}

http {
    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name APP_DOMAIN www.APP_DOMAIN;

        # Let's Encrypt ACME challenge
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$host$request_uri;
        }
    }

    # HTTPS
    server {
        listen 443 ssl;
        server_name APP_DOMAIN www.APP_DOMAIN;

        ssl_certificate /etc/letsencrypt/live/APP_DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/APP_DOMAIN/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;

        location /api/ {
            proxy_pass http://app:8000/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /admin/ {
            proxy_pass http://app:8000/admin/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

> Replace `APP_DOMAIN` with the actual domain. If no domain is set, skip this file entirely.

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
# Note: docs/operations/docker.md is generated with real content in Step 4b — skip it here
docs/marketing/launch-notes.md
```

### Step 10: Git init and commit

```bash
git init
git add -A
git commit -m "chore: bootstrap PROJECT_NAME"
```

### Step 11: Finish

Print engineer report, then prepared prompt for Opus terminal:

```
✓ Engineer report:
- Created project <name> with stacks: <stacks>
- Directories: <list>
- Files: CLAUDE.md, .gitignore, agents, doc stubs
- If backend: fill in backend/.env (grep REPLACE_ME)

Do NOT add translations — wait for pre-release-check phase.

━━━ Next (Opus terminal) ━━━━━━━━━━━━━━━━━━
/vladyslav:analyze-project

Context:
"Project <name> bootstrapped with <stacks>.
Domain: <domain or none>. Private mode: <yes/no>.
Analyze codebase and fill architecture docs."
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
