#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
out="$(bash "$HERE/../docker.sh" --pwd "$TMP" --plugin-root "$ROOT")"
assert_json_status "$out" "success"
assert_file "$TMP/Dockerfile"
assert_file "$TMP/docker-compose.yml"
assert_file "$TMP/docs/operations/docker.md"
assert_contains "$TMP/docker-compose.yml" "services:"
assert_contains "$TMP/docker-compose.yml" "app:"
out2="$(bash "$HERE/../docker.sh" --pwd "$TMP" --plugin-root "$ROOT")"
case "$out2" in *'"files_written":[]'*) pass "idempotent" ;; *) fail "re-run wrote: $out2" ;; esac
summary
