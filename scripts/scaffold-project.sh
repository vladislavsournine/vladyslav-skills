#!/usr/bin/env bash
# scaffold-project.sh — deterministic project scaffolder for `init-project`.
#
# This replaces the Sonnet subagent that v2.x used for the scaffold step.
# Everything the subagent did (mkdir, copy templates, sed-substitute, git
# init) is pure mechanics — no LLM thinking required — so it's done here
# in plain POSIX bash, in ~1 second instead of ~8 minutes / ~43k tokens.
#
# Usage:
#   scaffold-project.sh \
#       --pwd <project-dir> \
#       --name <project-name> \
#       --plugin-root <plugin-root> \
#       --backend <python|go|other|none> \
#       [--backend-other-label "Rust backend"] \
#       [--backend-other-dir rust] \
#       [--backend-other-gitignore "target/,Cargo.lock"] \
#       --frontend <comma-list: flutter,swift,kotlin,other,none> \
#       [--swift-bundle-id-prefix com.vlad] \
#       [--swift-deployment-target 17.0] \
#       [--frontend-other-label "RN frontend"] \
#       [--frontend-other-dir rn] \
#       [--frontend-other-gitignore ".cache/,node_modules/"] \
#       --domain <domain-or-empty> \
#       --private-mode <yes|no> \
#       --agents <comma-list: architect-reviewer,backend-engineer,...,none>
#
# Output: a single line of JSON on stdout describing the result:
#   { "status": "success" | "partial" | "error",
#     "files_written": [<paths>],
#     "files_skipped": [<paths>],
#     "warnings": [<msgs>],
#     "error": "<msg if status=error>" }
#
# Exit code: 0 on success/partial, 1 on error, 2 on bad arguments.
#
# Stack-specific instructions live next to this script:
#   <plugin-root>/skills/init-project/assets/    (templates copied verbatim)
#   <plugin-root>/skills/init-project/references/ (informational only — the
#                                                   scaffolder doesn't read them)

set -u

# ─── helpers ──────────────────────────────────────────────────────────────

WRITTEN=()
SKIPPED=()
WARNINGS=()

emit_json() {
    local status="$1" error_msg="${2:-}"
    local IFS=','
    printf '{"status":"%s","files_written":[' "$status"
    local first=1
    for f in "${WRITTEN[@]:-}"; do
        [ -z "$f" ] && continue
        [ $first -eq 1 ] || printf ','
        printf '"%s"' "$f"
        first=0
    done
    printf '],"files_skipped":['
    first=1
    for f in "${SKIPPED[@]:-}"; do
        [ -z "$f" ] && continue
        [ $first -eq 1 ] || printf ','
        printf '"%s"' "$f"
        first=0
    done
    printf '],"warnings":['
    first=1
    for w in "${WARNINGS[@]:-}"; do
        [ -z "$w" ] && continue
        [ $first -eq 1 ] || printf ','
        printf '"%s"' "$w"
        first=0
    done
    if [ -n "$error_msg" ]; then
        printf '],"error":"%s"}\n' "$error_msg"
    else
        printf ']}\n'
    fi
}

die() {
    WARNINGS+=("$1")
    emit_json "error" "$1"
    exit 1
}

mkpath() {
    local d="$1"
    mkdir -p "$d" || die "mkdir failed: $d"
}

write_file() {
    local path="$1" content="$2" overwrite="${3:-no}"
    if [ -f "$path" ] && [ "$overwrite" != "yes" ]; then
        SKIPPED+=("$path")
        return 0
    fi
    mkpath "$(dirname "$path")"
    printf '%s' "$content" > "$path" || die "write failed: $path"
    WRITTEN+=("$path")
}

copy_asset() {
    local src="$1" dest="$2"
    if [ ! -f "$src" ]; then
        die "asset not found: $src"
    fi
    if [ -f "$dest" ]; then
        SKIPPED+=("$dest")
        return 0
    fi
    mkpath "$(dirname "$dest")"
    cp "$src" "$dest" || die "copy failed: $src → $dest"
    WRITTEN+=("$dest")
}

