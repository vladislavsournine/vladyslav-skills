#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
out="$(bash "$HERE/../docs.sh" --pwd "$TMP" --plugin-root "$ROOT")"
assert_json_status "$out" "success"
assert_file "$TMP/docs/product/prd.md"
assert_file "$TMP/docs/plans/tasks.md"
assert_file "$TMP/docs/plans/backlog-next.md"
assert_contains "$TMP/docs/product/prd.md" "Product Requirements"
out2="$(bash "$HERE/../docs.sh" --pwd "$TMP" --plugin-root "$ROOT")"
case "$out2" in *'"files_written":[]'*) pass "idempotent" ;; *) fail "re-run wrote: $out2" ;; esac
summary
