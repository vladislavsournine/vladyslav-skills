#!/usr/bin/env bash
# section-status.sh — scan docs/product/start-project.md (or any markdown
# file with H2 sections) and emit which sections are still pending vs filled.
#
# Usage: section-status.sh [path]
#   path defaults to docs/product/start-project.md.
#
# A section is considered PENDING if its body (between this `## Heading` and
# the next `## Heading` or EOF) contains any of these placeholder markers:
#   <...>                   (any angle-bracket placeholder)
#   *to be filled*
#   TBD
#   REPLACE_ME
#
# Otherwise the section is FILLED.
#
# Output: JSON `{"filled":["Section A","Section B"], "pending":["Section C"]}`.
#
# Exit codes:
#   0 — file scanned (regardless of pending count)
#   2 — file not found

set -u

PATHARG="${1:-docs/product/start-project.md}"

if [ ! -f "$PATHARG" ]; then
    printf '{"error":"file not found","path":"%s"}\n' "$PATHARG"
    exit 2
fi

awk '
    BEGIN { current = ""; pending_marker = 0; n_filled = 0; n_pending = 0 }

    /^## / {
        if (current != "") {
            if (pending_marker) {
                pending_arr[n_pending++] = current
            } else {
                filled_arr[n_filled++] = current
            }
        }
        current = $0
        sub(/^## /, "", current)
        pending_marker = 0
        next
    }

    # Pending markers. Use POSIX-portable boundaries: TBD must not be part of
    # a longer word (avoid matching "STBDX" etc.) — surround with non-word chars
    # or string boundaries. BSD awk (macOS) has no \b support, so we use an
    # explicit character class.
    /<[^>]+>/ || /\*to be filled\*/ || /(^|[^A-Za-z0-9_])TBD([^A-Za-z0-9_]|$)/ || /REPLACE_ME/ {
        if (current != "") pending_marker = 1
    }

    END {
        if (current != "") {
            if (pending_marker) pending_arr[n_pending++] = current
            else filled_arr[n_filled++] = current
        }

        printf "{\"filled\":["
        for (i = 0; i < n_filled; i++) {
            if (i > 0) printf ","
            gsub(/"/, "\\\"", filled_arr[i])
            printf "\"%s\"", filled_arr[i]
        }
        printf "],\"pending\":["
        for (i = 0; i < n_pending; i++) {
            if (i > 0) printf ","
            gsub(/"/, "\\\"", pending_arr[i])
            printf "\"%s\"", pending_arr[i]
        }
        printf "]}\n"
    }
' "$PATHARG"
