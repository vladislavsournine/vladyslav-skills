#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
bash "$HERE/../docker.sh" --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
out="$(bash "$HERE/../redis.sh" --pwd "$TMP" --plugin-root "$ROOT")"
case "$out" in *'"status":"success"'*) pass "ran" ;; *) fail "bad: $out" ;; esac
assert_contains "$TMP/docker-compose.yml" "redis:"
assert_contains "$TMP/.env" "REDIS_URL"
bash "$HERE/../redis.sh" --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
n="$(grep -c '  redis:' "$TMP/docker-compose.yml")"
[ "$n" -eq 1 ] && pass "one redis block" || fail "redis blocks=$n"
summary
