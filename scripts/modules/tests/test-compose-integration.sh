#!/usr/bin/env bash
# test-compose-integration.sh — verify docker+postgres+redis produce a valid compose file
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

bash "$HERE/../docker.sh"   --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
bash "$HERE/../postgres.sh" --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
bash "$HERE/../redis.sh"    --pwd "$TMP" --plugin-root "$ROOT" >/dev/null

COMPOSE="$TMP/docker-compose.yml"

# top-level services: key must exist
grep -qx 'services:' "$COMPOSE" && pass "top-level services: present" \
    || fail "top-level services: missing"

# top-level volumes: key must NOT exist
count_vol="$(grep -c '^volumes:' "$COMPOSE" 2>/dev/null || true)"
[ "$count_vol" -eq 0 ] && pass "no top-level volumes: block" \
    || fail "unexpected top-level volumes: block (count=$count_vol)"

# each service appears exactly once under services:
for svc in app postgres redis; do
    n="$(grep -c "^  ${svc}:" "$COMPOSE" 2>/dev/null || true)"
    [ "$n" -eq 1 ] && pass "one ${svc}: block" || fail "${svc} block count=$n (want 1)"
done

# idempotency: run all three modules again; counts must still be 1
bash "$HERE/../docker.sh"   --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
bash "$HERE/../postgres.sh" --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
bash "$HERE/../redis.sh"    --pwd "$TMP" --plugin-root "$ROOT" >/dev/null

count_vol2="$(grep -c '^volumes:' "$COMPOSE" 2>/dev/null || true)"
[ "$count_vol2" -eq 0 ] && pass "still no top-level volumes: after re-run" \
    || fail "top-level volumes: appeared after re-run (count=$count_vol2)"

for svc in app postgres redis; do
    n="$(grep -c "^  ${svc}:" "$COMPOSE" 2>/dev/null || true)"
    [ "$n" -eq 1 ] && pass "still one ${svc}: after re-run" \
        || fail "${svc} block count=$n after re-run (want 1)"
done

summary
