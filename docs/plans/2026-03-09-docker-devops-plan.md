# Docker/DevOps Improvements to init-project — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enrich the Docker Compose templates in `skills/init-project/SKILL.md` with healthchecks, restart policies, named volumes, a self-hosted prod variant, SSL/certbot setup, and a generated `docs/operations/docker.md` cheatsheet.

**Architecture:** All changes are prose edits to a single Markdown skill file. The skill describes templates that Claude generates when a user runs `/vladyslav:init-project`. No code is executed — Claude reads the skill and follows its instructions to generate files in the user's project.

**Tech Stack:** Markdown, Docker Compose v3.8, Let's Encrypt/certbot, nginx

---

### Task 1: Expand `docker-compose.yml` (dev) template in Step 4

**Files:**
- Modify: `skills/init-project/SKILL.md` — Step 4, `docker-compose.yml` line

**Context:**
Currently the skill says `backend/docker-compose.yml: app + postgres + redis + adminer services.` — a one-liner. Replace it with a full template so Claude generates the right file.

**Step 1: Open the file and find the line to replace**

In `skills/init-project/SKILL.md`, find:
```
`backend/docker-compose.yml`: app + postgres + redis + adminer services.
```

**Step 2: Replace with full template**

Replace that one line with:

````markdown
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
````

**Step 3: Verify the edit looks correct**

Read the modified section in `skills/init-project/SKILL.md` and confirm:
- `depends_on` uses `condition: service_healthy`
- Both `db` and `redis` have `healthcheck` blocks
- Named volumes `postgres_data` and `redis_data` are declared at the bottom
- `restart: unless-stopped` on all services

**Step 4: Commit**

```bash
git add skills/init-project/SKILL.md
git commit -m "feat: expand docker-compose.yml dev template with healthchecks and named volumes"
```

---

### Task 2: Expand `docker-compose.prod.yml` template in Step 4

**Files:**
- Modify: `skills/init-project/SKILL.md` — Step 4, `docker-compose.prod.yml` line

**Context:**
Currently: `backend/docker-compose.prod.yml: app + nginx, no local DB (use managed services).`
Replace with a full template that includes certbot alongside nginx. Certbot is only included when domain is set — add a conditional note.

**Step 1: Find the line to replace**

```
`backend/docker-compose.prod.yml`: app + nginx, no local DB (use managed services).
```

**Step 2: Replace with full template**

````markdown
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
````

**Step 3: Verify**

Read the modified section and confirm certbot service, shared volumes, and the "no domain" note are present.

**Step 4: Commit**

```bash
git add skills/init-project/SKILL.md
git commit -m "feat: expand docker-compose.prod.yml template with certbot and healthcheck"
```

---

### Task 3: Add `docker-compose.prod-selfhosted.yml` template in Step 4

**Files:**
- Modify: `skills/init-project/SKILL.md` — Step 4, after the `docker-compose.prod.yml` block

**Context:**
New file for VPS deployments where postgres and redis run locally instead of managed services.

**Step 1: Find the insertion point**

After the `docker-compose.prod.yml` block (and its closing ` ``` `), insert:

````markdown
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
````

**Step 2: Verify**

Confirm both `docker-compose.prod.yml` and `docker-compose.prod-selfhosted.yml` blocks now exist in Step 4, each with their own closing ` ``` `.

**Step 3: Commit**

```bash
git add skills/init-project/SKILL.md
git commit -m "feat: add docker-compose.prod-selfhosted.yml template to init-project"
```

---

### Task 4: Update nginx.conf template in Step 5 with SSL

**Files:**
- Modify: `skills/init-project/SKILL.md` — Step 5

**Context:**
Currently Step 5 says `infra/nginx/nginx.conf: reverse proxy with API and admin subdomains.` — a one-liner. Replace with a full template including SSL server block (443), HTTP→HTTPS redirect, and certbot webroot challenge path.

**Step 1: Find the line to replace**

```
`infra/nginx/nginx.conf`: reverse proxy with API and admin subdomains.
```

**Step 2: Replace with full template**

````markdown
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
````

**Step 3: Verify**

Read Step 5 and confirm:
- Port 80 block with certbot challenge path and redirect
- Port 443 block with SSL cert paths
- `APP_DOMAIN` placeholder used consistently
- "If no domain, skip" note present

**Step 4: Commit**

```bash
git add skills/init-project/SKILL.md
git commit -m "feat: expand nginx.conf template with SSL and certbot webroot in init-project"
```

---

### Task 5: Add Step 4b — generate `docs/operations/docker.md`

**Files:**
- Modify: `skills/init-project/SKILL.md` — insert new step between Step 4 and Step 5

**Context:**
Add a new Step 4b that instructs Claude to create `docs/operations/docker.md` with a full cheatsheet. Renumber Step 5 onward (Step 5→6, 6→7, etc.) OR insert as Step 4b to avoid renumbering.

**Step 1: Insert Step 4b after Step 4 content**

After the closing of all Step 4 content (the `backend/secrets/.gitkeep` line and the Go note), insert:

```markdown
### Step 4b: Create Docker operations doc (if backend is python or go)

`docs/operations/docker.md`:
```markdown
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
```
```

**Step 2: Verify**

Read the new Step 4b and confirm all sections are present: dev, prod managed, prod selfhosted, SSL issuance, renewal, env vars.

**Step 3: Commit**

```bash
git add skills/init-project/SKILL.md
git commit -m "feat: add Step 4b to init-project — generate docs/operations/docker.md cheatsheet"
```

---

### Task 6: Add `docs/operations/docker.md` to the doc stubs list in Step 9

**Files:**
- Modify: `skills/init-project/SKILL.md` — Step 9 doc stubs list

**Context:**
Step 9 lists `docs/operations/incidents.md`. Since `docker.md` is now generated with real content in Step 4b (not a TBD stub), add a note to Step 9 to skip it if it already exists.

**Step 1: Find the doc stubs list in Step 9**

Find:
```
docs/operations/incidents.md
```

**Step 2: Add a note above the operations section**

Replace:
```
docs/operations/incidents.md
```

With:
```
docs/operations/incidents.md
# Note: docs/operations/docker.md is generated with real content in Step 4b — skip it here
```

**Step 3: Verify**

Read Step 9 and confirm the note is present.

**Step 4: Commit**

```bash
git add skills/init-project/SKILL.md
git commit -m "chore: note in Step 9 that docker.md is generated by Step 4b, not a stub"
```

---

### Task 7: Final review and version bump

**Files:**
- Modify: `skills/init-project/SKILL.md` — read-through
- Modify: `.claude-plugin/plugin.json` — bump version

**Step 1: Read the full modified skill**

Read `skills/init-project/SKILL.md` top to bottom and verify:
- Step 4: all three docker-compose files have full YAML templates
- Step 4b: `docs/operations/docker.md` cheatsheet is complete
- Step 5: nginx.conf has SSL server block + HTTP redirect
- Step 9: note about docker.md is present
- No broken markdown (unclosed code fences, mismatched headers)

**Step 2: Read current version**

Read `.claude-plugin/plugin.json` and note current version.

**Step 3: Bump patch version**

If current is `1.1.0`, bump to `1.2.0` (minor — new generated files added).

**Step 4: Commit**

```bash
git add skills/init-project/SKILL.md .claude-plugin/plugin.json
git commit -m "chore: bump version to 1.2.0 — Docker/DevOps improvements to init-project"
```
