# scripts/modules/_lib.sh
# Shared helpers for init-project module scripts. Source, don't execute.
set -u
WRITTEN=(); SKIPPED=(); WARNINGS=()

emit_json() {
    local status="$1" error_msg="${2:-}"
    printf '{"status":"%s","files_written":[' "$status"
    local first=1 f
    for f in "${WRITTEN[@]:-}"; do [ -z "$f" ] && continue
        [ $first -eq 1 ] || printf ','; printf '"%s"' "$f"; first=0; done
    printf '],"files_skipped":['; first=1
    for f in "${SKIPPED[@]:-}"; do [ -z "$f" ] && continue
        [ $first -eq 1 ] || printf ','; printf '"%s"' "$f"; first=0; done
    printf '],"warnings":['; first=1
    for f in "${WARNINGS[@]:-}"; do [ -z "$f" ] && continue
        [ $first -eq 1 ] || printf ','; printf '"%s"' "$f"; first=0; done
    if [ -n "$error_msg" ]; then printf '],"error":"%s"}\n' "$error_msg"
    else printf ']}\n'; fi
}
die() { WARNINGS+=("$1"); emit_json "error" "$1"; exit 1; }
mkpath() { mkdir -p "$1" || die "mkdir failed: $1"; }
write_file() {
    local path="$1" content="$2"
    if [ -e "$path" ]; then SKIPPED+=("$path"); return 0; fi
    mkpath "$(dirname "$path")"
    printf '%s' "$content" > "$path" || die "write failed: $path"
    WRITTEN+=("$path")
}
copy_asset() {
    local src="$1" dest="$2"
    [ -f "$src" ] || die "asset not found: $src"
    if [ -e "$dest" ]; then SKIPPED+=("$dest"); return 0; fi
    mkpath "$(dirname "$dest")"
    cp "$src" "$dest" || die "copy failed: $src -> $dest"
    WRITTEN+=("$dest")
}
sed_inplace() {
    local file="$1" expr="$2"
    if sed --version >/dev/null 2>&1; then sed -i "$expr" "$file"   # GNU
    else sed -i '' "$expr" "$file"; fi                              # BSD
}
PROJECT_PWD=""; PLUGIN_ROOT=""; REMAINING_ARGS=()
parse_common_args() {
    REMAINING_ARGS=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --pwd) PROJECT_PWD="$2"; shift 2 ;;
            --plugin-root) PLUGIN_ROOT="$2"; shift 2 ;;
            *) REMAINING_ARGS+=("$1"); shift ;;
        esac
    done
    [ -n "$PROJECT_PWD" ] || { echo "--pwd required" >&2; exit 2; }
    [ -d "$PROJECT_PWD" ] || die "project pwd does not exist: $PROJECT_PWD"
}