substitute() {
    # In-place sed-substitute placeholders in a file.
    # Args: file, then pairs of (placeholder, replacement).
    local file="$1"; shift
    [ -f "$file" ] || die "substitute target missing: $file"
    while [ $# -ge 2 ]; do
        local placeholder="$1" replacement="$2"
        shift 2
        # Use | as sed delimiter to allow paths with /
        sed -i '' "s|${placeholder}|${replacement}|g" "$file"
    done
}

write_stub() {
    local path="$1" title="$2"
    [ -f "$path" ] && { SKIPPED+=("$path"); return 0; }
    mkpath "$(dirname "$path")"
    {
        printf '# %s\n\n' "$title"
        printf '*to be filled*\n'
    } > "$path"
    WRITTEN+=("$path")
}

# ─── arg parsing ──────────────────────────────────────────────────────────

PROJECT_PWD=""
PROJECT_NAME=""
PLUGIN_ROOT=""
BACKEND=""
BACKEND_OTHER_LABEL=""
BACKEND_OTHER_DIR=""
BACKEND_OTHER_GITIGNORE=""
FRONTEND=""
SWIFT_BUNDLE_PREFIX=""
SWIFT_DEPLOY_TARGET="17.0"
FRONTEND_OTHER_LABEL=""
FRONTEND_OTHER_DIR=""
FRONTEND_OTHER_GITIGNORE=""
DOMAIN=""
PRIVATE_MODE="no"
AGENTS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --pwd) PROJECT_PWD="$2"; shift 2 ;;
        --name) PROJECT_NAME="$2"; shift 2 ;;
        --plugin-root) PLUGIN_ROOT="$2"; shift 2 ;;
        --backend) BACKEND="$2"; shift 2 ;;
        --backend-other-label) BACKEND_OTHER_LABEL="$2"; shift 2 ;;
        --backend-other-dir) BACKEND_OTHER_DIR="$2"; shift 2 ;;
        --backend-other-gitignore) BACKEND_OTHER_GITIGNORE="$2"; shift 2 ;;
        --frontend) FRONTEND="$2"; shift 2 ;;
        --swift-bundle-id-prefix) SWIFT_BUNDLE_PREFIX="$2"; shift 2 ;;
        --swift-deployment-target) SWIFT_DEPLOY_TARGET="$2"; shift 2 ;;
        --frontend-other-label) FRONTEND_OTHER_LABEL="$2"; shift 2 ;;
        --frontend-other-dir) FRONTEND_OTHER_DIR="$2"; shift 2 ;;
        --frontend-other-gitignore) FRONTEND_OTHER_GITIGNORE="$2"; shift 2 ;;
        --domain) DOMAIN="$2"; shift 2 ;;
        --private-mode) PRIVATE_MODE="$2"; shift 2 ;;
        --agents) AGENTS="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Required
[ -z "$PROJECT_PWD" ]  && { echo "--pwd required" >&2; exit 2; }
[ -z "$PROJECT_NAME" ] && { echo "--name required" >&2; exit 2; }
[ -z "$PLUGIN_ROOT" ]  && { echo "--plugin-root required" >&2; exit 2; }
[ -z "$BACKEND" ]      && { echo "--backend required" >&2; exit 2; }
[ -z "$FRONTEND" ]     && { echo "--frontend required" >&2; exit 2; }

[ -d "$PROJECT_PWD" ]  || die "project pwd does not exist: $PROJECT_PWD"
[ -d "$PLUGIN_ROOT" ]  || die "plugin root does not exist: $PLUGIN_ROOT"

ASSETS="$PLUGIN_ROOT/skills/init-project/assets"
[ -d "$ASSETS" ] || die "assets dir not found: $ASSETS"

cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

# Lowercase project name for substitutions like Go module paths
PROJECT_NAME_LOWER="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"

# Derive flags from FRONTEND list
has_frontend() {
    case ",$FRONTEND," in *",$1,"*) return 0 ;; esac
    return 1
}

# Derive flags from AGENTS list
has_agent() {
    case ",$AGENTS," in *",$1,"*) return 0 ;; esac
    return 1
}

# ─── Step 1: base directories ─────────────────────────────────────────────

for d in \
    .claude/agents \
    docs/product \
    docs/architecture/adr \
    docs/ux \
    docs/plans \
    docs/testing \
    docs/release \
    docs/operations \
    docs/marketing ; do
    mkpath "$d"
done

# ─── Step 2: base .gitignore ──────────────────────────────────────────────

GITIGNORE_BASE=".DS_Store
.AppleDouble
.idea/
.vscode/
*.swp
*.swo
.claude/settings.local.json
.env
.env.*
!.env.example
secrets/
*.log
logs/
build/
dist/
coverage/
"

