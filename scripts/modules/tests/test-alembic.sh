#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
out="$(bash "$HERE/../alembic.sh" --pwd "$TMP" --plugin-root "$ROOT")"
assert_json_status "$out" "success"
assert_file "$TMP/alembic.ini"
assert_file "$TMP/migrations/env.py"
assert_file "$TMP/migrations/versions/.gitkeep"
summary
