#!/usr/bin/env bash
# architecture.sh — docs/architecture/system.md stub.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
parse_common_args "$@"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"
write_file "docs/architecture/system.md" "# System Architecture

*to be filled*
"
emit_json "success"
exit 0