write_file ".gitignore" "$GITIGNORE_BASE"

append_gitignore() {
    local lines="$1"
    printf '%s\n' "$lines" >> .gitignore
}

# ─── Step 3: stack-specific scaffolding ───────────────────────────────────

UI_PROJECT=0
BACKEND_PRESENT=0

# Backend: Python
if [ "$BACKEND" = "python" ]; then
    BACKEND_PRESENT=1
    mkpath backend/admin
    mkpath backend/src
    mkpath backend/migrations
    mkpath backend/secrets

    append_gitignore "
# Python
__pycache__/
*.pyc
.venv/"

    write_file backend/requirements.txt "fastapi>=0.115.0
uvicorn[standard]>=0.30.0
gunicorn>=23.0.0
psycopg2-binary>=2.9.9
redis>=5.0.0
"

    write_file backend/src/__init__.py ""

    write_file backend/src/main.py "from fastapi import FastAPI

app = FastAPI(title=\"${PROJECT_NAME}\")


@app.get(\"/health\")
def health():
    return {\"status\": \"ok\"}


@app.get(\"/\")
def root():
    return {\"status\": \"running\"}
"

    write_file backend/Dockerfile "# syntax=docker/dockerfile:1.6
FROM python:3.12-slim AS base
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

FROM base AS dev
CMD [\"uvicorn\", \"src.main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"8000\", \"--reload\"]

FROM base AS prod
CMD [\"gunicorn\", \"src.main:app\", \"-k\", \"uvicorn.workers.UvicornWorker\", \"-b\", \"0.0.0.0:8000\", \"--workers\", \"4\"]
"

    ENV_DOMAIN_LINE="APP_DOMAIN=localhost"
    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "localhost only" ] && [ "$DOMAIN" != "localhost" ]; then
        ENV_DOMAIN_LINE="APP_DOMAIN=${DOMAIN}
ADMIN_URL=admin.${DOMAIN}
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET="
    fi

    write_file backend/.env.example "APP_ENV=dev
APP_PORT=8000
APP_SECRET_KEY=
DATABASE_URL=postgresql://user:pass@db:5432/app
REDIS_URL=redis://redis:6379/0
${ENV_DOMAIN_LINE}
"
    write_file backend/.env "# DO NOT COMMIT — copy .env.example and fill values
"
    write_file backend/secrets/.gitkeep ""

    # Docker compose files
    copy_asset "$ASSETS/backend/docker-compose.yml" backend/docker-compose.yml
    copy_asset "$ASSETS/backend/docker-compose.prod.yml" backend/docker-compose.prod.yml
    copy_asset "$ASSETS/backend/docker-compose.prod-selfhosted.yml" backend/docker-compose.prod-selfhosted.yml

    # Drop certbot section if no domain
    if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "localhost only" ] || [ "$DOMAIN" = "localhost" ]; then
        WARNINGS+=("no domain set — review docker-compose.prod*.yml to remove certbot if applicable")
    fi
fi

# Backend: Go
if [ "$BACKEND" = "go" ]; then
    BACKEND_PRESENT=1
    mkpath backend/cmd/server
    mkpath backend/admin
    mkpath backend/migrations
    mkpath backend/secrets

    append_gitignore "
# Go
/tmp/
vendor/"

    write_file backend/go.mod "module github.com/${PROJECT_NAME_LOWER}

go 1.22
"

    write_file backend/cmd/server/main.go 'package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]string{"status": "ok"})
	})
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]string{"status": "running"})
	})

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("listening on :%s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
'

    write_file backend/.air.toml '[build]
cmd = "go build -o tmp/server ./cmd/server"
bin = "tmp/server"
include_ext = ["go", "tpl", "tmpl", "html"]
exclude_dir = ["assets", "tmp", "vendor"]
'

    write_file backend/.env.example "APP_ENV=dev
APP_PORT=8080
APP_SECRET_KEY=
DATABASE_URL=postgresql://user:pass@db:5432/app
REDIS_URL=redis://redis:6379/0
APP_DOMAIN=${DOMAIN:-localhost}
"
    write_file backend/.env "# DO NOT COMMIT — copy .env.example and fill values
"
    write_file backend/secrets/.gitkeep ""

    copy_asset "$ASSETS/backend/docker-compose.yml" backend/docker-compose.yml
    copy_asset "$ASSETS/backend/docker-compose.prod.yml" backend/docker-compose.prod.yml
    copy_asset "$ASSETS/backend/docker-compose.prod-selfhosted.yml" backend/docker-compose.prod-selfhosted.yml
fi

# Backend: "other"
if [ "$BACKEND" = "other" ] && [ -n "$BACKEND_OTHER_DIR" ]; then
    BACKEND_PRESENT=1
    mkpath "$BACKEND_OTHER_DIR"
    write_file "$BACKEND_OTHER_DIR/.gitkeep" ""
    if [ -n "$BACKEND_OTHER_GITIGNORE" ]; then
        append_gitignore "
# ${BACKEND_OTHER_LABEL}"
        printf '%s' "$BACKEND_OTHER_GITIGNORE" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | while read -r line; do
            [ -n "$line" ] && printf '%s\n' "$line" >> .gitignore
        done
    fi
fi

# Backend-shared: docker docs and nginx (Python or Go)
if [ "$BACKEND_PRESENT" -eq 1 ]; then
    copy_asset "$ASSETS/docs/operations/docker.md" docs/operations/docker.md

    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "localhost only" ] && [ "$DOMAIN" != "localhost" ]; then
        mkpath infra/nginx
        copy_asset "$ASSETS/infra/nginx.conf" infra/nginx/nginx.conf
        substitute infra/nginx/nginx.conf "APP_DOMAIN" "$DOMAIN"
    fi
