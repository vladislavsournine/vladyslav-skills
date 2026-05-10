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
