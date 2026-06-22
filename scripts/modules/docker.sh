#!/usr/bin/env bash
# docker.sh — minimal Dockerfile + app-only compose + docker docs.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
parse_common_args "$@"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

write_file "Dockerfile" "# syntax=docker/dockerfile:1.6
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt || true
COPY . .
CMD [\"python\", \"-m\", \"src.main\"]
"

write_file "docker-compose.yml" "services:
  app:
    build: .
    ports:
      - \"8000:8000\"
    env_file:
      - .env
"

write_file "docs/operations/docker.md" "# Docker

\`docker compose up --build\` to run locally. Add services (postgres, redis) via the
matching init-project modules; re-run them any time to append missing services.
Postgres data is ephemeral by default; add a named volume (with a top-level \`volumes:\`
section) to docker-compose.yml if you need persistence.
"

emit_json "success"
exit 0
