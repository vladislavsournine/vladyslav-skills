#!/usr/bin/env bash
# grep-replace-me.sh — find unfilled placeholders in project files.
#
# Usage: grep-replace-me.sh [path]
#
# Searches for the conventional placeholder tokens used by this plugin's
# scaffolding skills. Excludes the plugin's own templates and binary/
# vendor directories. Emits one match per line as `<path>:<lineno>:<line>`.
#
# Tokens scanned (case-sensitive):
#   REPLACE_ME, TBD, TODO_FILL, <PROJECT_NAME>, <ProjectName>, *to be filled*
#
# Exit codes:
#   0 — at least one placeholder found (caller may treat this as a "block release" signal)
#   1 — no placeholders found (clean)
#   2 — bad arguments

set -u

PROJECT="${1:-.}"

if [ ! -d "$PROJECT" ]; then
    echo "grep-replace-me: not a directory: $PROJECT" >&2
    exit 2
fi

# Use grep -R with explicit excludes. Patterns joined with -e for clarity.
matches="$(
    grep -R -n \
        --exclude-dir=.git \
        --exclude-dir=node_modules \
        --exclude-dir=.venv \
        --exclude-dir=DerivedData \
        --exclude-dir=build \
        --exclude-dir=dist \
        --include='*.md' --include='*.swift' --include='*.py' --include='*.go' \
        --include='*.kt' --include='*.dart' --include='*.ts' --include='*.tsx' \
        --include='*.js' --include='*.jsx' --include='*.json' --include='*.yaml' \
        --include='*.yml' --include='*.toml' \
        -e 'REPLACE_ME' \
        -e 'TBD' \
        -e 'TODO_FILL' \
        -e '<PROJECT_NAME>' \
        -e '<ProjectName>' \
        -e '\*to be filled\*' \
        "$PROJECT" 2>/dev/null
)"

if [ -n "$matches" ]; then
    printf '%s\n' "$matches"
    exit 0
fi
exit 1
