#!/usr/bin/env bash
# backend-skeleton.sh — minimal python backend skeleton (no framework).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
parse_common_args "$@"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

write_file "requirements.txt" "# Add dependencies as needed.
"
write_file "src/__init__.py" ""
write_file "src/main.py" "def main() -> None:
    print(\"running\")


if __name__ == \"__main__\":
    main()
"

emit_json "success"
exit 0