fi

# Frontend: Swift
if has_frontend "swift"; then
    UI_PROJECT=1
    mkpath app/Resources
    mkpath tests

    append_gitignore "
# Swift
DerivedData/
*.xcuserstate
*.xcworkspace/xcuserdata/
*.xcodeproj/
Pods/"

    # project.yml from asset
    copy_asset "$ASSETS/swift/project.yml" project.yml
    substitute project.yml \
        "PROJECT_NAME" "$PROJECT_NAME" \
        "BUNDLE_ID_PREFIX" "${SWIFT_BUNDLE_PREFIX:-com.example}" \
        "PROJECT_NAME_LOWER" "$PROJECT_NAME_LOWER" \
        "DEPLOYMENT_TARGET" "$SWIFT_DEPLOY_TARGET"

    write_file app/Info.plist '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UILaunchScreen</key>
    <dict/>
</dict>
</plist>
'

    write_file "app/${PROJECT_NAME}App.swift" "import SwiftUI

@main
struct ${PROJECT_NAME}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
"

    write_file app/ContentView.swift 'import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
'

    write_file .claude/settings.local.json '{
  "permissions": {
    "allow": ["Bash(xcodegen:*)", "Bash(xcodebuild:*)"]
  }
}
'

    # Generate xcodeproj if xcodegen is available
    if command -v xcodegen >/dev/null 2>&1; then
        if ! xcodegen generate >/dev/null 2>&1; then
            WARNINGS+=("xcodegen generate failed — run manually after install")
        fi
    else
        WARNINGS+=("xcodegen not installed — run 'brew install xcodegen && xcodegen generate' to produce .xcodeproj")
    fi
fi

# Frontend: Flutter
if has_frontend "flutter"; then
    UI_PROJECT=1
    mkpath flutter
    write_file flutter/.gitkeep ""
    append_gitignore "
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
*.iml
.metadata"
fi

# Frontend: Kotlin
if has_frontend "kotlin"; then
    UI_PROJECT=1
    mkpath kotlin
    write_file kotlin/.gitkeep ""
    append_gitignore "
# Kotlin / Android
.gradle/
out/
build/
local.properties
*.iml"
fi

# Frontend: other
if has_frontend "other" && [ -n "$FRONTEND_OTHER_DIR" ]; then
    UI_PROJECT=1
    mkpath "$FRONTEND_OTHER_DIR"
    write_file "$FRONTEND_OTHER_DIR/.gitkeep" ""
    if [ -n "$FRONTEND_OTHER_GITIGNORE" ]; then
        append_gitignore "
# ${FRONTEND_OTHER_LABEL}"
        printf '%s' "$FRONTEND_OTHER_GITIGNORE" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | while read -r line; do
            [ -n "$line" ] && printf '%s\n' "$line" >> .gitignore
        done
    fi
fi

# Private mode: append AI workflow files to .gitignore
if [ "$PRIVATE_MODE" = "yes" ]; then
    append_gitignore "
