#!/usr/bin/env bash
# docs.sh — prd + planning docs.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
parse_common_args "$@"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

stub() { write_file "$1" "# $2

*to be filled*
"; }

stub "docs/product/prd.md" "Product Requirements"
stub "docs/plans/tasks.md" "Tasks"
stub "docs/plans/backlog-next.md" "Backlog — Next"

emit_json "success"
exit 0
