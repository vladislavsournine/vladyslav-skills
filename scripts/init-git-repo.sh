#!/usr/bin/env bash
# init-git-repo.sh — idempotent git initialisation for a project directory.
#
# Usage: init-git-repo.sh [project_name] [path]
#   project_name — used in the initial commit message; defaults to basename of path.
#   path         — defaults to current working directory.
#
# Behavior:
#   1. If `path` is not yet a git repo: `git init` (default branch = main).
#   2. If there are no commits yet: stage everything, create one commit
#      `chore: bootstrap <project_name>`.
#   3. If the repo already exists with commits: no-op (exits 0 silently).
#
# Exit codes:
#   0 — success (created or no-op)
#   1 — git command failed
#   2 — bad arguments

set -u

PROJECT_NAME_ARG="${1:-}"
PATH_ARG="${2:-.}"

if [ ! -d "$PATH_ARG" ]; then
    echo "init-git-repo: not a directory: $PATH_ARG" >&2
    exit 2
fi

cd "$PATH_ARG" || exit 1

NAME="${PROJECT_NAME_ARG:-$(basename "$(pwd)")}"

if [ ! -d ".git" ]; then
    git init -q -b main 2>/dev/null || git init -q || exit 1
fi

# Already has commits? Bail.
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    exit 0
fi

git add -A 2>/dev/null || exit 1
# Allow empty in case there is nothing yet — but this is unusual; skills
# should call this AFTER scaffolding has produced files.
git commit -q -m "chore: bootstrap $NAME" 2>/dev/null || exit 1