# Private mode — AI workflow files
CLAUDE.md
.claude/
docs/plans/
docs/operations/
docs/marketing/"
fi

# ─── Step 4: CLAUDE.md ────────────────────────────────────────────────────

STACK_LINES=""
[ "$BACKEND" = "python" ] && STACK_LINES="${STACK_LINES}- Python backend (FastAPI)\n"
[ "$BACKEND" = "go" ] && STACK_LINES="${STACK_LINES}- Go backend\n"
[ "$BACKEND" = "other" ] && STACK_LINES="${STACK_LINES}- ${BACKEND_OTHER_LABEL} (in ${BACKEND_OTHER_DIR}/)\n"
has_frontend "swift"   && STACK_LINES="${STACK_LINES}- iOS Swift / SwiftUI\n"
has_frontend "flutter" && STACK_LINES="${STACK_LINES}- Flutter\n"
has_frontend "kotlin"  && STACK_LINES="${STACK_LINES}- Kotlin / Android\n"
has_frontend "other"   && STACK_LINES="${STACK_LINES}- ${FRONTEND_OTHER_LABEL} (in ${FRONTEND_OTHER_DIR}/)\n"
[ -z "$STACK_LINES" ] && STACK_LINES="- to be filled\n"

API_DOC_LINE=""
DB_SCHEMA_LINE=""
if [ "$BACKEND_PRESENT" -eq 1 ]; then
    API_DOC_LINE="| \`docs/architecture/api.md\` | API endpoints and contracts |"
    DB_SCHEMA_LINE="| \`docs/architecture/db-schema.sql\` | Database schema |"
fi

PROJECT_TYPE="to be filled"
if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "localhost only" ] && [ "$DOMAIN" != "localhost" ]; then
    PROJECT_TYPE="$DOMAIN"
fi

# Use a heredoc with sed-friendly placeholders.
CLAUDE_MD_CONTENT="# ${PROJECT_NAME}

## Project Type

${PROJECT_TYPE}

## Stack

$(printf '%b' "$STACK_LINES")

## Source of Truth

