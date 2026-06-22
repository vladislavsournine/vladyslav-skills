#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
out="$(bash "$HERE/../design-system.sh" --pwd "$TMP" --plugin-root "$ROOT" --name DemoApp)"
case "$out" in *'"status":"success"'*|*'"status":"partial"'*) pass "ran" ;; *) fail "bad: $out" ;; esac
if [ -f "$ROOT/templates/DesignSystem.md" ]; then assert_file "$TMP/docs/design/system.md"; fi
summary
