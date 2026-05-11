#!/usr/bin/env bash
# scan-architecture.sh — gather a structured inventory of a project's
# architecture for analyze-project (and seed-mempalace) to consume.
#
# The narrative — what the architecture MEANS — is LLM work. This script
# does the mechanical part: detect stacks, list entry points, grep routes,
# enumerate migrations, summarize dependencies. JSON output.
#
# Usage:
#   scan-architecture.sh --pwd <project-dir>
#
# Output: JSON to stdout
#   {
#     "stacks":      <detect-stack.sh result>,
#     "entry_points": [<paths likely to be `main`/`index`/`App`>],
#     "routes": {
#         "framework": "fastapi|flask|express|gin|chi|none",
#         "handlers":  [{"method": "GET|POST|...", "path": "...", "file": "..."}]
#     },
#     "schema_files":  [<paths>],
#     "deps":          {<manifest path>: <summary>},
#     "doc_files":     [<paths under docs/>],
#     "warnings":      [<msgs>]
#   }
#
# Exit codes: 0 always (overall info, not pass/fail), 2 on bad args.

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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_PWD" || exit 2

WARNINGS=()

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

# ─── stacks (delegate to detect-stack.sh) ───────────────────────────────

if [ -x "$SCRIPT_DIR/detect-stack.sh" ]; then
    STACKS_JSON="$("$SCRIPT_DIR/detect-stack.sh" "$PROJECT_PWD")"
else
    STACKS_JSON='{}'
    WARNINGS+=("detect-stack.sh not found")
fi

# ─── entry points ──────────────────────────────────────────────────────

ENTRY_POINTS=()

# Python: src/main.py, app.py, server.py, manage.py
for f in src/main.py main.py app.py server.py manage.py backend/src/main.py backend/main.py; do
    [ -f "$f" ] && ENTRY_POINTS+=("$f")
done

# Go: cmd/*/main.go
while IFS= read -r f; do
    [ -n "$f" ] && ENTRY_POINTS+=("$f")
done < <(find . -maxdepth 4 -path '*/cmd/*/main.go' -not -path '*/vendor/*' 2>/dev/null)

# Node: index.js, src/index.js, server.js
for f in index.js src/index.js src/index.ts server.js src/server.ts; do
    [ -f "$f" ] && ENTRY_POINTS+=("$f")
done

# Swift: *App.swift
while IFS= read -r f; do
    [ -n "$f" ] && ENTRY_POINTS+=("$f")
done < <(find . -maxdepth 4 -name '*App.swift' -not -path '*/build/*' -not -path '*/DerivedData/*' 2>/dev/null)

# Flutter: lib/main.dart
[ -f lib/main.dart ] && ENTRY_POINTS+=("lib/main.dart")

# ─── routes ────────────────────────────────────────────────────────────

ROUTES_FRAMEWORK="none"
ROUTES_TMP=$(mktemp)

# FastAPI: @app.get("/x"), @app.post("/x"), @router.get(...)
if grep -rEln --include='*.py' --exclude-dir=.venv --exclude-dir=__pycache__ \
    'from fastapi import|FastAPI\(' . 2>/dev/null | head -1 | grep -q .; then
    ROUTES_FRAMEWORK="fastapi"
    grep -rEn --include='*.py' --exclude-dir=.venv --exclude-dir=__pycache__ \
        '@(app|router)\.(get|post|put|patch|delete|head|options)\(' . 2>/dev/null | \
    while IFS=: read -r file line content; do
        method=$(echo "$content" | grep -oE '@(app|router)\.[a-z]+' | sed 's/.*\.//')
        path=$(echo "$content" | grep -oE '"[^"]+"' | head -1 | sed 's/"//g')
        [ -n "$method" ] && [ -n "$path" ] && \
            printf '%s\t%s\t%s\n' "$(echo "$method" | tr '[:lower:]' '[:upper:]')" "$path" "$file" >> "$ROUTES_TMP"
    done
fi

