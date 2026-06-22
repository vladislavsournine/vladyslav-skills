#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
ROOT="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
out="$(bash "$HERE/../agents.sh" --pwd "$TMP" --plugin-root "$ROOT" --agents "architect-reviewer,qa-reviewer")"
assert_json_status "$out" "success"
assert_file "$TMP/.claude/agents/architect-reviewer.md"
assert_file "$TMP/.claude/agents/qa-reviewer.md"
assert_no_file "$TMP/.claude/agents/release-manager.md"
summary
