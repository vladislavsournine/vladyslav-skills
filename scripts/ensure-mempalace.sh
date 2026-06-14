#!/usr/bin/env bash
#
# ensure-mempalace.sh — guarantee the MemPalace MCP server is registered at
# USER scope, so it is available in every project (current and future) without
# any per-project setup.
#
# Why this exists:
#   MemPalace is normally registered once at "user" scope in ~/.claude.json
#   (mcpServers.mempalace). User scope is global — not tied to any path — so a
#   new project under any directory gets MemPalace automatically. This script
#   is the SELF-HEAL net for the cases where that record is lost: a fresh Mac,
#   a reset ~/.claude.json, or an accidental `claude mcp remove`.
#
# It is idempotent: if MemPalace is already registered at user scope, it does
# nothing. If missing, it re-adds it. Safe to run repeatedly and on every box.
#
# Config (override via env before running):
#   MEMPALACE_INTERP   absolute path to the venv python that has `mempalace`
#                      installed       (default: ~/.mempalace-venv/bin/python)
#   MEMPALACE_PALACE_PATH  absolute path to the palace data store
#                      (default: ~/.mempalace)
#
# Usage:
#   bash scripts/ensure-mempalace.sh           # check + heal
#   MEMPALACE_PALACE_PATH=/data/.mempalace bash scripts/ensure-mempalace.sh
#
# Exit codes: 0 = registered (already or just added); 1 = could not register.

set -euo pipefail

INTERP="${MEMPALACE_INTERP:-$HOME/.mempalace-venv/bin/python}"
PALACE="${MEMPALACE_PALACE_PATH:-$HOME/.mempalace}"

log()  { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
err()  { printf 'ERROR: %s\n' "$*" >&2; }

# 1. Need the claude CLI to query/modify MCP config.
if ! command -v claude >/dev/null 2>&1; then
  err "claude CLI not found on PATH — cannot manage MCP servers."
  exit 1
fi

# 2. Already registered at user scope? `claude mcp get` prints the scope line.
#    We only treat USER scope as "good" — a local/project entry would not give
#    the global coverage this script guarantees.
if claude mcp get mempalace 2>/dev/null | grep -q "Scope: User config"; then
  log "OK: MemPalace already registered at user scope (available in all projects)."
  exit 0
fi

log "MemPalace not found at user scope — registering…"

# 3. Sanity-check the interpreter before wiring it up. A bare/ wrong interpreter
#    is the #1 cause of 'No module named mempalace' at MCP startup.
if [ ! -x "$INTERP" ]; then
  warn "Interpreter not found/executable: $INTERP"
  warn "Install it first:  python3 -m venv ~/.mempalace-venv && ~/.mempalace-venv/bin/pip install --upgrade mempalace"
  warn "Or set MEMPALACE_INTERP to your interpreter and re-run."
elif ! "$INTERP" -c "import mempalace" >/dev/null 2>&1; then
  warn "'$INTERP' cannot import mempalace."
  warn "Install it:  $INTERP -m pip install --upgrade mempalace"
fi

# 4. Register at user scope. Idempotent guard above means we only reach here
#    when the user-scope entry is absent. Remove any stale non-user entry first
#    so the add does not collide with a leftover local/project registration.
claude mcp remove mempalace >/dev/null 2>&1 || true

if claude mcp add mempalace \
     --scope user \
     -e "MEMPALACE_PALACE_PATH=$PALACE" \
     -- "$INTERP" -m mempalace.mcp_server; then
  log "Registered MemPalace at user scope."
  log "  interpreter: $INTERP"
  log "  palace path: $PALACE"
  log "Restart Claude Code so the MCP server connects on the new config."
  exit 0
else
  err "Failed to register MemPalace. Check the interpreter path and try again."
  exit 1
fi