# Flask
if [ "$ROUTES_FRAMEWORK" = "none" ] && \
    grep -rEln --include='*.py' --exclude-dir=.venv 'from flask import|Flask\(' . 2>/dev/null | head -1 | grep -q .; then
    ROUTES_FRAMEWORK="flask"
    grep -rEn --include='*.py' --exclude-dir=.venv \
        '@(app|bp|blueprint)\.route\(' . 2>/dev/null | \
    while IFS=: read -r file line content; do
        path=$(echo "$content" | grep -oE '"[^"]+"' | head -1 | sed 's/"//g')
        method=$(echo "$content" | grep -oE 'methods=\[[^]]+\]' | grep -oE '"[A-Z]+"' | head -1 | sed 's/"//g')
        [ -z "$method" ] && method="GET"
        [ -n "$path" ] && printf '%s\t%s\t%s\n' "$method" "$path" "$file" >> "$ROUTES_TMP"
    done
fi

# Express
if [ "$ROUTES_FRAMEWORK" = "none" ] && \
    grep -rEln --include='*.js' --include='*.ts' --exclude-dir=node_modules \
    "require\('express'\)|from ['\"]express['\"]" . 2>/dev/null | head -1 | grep -q .; then
    ROUTES_FRAMEWORK="express"
    grep -rEn --include='*.js' --include='*.ts' --exclude-dir=node_modules \
        "(app|router)\.(get|post|put|patch|delete|head)\(['\"]" . 2>/dev/null | \
    while IFS=: read -r file line content; do
        method=$(echo "$content" | grep -oE '\.(get|post|put|patch|delete|head)' | sed 's/^\.//' | head -1)
        path=$(echo "$content" | grep -oE "['\"][^'\"]+['\"]" | head -1 | sed "s/['\"]//g")
        [ -n "$method" ] && [ -n "$path" ] && \
            printf '%s\t%s\t%s\n' "$(echo "$method" | tr '[:lower:]' '[:upper:]')" "$path" "$file" >> "$ROUTES_TMP"
    done
fi

# Go net/http stdlib (1.22+ pattern) and Chi
if [ "$ROUTES_FRAMEWORK" = "none" ] && [ -f go.mod ]; then
    if grep -rEln --include='*.go' --exclude-dir=vendor \
        '\.(HandleFunc|Handle)\("(GET|POST|PUT|PATCH|DELETE) ' . 2>/dev/null | head -1 | grep -q .; then
        ROUTES_FRAMEWORK="go-stdlib"
        grep -rEn --include='*.go' --exclude-dir=vendor \
            '\.(HandleFunc|Handle)\("(GET|POST|PUT|PATCH|DELETE) [^"]+"' . 2>/dev/null | \
        while IFS=: read -r file line content; do
            method_and_path=$(echo "$content" | grep -oE '"(GET|POST|PUT|PATCH|DELETE) [^"]+"' | head -1 | sed 's/"//g')
            method=$(echo "$method_and_path" | awk '{print $1}')
            path=$(echo "$method_and_path" | awk '{print $2}')
            [ -n "$method" ] && [ -n "$path" ] && printf '%s\t%s\t%s\n' "$method" "$path" "$file" >> "$ROUTES_TMP"
        done
    fi
fi

# Build routes JSON
HANDLERS_JSON="["
if [ -s "$ROUTES_TMP" ]; then
    first=1
    while IFS=$'\t' read -r method path file; do
        [ $first -eq 1 ] || HANDLERS_JSON+=","
        first=0
        HANDLERS_JSON+="{\"method\":\"$method\",\"path\":\"$(json_escape "$path")\",\"file\":\"$(json_escape "$file")\"}"
    done < "$ROUTES_TMP"
fi
HANDLERS_JSON+="]"
rm -f "$ROUTES_TMP"

ROUTES_JSON="{\"framework\":\"$ROUTES_FRAMEWORK\",\"handlers\":$HANDLERS_JSON}"

# ─── schema files ──────────────────────────────────────────────────────

