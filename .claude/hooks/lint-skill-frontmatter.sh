#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write|MultiEdit) — lint SKILL.md frontmatter.
# Validates skills/<name>/SKILL.md after every edit:
#   1. File starts with a YAML frontmatter block (--- ... ---)
#   2. Frontmatter contains both `name:` and `description:` keys
#   3. Frontmatter `name:` value matches the parent directory name
#   4. Body (after frontmatter) contains a `Type: Architect|Engineer` line
# On violation: exit 2 with stderr message — Claude Code surfaces it to the model.
# On success or non-matching files: exit 0 silently.
#
# Implementation note: pure bash + awk. No python/node — those are not
# guaranteed available (e.g. macOS python3 stub fails without Xcode license).

set -u

PAYLOAD="$(cat)"

# JSON extraction: minimal, assumes Claude Code emits flat-string values
# without backslash-escaped quotes inside `tool_name` or `file_path`. That
# holds in practice — file paths and tool names don't contain literal `"`.
TOOL="$(printf '%s' "$PAYLOAD" \
    | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 \
    | sed -E 's/.*"([^"]*)"$/\1/')"

case "$TOOL" in
    Edit|Write|MultiEdit) ;;
    *) exit 0 ;;
esac

FILE_PATH="$(printf '%s' "$PAYLOAD" \
    | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | head -1 \
    | sed -E 's/.*"([^"]*)"$/\1/')"

case "$FILE_PATH" in
    */skills/*/SKILL.md) ;;
    *) exit 0 ;;
esac

[ -f "$FILE_PATH" ] || exit 0

EXPECTED_NAME="$(basename "$(dirname "$FILE_PATH")")"

awk -v expected="$EXPECTED_NAME" '
BEGIN { state = "before"; name = ""; desc = ""; type_found = 0; fm_found = 0 }

state == "before" && /^---[[:space:]]*$/ {
    state = "fm"; fm_found = 1; next
}
state == "fm" && /^---[[:space:]]*$/ {
    state = "body"; next
}
state == "fm" {
    if ($0 ~ /^name:[[:space:]]/) {
        line = $0; sub(/^name:[[:space:]]*/, "", line); name = line
    } else if ($0 ~ /^description:[[:space:]]/) {
        line = $0; sub(/^description:[[:space:]]*/, "", line); desc = line
    }
    next
}
state == "body" && /^\*?\*?Type:\*?\*?[[:space:]]+(Architect|Engineer)/ {
    type_found = 1
}

END {
    n = 0
    if (!fm_found) {
        errs[++n] = "missing YAML frontmatter (--- ... ---) at start of file"
    } else {
        if (name == "") {
            errs[++n] = "frontmatter missing required `name:` field"
        } else if (name != expected) {
            errs[++n] = "frontmatter `name: " name "` does not match directory name `" expected "`"
        }
        if (desc == "") {
            errs[++n] = "frontmatter missing required `description:` field"
        }
    }
    if (!type_found) {
        errs[++n] = "body missing `Type:` line — expected one of: `Type: Architect`, `Type: Engineer`, or `Type: Engineer (light)`"
    }
    if (n > 0) {
        printf "[lint-skill-frontmatter] %s:\n", FILENAME > "/dev/stderr"
        for (i = 1; i <= n; i++) printf "  - %s\n", errs[i] > "/dev/stderr"
        exit 2
    }
    exit 0
}
' "$FILE_PATH"
