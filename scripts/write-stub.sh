#!/usr/bin/env bash
# write-stub.sh — create a placeholder Markdown file with a single heading
# and "*to be filled*" marker. Idempotent: refuses to overwrite an existing
# file unless --force is passed.
#
# Usage: write-stub.sh <path> <title> [--force]
#
# Example: write-stub.sh docs/architecture/system.md "System Architecture"
#
# Exit codes:
#   0 — file written (or already exists when --force not given)
#   2 — bad arguments
#   3 — file exists, --force not given (returned only when caller cares;
#       most callers can ignore this distinction since the file is in place)

set -u

if [ $# -lt 2 ]; then
    echo "Usage: write-stub.sh <path> <title> [--force]" >&2
    exit 2
fi

PATHARG="$1"
TITLE="$2"
FORCE=0
[ "${3:-}" = "--force" ] && FORCE=1

if [ -e "$PATHARG" ] && [ "$FORCE" -ne 1 ]; then
    # File already in place — leave it alone. This is the common case
    # for re-runs of init-project / attach-project.
    exit 3
fi

mkdir -p "$(dirname "$PATHARG")"
{
    printf '# %s\n\n' "$TITLE"
    printf '*to be filled*\n'
} > "$PATHARG"
