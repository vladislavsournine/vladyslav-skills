#!/usr/bin/env bash
# parse-yaml-return.sh — find the last fenced ```yaml block in stdin and emit
# its body as JSON. Used by heavy-engineer skills to validate the structured
# return contract from their Sonnet subagents without forcing the model to
# parse YAML in-line.
#
# Usage: parse-yaml-return.sh < subagent_output.txt
#
# Output (stdout):
#   Valid case:   {"ok": true, "yaml": "<original yaml body>"}
#   Parse error:  {"ok": false, "reason": "no yaml block"|"missing status field"|"empty"}
#
# Exit codes:
#   0 — yaml block found and `status:` key present
#   1 — block missing or malformed
#   2 — bad arguments
#
# Note: this script does NOT convert YAML to JSON (would require a yaml parser).
# It only locates the block, validates the presence of `status:`, and returns
# the raw YAML for the caller to interpret. Skills should pass the yaml body
# back to the model for structured rendering — the deterministic part is the
# block extraction, which is what was fragile before.

set -u

INPUT="$(cat)"
if [ -z "$INPUT" ]; then
    echo '{"ok":false,"reason":"empty"}'
    exit 1
fi

# Extract the LAST ```yaml ... ``` block.
# Strategy: iterate lines; when we see ```yaml, start capturing into a buffer;
# when we see ```, finalise and reset. The last finalised buffer wins.
LAST_BLOCK="$(
    awk '
        BEGIN { in_block = 0; block = "" }
        /^[[:space:]]*```[[:space:]]*yaml[[:space:]]*$/ { in_block = 1; block = ""; next }
        /^[[:space:]]*```[[:space:]]*$/ {
            if (in_block) { last = block; in_block = 0 }
            next
        }
        in_block { block = block $0 "\n" }
        END { if (last != "") printf "%s", last }
    ' <<< "$INPUT"
)"

if [ -z "$LAST_BLOCK" ]; then
    echo '{"ok":false,"reason":"no yaml block"}'
    exit 1
fi

# Check for `status:` key (with optional leading whitespace, optional list dash).
if ! printf '%s' "$LAST_BLOCK" | grep -Eq '^[[:space:]]*status[[:space:]]*:'; then
    echo '{"ok":false,"reason":"missing status field"}'
    exit 1
fi

# Escape the YAML for JSON embedding: wrap with jq if available, otherwise
# fall back to a minimal escape (sufficient for the structured outputs our
# subagents produce — no embedded backslashes or control chars expected).
if command -v jq >/dev/null 2>&1; then
    printf '%s' "$LAST_BLOCK" | jq -Rs '{ok: true, yaml: .}'
else
    # Minimal escape: backslash, double-quote, newline.
    ESC="$(printf '%s' "$LAST_BLOCK" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s\\n", $0}')"
    printf '{"ok":true,"yaml":"%s"}\n' "$ESC"
fi
