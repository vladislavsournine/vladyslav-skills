#!/usr/bin/env bash
# gather-seed-signals.sh — collect MemPalace seed signals from git log,
# package manifests, and existing docs. Emits JSON for the `ingest` skill
# to feed into its LLM record-extraction step.
#
# Pairs with scan-architecture.sh: scan-architecture provides the
# "what does the code look like" snapshot, gather-seed-signals provides
# the "what changed historically and why" snapshot. Together they're the
# only file-system reads `ingest` needs before the LLM step.
#
# Usage:
#   gather-seed-signals.sh --pwd <project-dir>
#
# Output: JSON to stdout
#   {
#     "git": {
#       "available":         true|false,
#       "head_commit":       "<short sha>",
#       "branch":            "<current branch>",
#       "first_commit_date": "<YYYY-MM-DD>",
#       "recent_themes":     [<commit subject>, ...],   // last 30 non-merge
#       "decision_commits":  [<commit subject>, ...],   // grep feat/refactor/fix/decision
#       "most_edited":       [{"path": "...", "edits": N}, ...]  // top 10 last 100 commits
#     },
#     "manifests":      {<path>: <summary>},
#     "existing_docs":  [<paths>],
#     "adr_files":      [<paths>],   // docs/architecture/adr/*.md
#     "claude_md":      {"exists": true|false, "size": <bytes>},
#     "warnings":       [<msgs>]
#   }
#
# Exit codes: 0 always (overall info), 2 on bad args.

set -u

PROJECT_PWD=""
while [ $# -gt 0 ]; do
    case "$1" in
        --pwd) PROJECT_PWD="$2"; shift 2 ;;
        *) echo "unknown: $1" >&2; exit 2 ;;
    esac
done

[ -z "$PROJECT_PWD" ] && { echo "--pwd required" >&2; exit 2; }
[ -d "$PROJECT_PWD" ] || { echo "pwd not found: $PROJECT_PWD" >&2; exit 2; }

cd "$PROJECT_PWD" || exit 2

WARNINGS=()

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/\\r}"
    printf '%s' "$s"
}

# ─── git signals ────────────────────────────────────────────────────────

GIT_AVAILABLE="false"
HEAD_SHA=""
BRANCH=""
FIRST_DATE=""
RECENT_THEMES_JSON="[]"
DECISION_COMMITS_JSON="[]"
MOST_EDITED_JSON="[]"

if git rev-parse --git-dir >/dev/null 2>&1; then
    GIT_AVAILABLE="true"
    HEAD_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo '')"
    BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
    FIRST_DATE="$(git log --reverse --pretty='%ad' --date=short -1 2>/dev/null || echo '')"

    # Recent themes — last 30 non-merge commit subjects (cap message length)
    RECENT_THEMES_JSON="$(
        git log --no-merges --pretty='%s' -30 2>/dev/null \
        | awk -v escaper=1 '
            BEGIN { print "["; first=1 }
            {
                if (length($0) > 100) $0 = substr($0, 1, 100) "..."
                gsub(/\\/, "\\\\")
                gsub(/"/, "\\\"")
                if (!first) printf ","
                printf "\"%s\"", $0
                first=0
            }
            END { print "]" }
        '
    )"
    [ -z "$RECENT_THEMES_JSON" ] && RECENT_THEMES_JSON="[]"

    # Decision-ish commits (feat / refactor / fix / decision in subject)
    DECISION_COMMITS_JSON="$(
        git log --no-merges --pretty='%s' --all 2>/dev/null \
        | grep -iE '^(feat|refactor|fix|decision|chore\(release|release):' \
        | head -40 \
        | awk '
            BEGIN { print "["; first=1 }
            {
                if (length($0) > 100) $0 = substr($0, 1, 100) "..."
                gsub(/\\/, "\\\\")
                gsub(/"/, "\\\"")
                if (!first) printf ","
                printf "\"%s\"", $0
                first=0
            }
            END { print "]" }
        '
    )"
    [ -z "$DECISION_COMMITS_JSON" ] && DECISION_COMMITS_JSON="[]"

    # Most-edited files in the last 100 commits — gives a rough hotspot map
    MOST_EDITED_JSON="$(
        git log --no-merges --name-only --pretty=format: -100 2>/dev/null \
        | grep -v '^$' \
        | sort | uniq -c | sort -rn | head -10 \
        | awk '
            BEGIN { print "["; first=1 }
            {
                n=$1
                # everything after the count is the path
                path=$0; sub(/^ *[0-9]+ +/, "", path)
                gsub(/\\/, "\\\\", path)
                gsub(/"/, "\\\"", path)
                if (!first) printf ","
                printf "{\"path\":\"%s\",\"edits\":%d}", path, n
                first=0
            }
            END { print "]" }
        '
    )"
    [ -z "$MOST_EDITED_JSON" ] && MOST_EDITED_JSON="[]"
else
    WARNINGS+=("not a git repository — git signals empty")
fi

