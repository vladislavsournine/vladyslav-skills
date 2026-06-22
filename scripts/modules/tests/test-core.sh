#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

out="$(bash "$HERE/../core.sh" --pwd "$TMP" --plugin-root "$ROOT" --name DemoApp)"
assert_json_status "$out" "success"
assert_file "$TMP/CLAUDE.md"
assert_contains "$TMP/CLAUDE.md" "DemoApp"
assert_contains "$TMP/CLAUDE.md" "MemPalace"
assert_file "$TMP/.claude/settings.json"
assert_file "$TMP/.gitignore"
assert_file "$TMP/.remember/now.md"
# minimal = nothing else
assert_no_file "$TMP/docs"
assert_no_file "$TMP/Dockerfile"

# idempotent: second run skips all
out2="$(bash "$HERE/../core.sh" --pwd "$TMP" --plugin-root "$ROOT" --name DemoApp)"
case "$out2" in *'"files_written":[]'*) pass "idempotent re-run" ;; *) fail "re-run wrote files: $out2" ;; esac
summary
