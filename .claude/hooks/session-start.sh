#!/usr/bin/env bash
# SessionStart hook — silent wing-memory hint.
# Reads JSON from stdin (Claude Code hook protocol), emits a single short line
# reminding which MemPalace wing applies to this project. Always exits 0 so
# the session never gets blocked by this hook.

set -u

# Discard stdin payload — we don't need to parse it for this hook.
cat >/dev/null 2>&1 || true

cat <<'EOF'
[vladyslav-skills] MemPalace wing for this project: `vladyslav-skills`. Search there before re-scanning the codebase. Recent room types: decision, problem, milestone, preference, compact-save.
EOF

exit 0
