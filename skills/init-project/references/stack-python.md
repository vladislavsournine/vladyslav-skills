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

### Docker compose files

Docker Compose scaffolding is now handled by the modular scripts:

- `scripts/modules/docker.sh` — writes `backend/docker-compose.yml` and `backend/docker-compose.prod.yml`
- `scripts/modules/postgres.sh` — adds Postgres service into the compose files
- `scripts/modules/redis.sh` — adds Redis service into the compose files

These scripts are invoked by `init-project` when the user opts into the backend-infra module. This reference fragment does not need to call them directly.
