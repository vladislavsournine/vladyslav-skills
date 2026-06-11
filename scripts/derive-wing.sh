#!/usr/bin/env bash
# derive-wing.sh — emit the canonical MemPalace wing name for a project.
#
# Usage: derive-wing.sh [path]
#   path defaults to the current working directory.
#
# Algorithm (deliberately minimal — basename only):
#   1. Take the basename of the absolute path.
#   2. Replace any run of whitespace, underscores, or dots with a single hyphen;
#      collapse repeated hyphens; strip leading/trailing hyphens.
#   3. Print it. Case is PRESERVED. No lowercasing. No stack prefix.
#
# Why basename-only:
#   The canonical wings are exactly the project directory names — they already
#   carry their own convention prefix where one applies (swift-calories,
#   python-tax, flutter-paolo) and intentionally do NOT where it doesn't (brain,
#   documents, phD, claude-init, vladyslav-skills). The previous version
#   lowercased (phD -> phd) and force-prepended a detected stack prefix
#   (vladyslav-skills -> plugin-vladyslav-skills), both of which diverged from
#   the real wing names in the palace and from the SessionEnd miner (which uses
#   the bare basename). Anything beyond basename re-introduces split-brain wings.
#
# Output: a single line.

set -u

PROJECT="${1:-.}"

if [ ! -d "$PROJECT" ]; then
    echo "derive-wing: not a directory: $PROJECT" >&2
    exit 2
fi

# Resolve to absolute path so basename is stable regardless of caller's pwd.
ABS="$(cd "$PROJECT" && pwd)"
RAW="$(basename "$ABS")"

# Normalize separators only — never change case, never add a prefix.
WING="$(printf '%s' "$RAW" | sed -E 's/[[:space:]_.]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')"

printf '%s\n' "$WING"
