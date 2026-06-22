#!/usr/bin/env bash
# design-system.sh — docs/design/system.md from template.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
NAME=""
parse_common_args "$@"
i=0; while [ $i -lt ${#REMAINING_ARGS[@]} ]; do
    case "${REMAINING_ARGS[$i]}" in
        --name) NAME="${REMAINING_ARGS[$((i+1))]}"; i=$((i+2)) ;;
        *) i=$((i+1)) ;;
    esac
done
[ -n "$PLUGIN_ROOT" ] || die "--plugin-root required"
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

SRC="$PLUGIN_ROOT/templates/DesignSystem.md"
if [ -f "$SRC" ]; then
    copy_asset "$SRC" "docs/design/system.md"
    if [ -f "docs/design/system.md" ] && [ -n "$NAME" ]; then
        sed_inplace "docs/design/system.md" "s|<PROJECT_NAME>|${NAME}|g"
    fi
    emit_json "success"
else
    WARNINGS+=("templates/DesignSystem.md not found at $SRC — system.md not written")
    emit_json "partial"
fi
exit 0