| Doc | Purpose |
|-----|---------|
| \`docs/product/prd.md\` | Product requirements |
| \`docs/product/user-stories.md\` | User stories |
| \`docs/architecture/system.md\` | Architecture overview |
| \`docs/plans/tasks.md\` | Active tasks |"

if [ -n "$API_DOC_LINE" ]; then
    CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT}
${API_DOC_LINE}"
fi
if [ -n "$DB_SCHEMA_LINE" ]; then
    CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT}
${DB_SCHEMA_LINE}"
fi

CLAUDE_MD_CONTENT="${CLAUDE_MD_CONTENT}

## Working Rules

- Do not add translations until the finalization phase (pre-release-check)
- <add project-specific rules here>
"

write_file CLAUDE.md "$CLAUDE_MD_CONTENT"

# ─── Step 5: .claude/settings.json ────────────────────────────────────────

write_file .claude/settings.json '{
  "env": {
    "PROJECT_DOCS_ROOT": "docs"
  }
}
'

# ─── Step 6: agents ────────────────────────────────────────────────────────

agent_architect_reviewer='---
name: architect-reviewer
description: Reviews changes against PRD, architecture docs, and active tasks
---

Read CLAUDE.md and the source-of-truth docs listed there before reviewing any change.
Verify the change aligns with the PRD, does not violate architecture decisions, and
updates docs/plans/tasks.md if the change closes a task.
'

agent_backend_engineer='---
name: backend-engineer
description: Implements backend features following the project API and DB schema
---

Read CLAUDE.md, docs/architecture/api.md, and docs/architecture/db-schema.sql before
implementing any feature. Follow existing patterns in backend/src/. Write or update
tests alongside implementation. Do not modify frontend/mobile code.
'

agent_ios_engineer='---
name: ios-engineer
description: Implements iOS features following SwiftUI conventions and project architecture
---

Read CLAUDE.md and docs/architecture/system.md before implementing any feature.
Follow SwiftUI best practices. Use only tokens defined in docs/design/system.md.
Do not hard-code colors, fonts, or spacing. Support Dark Mode and Dynamic Type.
'

agent_qa_reviewer='---
name: qa-reviewer
description: Generates test scenarios and QA plans from PRD and user stories
---

Read CLAUDE.md, docs/product/prd.md, and docs/product/user-stories.md.
Generate test scenarios covering happy path, error cases, edge cases, and empty states.
Write to docs/testing/ files.
'

agent_release_manager='---
name: release-manager
description: Prepares release documentation and runs pre-release checklist
---

Read CLAUDE.md, docs/plans/tasks.md, docs/testing/manual-qa.md, and
docs/release/checklist.md. Verify all tasks are complete, tests pass, and
docs are up to date. Update docs/release/changelog.md with the release summary.
'

has_agent "architect-reviewer" && write_file .claude/agents/architect-reviewer.md "$agent_architect_reviewer"
has_agent "backend-engineer"   && [ "$BACKEND_PRESENT" -eq 1 ] && write_file .claude/agents/backend-engineer.md "$agent_backend_engineer"
has_agent "ios-engineer"       && has_frontend "swift"          && write_file .claude/agents/ios-engineer.md "$agent_ios_engineer"
has_agent "qa-reviewer"        && write_file .claude/agents/qa-reviewer.md "$agent_qa_reviewer"
has_agent "release-manager"    && write_file .claude/agents/release-manager.md "$agent_release_manager"

# ─── Step 7: docs/product/start-project.md ────────────────────────────────

START_PROJECT_SRC="$ASSETS/StartProject.md"
[ -f "$START_PROJECT_SRC" ] || die "missing asset: $START_PROJECT_SRC"
copy_asset "$START_PROJECT_SRC" docs/product/start-project.md
substitute docs/product/start-project.md "<PROJECT_NAME>" "$PROJECT_NAME"

# ─── Step 8: docs/design/system.md (UI projects only) ─────────────────────

if [ "$UI_PROJECT" -eq 1 ]; then
    mkpath docs/design
    DESIGN_SRC="$PLUGIN_ROOT/templates/DesignSystem.md"
    if [ -f "$DESIGN_SRC" ]; then
        copy_asset "$DESIGN_SRC" docs/design/system.md
        substitute docs/design/system.md "<PROJECT_NAME>" "$PROJECT_NAME"
        # Non-iOS gets a hint header — but we don't auto-prepend; warn instead.
        if ! has_frontend "swift"; then
            WARNINGS+=("docs/design/system.md is iOS-leaning — run /vladyslav:design-sync to adapt")
        fi
    else
        WARNINGS+=("templates/DesignSystem.md not found at $DESIGN_SRC — docs/design/system.md not written")
    fi
fi

# ─── Step 9: doc stubs ────────────────────────────────────────────────────

write_stub docs/product/idea.md "Idea"
write_stub docs/product/competitors.md "Competitors"
write_stub docs/product/prd.md "Product Requirements"
write_stub docs/product/user-stories.md "User Stories"
write_stub docs/architecture/system.md "System Architecture"
[ "$BACKEND_PRESENT" -eq 1 ] && write_stub docs/architecture/api.md "API Reference"
[ "$BACKEND_PRESENT" -eq 1 ] && write_stub docs/architecture/db-schema.sql "Database Schema"
write_stub docs/ux/screens.md "Screens"
write_stub docs/ux/flows.md "UX Flows"
write_stub docs/plans/implementation.md "Implementation Plan"
write_stub docs/plans/tasks.md "Tasks"
write_stub docs/plans/backlog-next.md "Backlog — Next"
write_stub docs/testing/test-plan.md "Test Plan"
write_stub docs/testing/manual-qa.md "Manual QA Checklist"
write_stub docs/release/checklist.md "Release Checklist"
write_stub docs/release/changelog.md "Changelog"
write_stub docs/release/rollback.md "Rollback Procedure"
write_stub docs/operations/incidents.md "Incidents Log"
write_stub docs/marketing/launch-notes.md "Launch Notes"

# ─── Step 10: git init and initial commit ─────────────────────────────────

INIT_GIT="$PLUGIN_ROOT/scripts/init-git-repo.sh"
if [ -x "$INIT_GIT" ]; then
    "$INIT_GIT" "$PROJECT_NAME" "$PROJECT_PWD" >/dev/null 2>&1 || WARNINGS+=("git init/commit failed — run manually")
else
    if [ ! -d .git ]; then
        git init -q 2>/dev/null
        git add -A 2>/dev/null
        git commit -q -m "chore: bootstrap $PROJECT_NAME" 2>/dev/null || WARNINGS+=("git commit failed")
    fi
fi

# ─── Done ─────────────────────────────────────────────────────────────────

emit_json "success"
exit 0
