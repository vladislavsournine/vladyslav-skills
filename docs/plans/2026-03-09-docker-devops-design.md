# Design: Docker/DevOps Improvements to init-project

**Date:** 2026-03-09
**Status:** Approved
**Scope:** `skills/init-project/SKILL.md` only

## Problem

`init-project` generates basic Docker Compose files without healthchecks, restart policies, or named volumes. There is no prod-selfhosted variant and no SSL/certbot setup. No generated documentation explains the Docker workflow.

## Decision

Extend `init-project` Step 4 with richer Docker Compose templates and add a new Step 4b that generates `docs/operations/docker.md`.

## Files Changed

Only `skills/init-project/SKILL.md` changes.

### Generated file additions/changes per new project

| File | Change |
|------|--------|
| `backend/docker-compose.yml` | Add healthchecks, restart policies, named volumes, `depends_on: condition: service_healthy` |
| `backend/docker-compose.prod.yml` | App + nginx + certbot (when domain set); external DB/Redis |
| `backend/docker-compose.prod-selfhosted.yml` | New — same as prod but adds postgres + redis for VPS deployments |
| `infra/nginx/nginx.conf` | Add SSL server block (443) + HTTP→HTTPS redirect (when domain set) |
| `docs/operations/docker.md` | New — cheatsheet for dev/prod workflow, migrations, SSL issuance, renewal |

## Docker Compose Patterns

### Dev (`docker-compose.yml`)
- Services: app, postgres, redis, adminer
- Named volumes: `postgres_data`, `redis_data`
- `restart: unless-stopped` on all services
- Healthchecks on postgres and redis
- `depends_on: db: condition: service_healthy` for app

### Prod managed (`docker-compose.prod.yml`)
- Services: app, nginx, certbot (when domain set)
- `restart: always`
- Healthcheck on app
- External DB/Redis (managed services assumed)
- certbot volume shared with nginx for certs

### Prod self-hosted (`docker-compose.prod-selfhosted.yml`)
- Same as prod + postgres + redis services
- Same healthcheck/restart/volume patterns as dev
- Header comment: `# Self-hosted variant — use when no managed services available`

### SSL/Certbot
- Only generated when domain is set (gated by existing Step 5 condition)
- nginx.conf includes SSL server block with Let's Encrypt cert paths
- docker.md includes initial cert issuance and renewal commands

## Out of Scope

- No changes to `attach-project` (inherits init-project logic automatically)
- No new `vladyslav:devops` skill
- No CI/CD (GitHub Actions)
- No changes to `.env.example`
- Go backend gets same patterns as Python

## docs/operations/docker.md Content

```markdown
# Docker Operations

## Dev
docker compose up -d
docker compose logs -f app
docker compose exec app <migration-command>
docker compose down

## Prod (managed DB/Redis)
docker compose -f docker-compose.prod.yml up -d

## Prod (self-hosted, VPS)
docker compose -f docker-compose.prod-selfhosted.yml up -d

## Rebuild after code change
docker compose build app && docker compose up -d app

## SSL — initial cert issuance
docker compose -f docker-compose.prod.yml run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  -d yourdomain.com

## SSL — renewal (add to cron)
docker compose -f docker-compose.prod.yml run --rm certbot renew
```
