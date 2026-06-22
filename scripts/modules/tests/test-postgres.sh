#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
bash "$HERE/../docker.sh" --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
out="$(bash "$HERE/../postgres.sh" --pwd "$TMP" --plugin-root "$ROOT")"
case "$out" in *'"status":"success"'*) pass "ran" ;; *) fail "bad: $out" ;; esac
assert_contains "$TMP/docker-compose.yml" "postgres:"
assert_contains "$TMP/.env" "DATABASE_URL"
# idempotent: postgres service appears exactly once
n="$(grep -c '  postgres:' "$TMP/docker-compose.yml")"
[ "$n" -eq 1 ] && pass "one postgres block" || fail "postgres blocks=$n"
bash "$HERE/../postgres.sh" --pwd "$TMP" --plugin-root "$ROOT" >/dev/null
n2="$(grep -c '  postgres:' "$TMP/docker-compose.yml")"
[ "$n2" -eq 1 ] && pass "still one after re-run" || fail "postgres blocks=$n2"
summary
