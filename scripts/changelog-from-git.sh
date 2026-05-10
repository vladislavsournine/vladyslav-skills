#!/usr/bin/env bash
# changelog-from-git.sh — emit a Markdown CHANGELOG section from git history.
#
# Usage: changelog-from-git.sh <version> [since-ref]
#   version    — semver string for the new section heading, e.g. "2.3.0"
#   since-ref  — git ref to diff against; defaults to the most recent tag
#                matching v* (or the empty repo if none exists).
#
# Output (stdout):
#
#   ## v<version> — <today YYYY-MM-DD>
#
#   ### Added
#   - <commit subject> [<short hash>]
#
#   ### Changed
#   - ...
#
#   ### Fixed
#   - ...
#
# Buckets are derived from conventional-commit prefixes:
#   feat / feature  → Added
#   refactor / chore / build / docs / perf / style → Changed
#   fix / bug       → Fixed
#   anything else   → Changed (fallback)
#
# Designed as a starting point — the human is expected to edit the result
# before committing the CHANGELOG. Do NOT pipe directly into the file.

set -u

if [ $# -lt 1 ]; then
    echo "Usage: changelog-from-git.sh <version> [since-ref]" >&2
    exit 2
fi

VERSION="$1"
SINCE="${2:-}"

if [ -z "$SINCE" ]; then
    SINCE="$(git describe --tags --match 'v*' --abbrev=0 2>/dev/null || echo '')"
fi

# Gather commits with subject + short hash. Reverse chronological by default —
# we keep that order in each bucket to mirror what the user sees in `git log`.
RANGE_ARG=""
[ -n "$SINCE" ] && RANGE_ARG="$SINCE..HEAD"

LOG="$(git log --no-merges --pretty='%h%x09%s' $RANGE_ARG 2>/dev/null)"
if [ -z "$LOG" ]; then
    echo "changelog-from-git: no commits in range ${SINCE:-<repo start>}..HEAD" >&2
    exit 1
fi

DATE="$(date +%Y-%m-%d)"

added=""
changed=""
fixed=""

while IFS=$'\t' read -r hash subject; do
    [ -z "$hash" ] && continue
    line="- ${subject} [${hash}]"
    case "$subject" in
        feat:*|feat\(*\):*|feature:*|feature\(*\):*)
            added="${added}${line}"$'\n' ;;
        fix:*|fix\(*\):*|bug:*|bug\(*\):*)
            fixed="${fixed}${line}"$'\n' ;;
        refactor:*|refactor\(*\):*|chore:*|chore\(*\):*|build:*|build\(*\):*|docs:*|docs\(*\):*|perf:*|perf\(*\):*|style:*|style\(*\):*|test:*|test\(*\):*)
            changed="${changed}${line}"$'\n' ;;
        *)
            changed="${changed}${line}"$'\n' ;;
    esac
done <<< "$LOG"

printf '## v%s — %s\n\n' "$VERSION" "$DATE"

if [ -n "$added" ]; then
    printf '### Added\n\n'
    printf '%s\n' "${added%$'\n'}"
fi
if [ -n "$changed" ]; then
    printf '### Changed\n\n'
    printf '%s\n' "${changed%$'\n'}"
fi
if [ -n "$fixed" ]; then
    printf '### Fixed\n\n'
    printf '%s\n' "${fixed%$'\n'}"
fi
