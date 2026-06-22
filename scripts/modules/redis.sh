#!/usr/bin/env bash
# redis.sh — append a redis service to docker-compose.yml, idempotently.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
parse_common_args "$@"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

COMPOSE="docker-compose.yml"
[ -f "$COMPOSE" ] || write_file "$COMPOSE" "services:
"

if grep -q '^  redis:' "$COMPOSE"; then
    SKIPPED+=("$COMPOSE#redis")
else
    cat >> "$COMPOSE" <<'YAML'
  redis:
    image: redis:7
    ports:
      - "6379:6379"
YAML
    WRITTEN+=("$COMPOSE#redis")
fi

if [ ! -f .env ] || ! grep -q '^REDIS_URL=' .env; then
    printf 'REDIS_URL=redis://redis:6379/0\n' >> .env
    WRITTEN+=(".env#REDIS_URL")
else
    SKIPPED+=(".env#REDIS_URL")
fi

emit_json "success"
exit 0
