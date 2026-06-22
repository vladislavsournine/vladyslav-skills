#!/usr/bin/env bash
# postgres.sh — append a postgres service to docker-compose.yml, idempotently.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
parse_common_args "$@"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

COMPOSE="docker-compose.yml"
if [ ! -f "$COMPOSE" ]; then
    write_file "$COMPOSE" "services:
"
fi

if grep -q '^  postgres:' "$COMPOSE"; then
    SKIPPED+=("$COMPOSE#postgres")
else
    cat >> "$COMPOSE" <<'YAML'
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: app
      POSTGRES_DB: app
    ports:
      - "5432:5432"
YAML
    WRITTEN+=("$COMPOSE#postgres")
fi

if [ ! -f .env ] || ! grep -q '^DATABASE_URL=' .env; then
    printf 'DATABASE_URL=postgresql://app:app@postgres:5432/app\n' >> .env
    WRITTEN+=(".env#DATABASE_URL")
else
    SKIPPED+=(".env#DATABASE_URL")
fi

emit_json "success"
exit 0
