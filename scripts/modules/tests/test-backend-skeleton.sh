#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
out="$(bash "$HERE/../backend-skeleton.sh" --pwd "$TMP" --plugin-root "$ROOT")"
assert_json_status "$out" "success"
assert_file "$TMP/requirements.txt"
assert_file "$TMP/src/main.py"
# must NOT be FastAPI boilerplate
grep -qi "fastapi" "$TMP/src/main.py" && fail "should not contain FastAPI" || pass "no FastAPI boilerplate"
summary