SCHEMA_FILES=()
# SQL schemas
while IFS= read -r f; do
    [ -n "$f" ] && SCHEMA_FILES+=("$f")
done < <(find . -maxdepth 5 \( -name 'schema.sql' -o -name 'db-schema.sql' -o -name '*.sql' -path '*/migrations/*' \) \
    -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null | head -50)
# Prisma / Drizzle / TypeORM
[ -f prisma/schema.prisma ] && SCHEMA_FILES+=("prisma/schema.prisma")
[ -f drizzle.config.ts ] && SCHEMA_FILES+=("drizzle.config.ts")
# Alembic / Django migrations
while IFS= read -r f; do
    [ -n "$f" ] && SCHEMA_FILES+=("$f")
done < <(find . -maxdepth 5 -path '*/alembic/versions/*.py' 2>/dev/null | head -20)

# ─── deps (manifest summary) ───────────────────────────────────────────

DEPS_JSON="{"
deps_first=1

add_dep() {
    local path="$1" summary="$2"
    [ $deps_first -eq 1 ] || DEPS_JSON+=","
    deps_first=0
    DEPS_JSON+="\"$path\":\"$(json_escape "$summary")\""
}

[ -f requirements.txt ] && add_dep "requirements.txt" "$(head -20 requirements.txt | tr '\n' ',' | sed 's/,$//')"
[ -f backend/requirements.txt ] && add_dep "backend/requirements.txt" "$(head -20 backend/requirements.txt | tr '\n' ',' | sed 's/,$//')"
[ -f pyproject.toml ] && add_dep "pyproject.toml" "$(grep -A 5 '\[project\]\|\[tool.poetry.dependencies\]' pyproject.toml | head -10 | tr '\n' ' ' | head -c 200)"
[ -f go.mod ] && add_dep "go.mod" "$(head -10 go.mod | tr '\n' ' ' | head -c 200)"
[ -f backend/go.mod ] && add_dep "backend/go.mod" "$(head -10 backend/go.mod | tr '\n' ' ' | head -c 200)"
[ -f package.json ] && add_dep "package.json" "$(grep -E '"(name|dependencies|devDependencies)"' package.json | head -10 | tr '\n' ' ' | head -c 200)"
[ -f Cargo.toml ] && add_dep "Cargo.toml" "$(grep -A 5 '\[dependencies\]' Cargo.toml | head -10 | tr '\n' ' ' | head -c 200)"

DEPS_JSON+="}"

# ─── doc files under docs/ ─────────────────────────────────────────────

DOC_FILES_JSON="["
if [ -d docs ]; then
    doc_first=1
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        [ $doc_first -eq 1 ] || DOC_FILES_JSON+=","
        doc_first=0
        DOC_FILES_JSON+="\"$(json_escape "$f")\""
    done < <(find docs -type f \( -name '*.md' -o -name '*.sql' \) 2>/dev/null | sort)
fi
DOC_FILES_JSON+="]"

# ─── entry points JSON ─────────────────────────────────────────────────

EP_JSON="["
ep_first=1
for ep in "${ENTRY_POINTS[@]:-}"; do
    [ -z "$ep" ] && continue
    [ $ep_first -eq 1 ] || EP_JSON+=","
    ep_first=0
    EP_JSON+="\"$(json_escape "$ep")\""
done
EP_JSON+="]"

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

printf '{"stacks":%s,"entry_points":%s,"routes":%s,"schema_files":[' \
    "$STACKS_JSON" "$EP_JSON" "$ROUTES_JSON"
sf_first=1
for sf in "${SCHEMA_FILES[@]:-}"; do
    [ -z "$sf" ] && continue
    [ $sf_first -eq 1 ] || printf ','
    sf_first=0
    printf '"%s"' "$(json_escape "$sf")"
done
printf '],"deps":%s,"doc_files":%s,"warnings":%s}\n' \
    "$DEPS_JSON" "$DOC_FILES_JSON" "$WARN_JSON"
