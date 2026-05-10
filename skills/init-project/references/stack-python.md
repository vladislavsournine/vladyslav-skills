# Stack: Python (FastAPI backend)

This fragment is composed into the `init-project` subagent prompt when the user selects Python as the backend stack.

## Directories

Create:

```
backend/admin/
backend/src/
backend/migrations/
backend/secrets/
```

## .gitignore additions

Append to `.gitignore`:

```
__pycache__/
*.pyc
.venv/
```

## Files

### `backend/requirements.txt`

```
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
gunicorn>=23.0.0
psycopg2-binary>=2.9.9
redis>=5.0.0
```

### `backend/src/__init__.py`

Empty file.

### `backend/src/main.py`

Replace `<ProjectName>` with the actual project name.

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

### `backend/Dockerfile`

Multi-stage Dockerfile with `dev` (uvicorn --reload) and `prod` (gunicorn) targets.

### `backend/.env.example`

Keys: `APP_ENV`, `APP_PORT`, `APP_SECRET_KEY`, `DATABASE_URL`, `REDIS_URL`. If a domain is set: also `APP_DOMAIN`, `ADMIN_URL`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`. If no domain: `APP_DOMAIN=localhost`.

### `backend/.env`

Stub with comment:

```
# DO NOT COMMIT — copy .env.example and fill values
```

### `backend/secrets/.gitkeep`

Empty file.

### Docker compose files (read from plugin assets)

Read each from `<plugin>/skills/init-project/assets/backend/` and write to `backend/`:

- `assets/backend/docker-compose.yml` → `backend/docker-compose.yml` (no substitutions)
- `assets/backend/docker-compose.prod.yml` → `backend/docker-compose.prod.yml`
  - If no domain: remove the `certbot` service and `certbot_*` volumes; nginx uses port 80 only.
- `assets/backend/docker-compose.prod-selfhosted.yml` → `backend/docker-compose.prod-selfhosted.yml`
  - Same certbot rule applies.

If any asset cannot be located, return `status: error`: `"Cannot find skills/init-project/assets/backend/<name> in vladyslav-skills plugin. Please reinstall or run git pull."`