# ─── package manifests (re-summarise; same set as scan-architecture) ─────

MANIFESTS_JSON="{"
mf_first=1

add_manifest() {
    local path="$1" summary="$2"
    [ ! -f "$path" ] && return 0
    [ $mf_first -eq 1 ] || MANIFESTS_JSON+=","
    mf_first=0
    MANIFESTS_JSON+="\"$path\":\"$(json_escape "$summary")\""
}

add_manifest "package.json"               "$(grep -E '"(name|version|description)"' package.json 2>/dev/null | head -5 | tr '\n' ' ' | head -c 200)"
add_manifest "pyproject.toml"             "$(grep -E '^(name|version|description) *=' pyproject.toml 2>/dev/null | head -5 | tr '\n' ' ' | head -c 200)"
add_manifest "requirements.txt"           "$(head -20 requirements.txt 2>/dev/null | tr '\n' ',' | head -c 200)"
add_manifest "backend/requirements.txt"   "$(head -20 backend/requirements.txt 2>/dev/null | tr '\n' ',' | head -c 200)"
add_manifest "go.mod"                     "$(head -5 go.mod 2>/dev/null | tr '\n' ' ' | head -c 200)"
add_manifest "backend/go.mod"             "$(head -5 backend/go.mod 2>/dev/null | tr '\n' ' ' | head -c 200)"
add_manifest "pubspec.yaml"               "$(grep -E '^(name|version|description):' pubspec.yaml 2>/dev/null | head -5 | tr '\n' ' ' | head -c 200)"
add_manifest "Package.swift"              "$(head -10 Package.swift 2>/dev/null | tr '\n' ' ' | head -c 200)"
add_manifest "Cargo.toml"                 "$(grep -E '^(name|version|description) *=' Cargo.toml 2>/dev/null | head -5 | tr '\n' ' ' | head -c 200)"
add_manifest "build.gradle"               "$(head -20 build.gradle 2>/dev/null | tr '\n' ' ' | head -c 200)"
add_manifest "build.gradle.kts"           "$(head -20 build.gradle.kts 2>/dev/null | tr '\n' ' ' | head -c 200)"
add_manifest ".claude-plugin/plugin.json" "$(grep -E '"(name|version|description)"' .claude-plugin/plugin.json 2>/dev/null | head -5 | tr '\n' ' ' | head -c 200)"

MANIFESTS_JSON+="}"

# ─── existing docs ─────────────────────────────────────────────────────

EXISTING_DOCS_JSON="["
ed_first=1
if [ -d docs ]; then
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        [ $ed_first -eq 1 ] || EXISTING_DOCS_JSON+=","
        ed_first=0
        EXISTING_DOCS_JSON+="\"$(json_escape "$f")\""
    done < <(find docs -type f -name '*.md' 2>/dev/null | sort)
fi
EXISTING_DOCS_JSON+="]"

# ─── ADR files specifically (decisions log) ─────────────────────────────

ADR_JSON="["
adr_first=1
for adr_dir in docs/architecture/adr docs/adr docs/decisions; do
    [ -d "$adr_dir" ] || continue
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        [ $adr_first -eq 1 ] || ADR_JSON+=","
        adr_first=0
        ADR_JSON+="\"$(json_escape "$f")\""
    done < <(find "$adr_dir" -maxdepth 2 -type f -name '*.md' 2>/dev/null | sort)
done
ADR_JSON+="]"

# ─── CLAUDE.md ──────────────────────────────────────────────────────────

CLAUDE_EXISTS="false"
CLAUDE_SIZE=0
if [ -f CLAUDE.md ]; then
    CLAUDE_EXISTS="true"
    CLAUDE_SIZE="$(wc -c < CLAUDE.md | tr -d ' ')"
fi

# ─── warnings ──────────────────────────────────────────────────────────

WARN_JSON="["
w_first=1
for w in "${WARNINGS[@]:-}"; do
    [ -z "$w" ] && continue
    [ $w_first -eq 1 ] || WARN_JSON+=","
    w_first=0
    WARN_JSON+="\"$(json_escape "$w")\""
done
WARN_JSON+="]"

# ─── emit ──────────────────────────────────────────────────────────────

printf '{"git":{"available":%s,"head_commit":"%s","branch":"%s","first_commit_date":"%s","recent_themes":%s,"decision_commits":%s,"most_edited":%s},"manifests":%s,"existing_docs":%s,"adr_files":%s,"claude_md":{"exists":%s,"size":%s},"warnings":%s}\n' \
    "$GIT_AVAILABLE" \
    "$HEAD_SHA" \
    "$BRANCH" \
    "$FIRST_DATE" \
    "$RECENT_THEMES_JSON" \
    "$DECISION_COMMITS_JSON" \
    "$MOST_EDITED_JSON" \
    "$MANIFESTS_JSON" \
    "$EXISTING_DOCS_JSON" \
    "$ADR_JSON" \
    "$CLAUDE_EXISTS" \
    "$CLAUDE_SIZE" \
    "$WARN_JSON"
