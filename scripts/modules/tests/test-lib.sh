#!/usr/bin/env bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_assert.sh"
. "$HERE/../_lib.sh"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# write_file writes when absent
write_file "$TMP/a.txt" "hello"
assert_file "$TMP/a.txt"
assert_contains "$TMP/a.txt" "hello"

# write_file skips when present
write_file "$TMP/a.txt" "OVERWRITE"
assert_contains "$TMP/a.txt" "hello"   # unchanged
[ "${#SKIPPED[@]}" -ge 1 ] && pass "skip tracked" || fail "skip not tracked"

# emit_json shape
out="$(emit_json success)"
assert_json_status "$out" "success"

# sed_inplace portable
printf 'TOKEN\n' > "$TMP/b.txt"
sed_inplace "$TMP/b.txt" 's|TOKEN|DONE|'
assert_contains "$TMP/b.txt" "DONE"

summary
