#!/usr/bin/env bash
# derive-wing.sh — emit the canonical MemPalace wing name for a project.
#
# Usage: derive-wing.sh [path]
#   path defaults to the current working directory.
#
# Algorithm:
#   1. Take the basename of the absolute path.
#   2. Lowercase it.
#   3. Replace any sequence of whitespace, underscores, or dots with a single
#      hyphen. Strip leading/trailing hyphens.
#   4. If the result does NOT already start with a known platform prefix
#      (swift-, python-, flutter-, kotlin-, go-, web-, plugin-),
#      derive a prefix from detect-stack.sh and prepend it.
#   5. Print the wing name to stdout.
#
# Output: a single line, no trailing newline beyond `echo`.
#
# This eliminates the recurring case-mismatch wing bug class (e.g. an iOS
# project at swift/Sudoku/ ending up as swift-Sudoku instead of swift-sudoku).

set -u

PROJECT="${1:-.}"

if [ ! -d "$PROJECT" ]; then
    echo "derive-wing: not a directory: $PROJECT" >&2
    exit 2
fi

# Resolve to absolute path so basename is stable regardless of caller's pwd.
ABS="$(cd "$PROJECT" && pwd)"
RAW="$(basename "$ABS")"

# Lowercase using `tr` (portable; bash 4 ${var,,} not available on macOS bash 3.2).
LOWER="$(printf '%s' "$RAW" | tr '[:upper:]' '[:lower:]')"

# Replace runs of whitespace / underscore / dot with a single hyphen,
# then collapse repeated hyphens, then strip edge hyphens.
NORMAL="$(printf '%s' "$LOWER" | sed -E 's/[[:space:]_.]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')"

# Already prefixed?
case "$NORMAL" in
    swift-*|python-*|flutter-*|kotlin-*|go-*|web-*|plugin-*|android-*)
        printf '%s\n' "$NORMAL"
        exit 0
        ;;
esac

# Need to derive a prefix from the project stack.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECT="$SCRIPT_DIR/detect-stack.sh"

if [ ! -x "$DETECT" ]; then
    # No detector available — emit the unprefixed name and exit non-zero
    # so the caller knows the prefix step was skipped.
    printf '%s\n' "$NORMAL"
    echo "derive-wing: detect-stack.sh not found or not executable; prefix not applied" >&2
    exit 1
fi

DETECTION="$("$DETECT" "$ABS")"

# Pick a prefix in priority order: ios > flutter > kotlin > python > go > web > plugin.
prefix=""
case "$DETECTION" in
    *'"ios":true'*)     prefix="swift" ;;
    *'"flutter":true'*) prefix="flutter" ;;
    *'"kotlin":true'*)  prefix="kotlin" ;;
    *'"android":true'*) prefix="android" ;;
    *'"python":true'*)  prefix="python" ;;
    *'"go":true'*)      prefix="go" ;;
    *'"web":true'*)     prefix="web" ;;
    *'"plugin":true'*)  prefix="plugin" ;;
esac

if [ -n "$prefix" ]; then
    printf '%s-%s\n' "$prefix" "$NORMAL"
else
    # No stack detected — return the bare name. Caller should treat this as
    # a fallback; logging guidance lives in the calling skill.
    printf '%s\n' "$NORMAL"
fi
