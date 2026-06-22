# scripts/modules/tests/_assert.sh
# Minimal assertion helpers for module tests.
_PASS=0; _FAIL=0
pass() { _PASS=$((_PASS+1)); printf 'ok   - %s\n' "$1"; }
fail() { _FAIL=$((_FAIL+1)); printf 'FAIL - %s\n' "$1"; }
assert_file() { [ -f "$1" ] && pass "exists: $1" || fail "missing: $1"; }
assert_no_file() { [ ! -e "$1" ] && pass "absent: $1" || fail "should be absent: $1"; }
assert_contains() { grep -qF "$2" "$1" 2>/dev/null && pass "contains '$2': $1" || fail "missing '$2' in $1"; }
assert_json_status() { case "$1" in *"\"status\":\"$2\""*) pass "status=$2" ;; *) fail "status!=$2 in: $1" ;; esac; }
summary() { printf '\n%d passed, %d failed\n' "$_PASS" "$_FAIL"; [ "$_FAIL" -eq 0 ]; }
