#!/usr/bin/env bash
# extract-tokens.sh — extract design tokens (colors / typography / icons /
# spacing) from a UI project's source code. Emits JSON for design-sync to
# consume.
#
# The hard part (deciding what's canonical, what's drift) stays in the LLM.
# This script's job is the pure-mechanical grep+parse pass that today's
# design-sync skill has the model do step-by-step.
#
# Usage:
#   extract-tokens.sh --pwd <project-dir> [--platform <ios|web|flutter|kotlin|auto>]
#
# If --platform is omitted or `auto`, the script uses detect-stack.sh and
# picks the first matching UI stack.
#
# Output: JSON to stdout
#   {
#     "platform": "ios|web|flutter|kotlin",
#     "colors":     [{"value": "#RRGGBB", "count": <n>, "names": [<symbolic names>], "files": [<paths>]}],
#     "typography": [{"family": "...", "size": <n|null>, "weight": "...", "count": <n>, "files": [<paths>]}],
#     "icons":      [{"name": "<sf-symbol|asset>", "count": <n>, "files": [<paths>]}],
#     "spacing":    [{"value": <n>, "count": <n>, "files": [<paths>]}],
#     "warnings":   [<msgs>]
#   }
#
# Each array is sorted by `count` descending (most-used first), which is how
# canonical-vs-drift is most easily seen.
#
# Exit codes: 0 on success (even if zero tokens found — that's data), 2 on
# bad args, 1 on platform-resolution failure.

set -u

PROJECT_PWD=""
PLATFORM=""

while [ $# -gt 0 ]; do
    case "$1" in
        --pwd) PROJECT_PWD="$2"; shift 2 ;;
        --platform) PLATFORM="$2"; shift 2 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

[ -z "$PROJECT_PWD" ] && { echo "--pwd required" >&2; exit 2; }
[ -d "$PROJECT_PWD" ] || { echo "pwd not found: $PROJECT_PWD" >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-detect platform if not specified
if [ -z "$PLATFORM" ] || [ "$PLATFORM" = "auto" ]; then
    if [ -x "$SCRIPT_DIR/detect-stack.sh" ]; then
        DETECTION="$("$SCRIPT_DIR/detect-stack.sh" "$PROJECT_PWD")"
        if echo "$DETECTION" | grep -q '"ios":true'; then
            PLATFORM="ios"
        elif echo "$DETECTION" | grep -q '"flutter":true'; then
            PLATFORM="flutter"
        elif echo "$DETECTION" | grep -q '"kotlin":true'; then
            PLATFORM="kotlin"
        elif echo "$DETECTION" | grep -q '"web":true'; then
            PLATFORM="web"
        else
            echo "could not auto-detect UI platform — pass --platform explicitly" >&2
            exit 1
        fi
    else
        echo "detect-stack.sh not found; pass --platform explicitly" >&2
        exit 1
    fi
fi

cd "$PROJECT_PWD" || exit 2

WARNINGS=()

# ─── helpers ─────────────────────────────────────────────────────────────

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    printf '%s' "$s"
}

# Compact a list of token rows (one per line, fields tab-separated) into
# a JSON array sorted by count descending. Each input row: value\tname\tfile
# We aggregate by value: count = number of rows, names = unique names list,
# files = unique files list.
#
# Used for colors and similar string-valued tokens.
aggregate_string_tokens() {
    local field_label="$1"  # JSON field name for the value ("value", "name", etc.)
    # Read stdin, aggregate. awk produces "value\tcount\tname1|name2\tfile1|file2"
    awk -F'\t' '
        {
            value=$1; name=$2; file=$3
            count[value]++
            if (name != "") names[value] = (names[value] == "" ? name : names[value] "|" name)
            if (file != "") files[value] = (files[value] == "" ? file : files[value] "|" file)
        }
        END {
            for (v in count) printf "%s\t%d\t%s\t%s\n", v, count[v], names[v], files[v]
        }
    ' | sort -t$'\t' -k2,2 -rn | awk -F'\t' -v field="$field_label" '
        BEGIN { print "["; first=1 }
        {
            if (!first) print ","
            first=0
            # Dedupe names list
            n=split($3, narr, "|")
            seen_names=""
            unique_names=""
            for (i=1; i<=n; i++) {
                if (narr[i] == "") continue
                if (index(seen_names, "|" narr[i] "|") == 0) {
                    seen_names = seen_names "|" narr[i] "|"
                    unique_names = unique_names (unique_names == "" ? "" : ",") "\"" narr[i] "\""
                }
            }
            # Dedupe files list, cap at 5
            m=split($4, farr, "|")
            seen_files=""
            unique_files=""
            file_count=0
            for (i=1; i<=m; i++) {
                if (farr[i] == "") continue
                if (index(seen_files, "|" farr[i] "|") == 0) {
                    seen_files = seen_files "|" farr[i] "|"
                    if (file_count < 5) {
                        unique_files = unique_files (unique_files == "" ? "" : ",") "\"" farr[i] "\""
                        file_count++
                    }
                }
            }
            printf "  {\"%s\":\"%s\",\"count\":%s,\"names\":[%s],\"files\":[%s]}", field, $1, $2, unique_names, unique_files
        }
        END { print ""; print "]" }
    '
}

# Same shape for integer-valued tokens (spacing).
aggregate_int_tokens() {
    local field_label="$1"
    awk -F'\t' '
        {
            value=$1; file=$2
            count[value]++
            if (file != "") files[value] = (files[value] == "" ? file : files[value] "|" file)
        }
        END {
            for (v in count) printf "%s\t%d\t%s\n", v, count[v], files[v]
        }
    ' | sort -t$'\t' -k2,2 -rn | awk -F'\t' -v field="$field_label" '
        BEGIN { print "["; first=1 }
        {
            if (!first) print ","
            first=0
            m=split($3, farr, "|")
            seen_files=""; unique_files=""; file_count=0
            for (i=1; i<=m; i++) {
                if (farr[i] == "") continue
                if (index(seen_files, "|" farr[i] "|") == 0) {
                    seen_files = seen_files "|" farr[i] "|"
                    if (file_count < 5) {
                        unique_files = unique_files (unique_files == "" ? "" : ",") "\"" farr[i] "\""
                        file_count++
                    }
                }
            }
            printf "  {\"%s\":%s,\"count\":%s,\"files\":[%s]}", field, $1, $2, unique_files
        }
        END { print ""; print "]" }
    '
}

# ─── iOS extractor ───────────────────────────────────────────────────────

extract_ios() {
    COLORS_RAW=$(mktemp)
    TYPO_RAW=$(mktemp)
    ICONS_RAW=$(mktemp)
    SPACING_RAW=$(mktemp)

    # 1. Colors from Assets.xcassets/.colorset/Contents.json
    if [ -d Assets.xcassets ] || find . -maxdepth 4 -name '*.xcassets' -print -quit 2>/dev/null | grep -q .; then
        while IFS= read -r contents_json; do
            colorset_dir=$(dirname "$contents_json")
            colorset_name=$(basename "$colorset_dir" .colorset)
            # Extract first color's hex from JSON. iOS asset Contents.json contains
            # "red", "green", "blue" components per appearance. We just grab the
            # default appearance's first set.
            hex=$(python3 -c "
import json, sys
try:
    with open('$contents_json') as f:
        data = json.load(f)
    for c in data.get('colors', []):
        comp = c.get('color', {}).get('components', {})
        if 'red' in comp and 'green' in comp and 'blue' in comp:
            def to255(v):
                v = str(v)
                if v.startswith('0x'):
                    return int(v, 16)
                try:
                    f = float(v)
                    return int(f * 255 if f <= 1 else f)
                except: return 0
            r, g, b = to255(comp['red']), to255(comp['green']), to255(comp['blue'])
            print('#%02X%02X%02X' % (r, g, b))
            break
except Exception:
    pass
" 2>/dev/null)
            [ -n "$hex" ] && printf '%s\t%s\t%s\n' "$hex" "$colorset_name" "$contents_json" >> "$COLORS_RAW"
        done < <(find . -path '*.xcassets/*.colorset/Contents.json' -not -path '*/build/*' -not -path '*/DerivedData/*' 2>/dev/null)
    fi

    # 2. Inline hex colors in Swift code: Color(hex: "#XXXXXX") or Color(hex: 0xXXXXXX)
    grep -rEn --include='*.swift' -h --exclude-dir=DerivedData --exclude-dir=build \
        '(Color|UIColor)\(hex:[[:space:]]*"#?[0-9A-Fa-f]{6,8}"' . 2>/dev/null | \
        while IFS=: read -r file _ line; do
            hex=$(echo "$line" | grep -oE '#?[0-9A-Fa-f]{6,8}' | head -1)
            [ -n "$hex" ] && {
                # Normalize: ensure leading #, uppercase
                hex="${hex#\#}"
                hex_upper=$(echo "$hex" | tr '[:lower:]' '[:upper:]')
                printf '#%s\tinline\t%s\n' "$hex_upper" "$file" >> "$COLORS_RAW"
            }
        done 2>/dev/null

    # 3. Color(red:, green:, blue:) — rough RGB extraction
    grep -rEn --include='*.swift' --exclude-dir=DerivedData --exclude-dir=build \
        'Color\(red:[[:space:]]*[0-9.]+,[[:space:]]*green:[[:space:]]*[0-9.]+,[[:space:]]*blue:' . 2>/dev/null | \
        awk -F: '{print $1}' | sort -u | while IFS= read -r file; do
            printf '#RGB-inline\trgb-call\t%s\n' "$file" >> "$COLORS_RAW"
        done

    # 4. Typography: SwiftUI .font(.system(size: N, weight: .semibold))
    grep -rEn --include='*.swift' --exclude-dir=DerivedData --exclude-dir=build \
        '\.font\(' . 2>/dev/null | while IFS=: read -r file _ line; do
            size=$(echo "$line" | grep -oE 'size:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
            weight=$(echo "$line" | grep -oE 'weight:[[:space:]]*\.[a-zA-Z]+' | sed 's/.*\.//')
            family=$(echo "$line" | grep -oE 'Font\.custom\("[^"]+"' | sed 's/Font\.custom("//;s/"$//')
            [ -z "$family" ] && family="system"
            [ -n "$size" ] && printf 'family=%s\tsize=%s\tweight=%s\t%s\n' "$family" "$size" "${weight:-regular}" "$file" >> "$TYPO_RAW"
        done

    # 5. SF Symbols: Image(systemName: "...")
    grep -rEn --include='*.swift' --exclude-dir=DerivedData --exclude-dir=build \
        'Image\(systemName:[[:space:]]*"[^"]+"' . 2>/dev/null | \
        while IFS=: read -r file _ line; do
            name=$(echo "$line" | grep -oE 'systemName:[[:space:]]*"[^"]+"' | sed 's/.*"\([^"]*\)".*/\1/')
            [ -n "$name" ] && printf '%s\t-\t%s\n' "$name" "$file" >> "$ICONS_RAW"
        done

    # 6. Spacing: .padding(N), .spacing: N
    grep -rEn --include='*.swift' --exclude-dir=DerivedData --exclude-dir=build \
        '\.padding\([[:space:]]*[0-9]+[[:space:]]*\)' . 2>/dev/null | \
        while IFS=: read -r file _ line; do
            val=$(echo "$line" | grep -oE '\.padding\([[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
            [ -n "$val" ] && printf '%s\t%s\n' "$val" "$file" >> "$SPACING_RAW"
        done

    COLORS_JSON=$([ -s "$COLORS_RAW" ] && cat "$COLORS_RAW" | aggregate_string_tokens "value" || echo "[]")
    SPACING_JSON=$([ -s "$SPACING_RAW" ] && cat "$SPACING_RAW" | aggregate_int_tokens "value" || echo "[]")
    ICONS_JSON=$([ -s "$ICONS_RAW" ] && cat "$ICONS_RAW" | aggregate_string_tokens "name" || echo "[]")

    # Typography aggregation is custom (multiple fields)
    if [ -s "$TYPO_RAW" ]; then
        TYPO_JSON=$(awk -F'\t' '
            { count[$1"\t"$2"\t"$3]++; files[$1"\t"$2"\t"$3] = (files[$1"\t"$2"\t"$3] == "" ? $4 : files[$1"\t"$2"\t"$3] "|" $4) }
            END { for (k in count) printf "%s\t%d\t%s\n", k, count[k], files[k] }
        ' "$TYPO_RAW" | sort -t$'\t' -k4,4 -rn | awk -F'\t' '
            BEGIN { print "["; first=1 }
            {
                if (!first) print ","
                first=0
                family=$1; sub(/^family=/, "", family)
                size=$2;   sub(/^size=/, "", size)
                weight=$3; sub(/^weight=/, "", weight)
                count=$4
                m=split($5, farr, "|")
                seen=""; uniq=""; fc=0
                for (i=1; i<=m; i++) {
                    if (farr[i] == "" || index(seen, "|" farr[i] "|") != 0) continue
                    seen = seen "|" farr[i] "|"
                    if (fc < 5) { uniq = uniq (uniq == "" ? "" : ",") "\"" farr[i] "\""; fc++ }
                }
                printf "  {\"family\":\"%s\",\"size\":%s,\"weight\":\"%s\",\"count\":%s,\"files\":[%s]}", family, size, weight, count, uniq
            }
            END { print ""; print "]" }
        ')
    else
        TYPO_JSON="[]"
    fi

    rm -f "$COLORS_RAW" "$TYPO_RAW" "$ICONS_RAW" "$SPACING_RAW"
}

# ─── Web extractor ───────────────────────────────────────────────────────

extract_web() {
    COLORS_RAW=$(mktemp)
    SPACING_RAW=$(mktemp)
    ICONS_RAW=$(mktemp)

    # CSS variables (--color-*, --spacing-*) in .css / .scss
    grep -rhEn --include='*.css' --include='*.scss' --include='*.less' --exclude-dir=node_modules --exclude-dir=build --exclude-dir=dist \
        '\-\-[a-z-]+:[[:space:]]*' . 2>/dev/null | while IFS= read -r line; do
            varname=$(echo "$line" | grep -oE '\-\-[a-z-]+' | head -1)
            value=$(echo "$line" | grep -oE ':[[:space:]]*[^;]+' | sed 's/:[[:space:]]*//')
            [ -z "$varname" ] && continue
            # Heuristic: classify by name prefix
            if echo "$varname" | grep -qE '^\-\-(color|bg|text|border)'; then
                hex=$(echo "$value" | grep -oE '#[0-9A-Fa-f]{3,8}' | head -1)
                [ -n "$hex" ] && printf '%s\t%s\tcss-variable\n' "$hex" "$varname" >> "$COLORS_RAW"
            elif echo "$varname" | grep -qE '^\-\-(spacing|space|gap|padding|margin)'; then
                val=$(echo "$value" | grep -oE '[0-9]+' | head -1)
                [ -n "$val" ] && printf '%s\tcss-variable\n' "$val" >> "$SPACING_RAW"
            fi
        done

    # Inline hex colors in TS/JS/CSS
    grep -rhEn --include='*.tsx' --include='*.ts' --include='*.jsx' --include='*.js' --include='*.css' --exclude-dir=node_modules --exclude-dir=build --exclude-dir=dist \
        '#[0-9A-Fa-f]{6,8}' . 2>/dev/null | while IFS= read -r line; do
            hex=$(echo "$line" | grep -oE '#[0-9A-Fa-f]{6,8}' | head -1)
            [ -z "$hex" ] && continue
            hex=$(echo "$hex" | tr '[:lower:]' '[:upper:]')
            printf '%s\tinline\tcode\n' "$hex" >> "$COLORS_RAW"
        done

    # Tailwind config — look for theme.colors and theme.spacing
    if [ -f tailwind.config.js ] || [ -f tailwind.config.ts ]; then
        for f in tailwind.config.js tailwind.config.ts; do
            [ -f "$f" ] && {
                grep -E '^\s+[a-z][a-z0-9-]*:\s*("|#)' "$f" 2>/dev/null | \
                grep -oE '#[0-9A-Fa-f]{6,8}' | while IFS= read -r hex; do
                    [ -z "$hex" ] && continue
                    hex=$(echo "$hex" | tr '[:lower:]' '[:upper:]')
                    printf '%s\ttailwind\t%s\n' "$hex" "$f" >> "$COLORS_RAW"
                done
            }
        done
    fi

    COLORS_JSON=$([ -s "$COLORS_RAW" ] && cat "$COLORS_RAW" | aggregate_string_tokens "value" || echo "[]")
    SPACING_JSON=$([ -s "$SPACING_RAW" ] && cat "$SPACING_RAW" | aggregate_int_tokens "value" || echo "[]")
    ICONS_JSON="[]"
    TYPO_JSON="[]"

    WARNINGS+=("web typography/icons extraction is a stub — extend extract_web if you need richer data")

    rm -f "$COLORS_RAW" "$SPACING_RAW" "$ICONS_RAW"
}

# ─── Flutter / Kotlin placeholders ───────────────────────────────────────

extract_flutter() {
    COLORS_JSON="[]"
    TYPO_JSON="[]"
    ICONS_JSON="[]"
    SPACING_JSON="[]"
    WARNINGS+=("flutter token extraction not yet implemented — handle in-skill via LLM")
}

extract_kotlin() {
    # Quick win: parse colors.xml
    COLORS_RAW=$(mktemp)
    while IFS= read -r f; do
        grep -oE '<color name="[^"]+">#[0-9A-Fa-f]+</color>' "$f" 2>/dev/null | \
        while IFS= read -r line; do
            name=$(echo "$line" | sed -E 's/.*name="([^"]+)".*/\1/')
            hex=$(echo "$line" | grep -oE '#[0-9A-Fa-f]+' | head -1 | tr '[:lower:]' '[:upper:]')
            [ -n "$hex" ] && printf '%s\t%s\t%s\n' "$hex" "$name" "$f" >> "$COLORS_RAW"
        done
    done < <(find . -name 'colors.xml' -not -path '*/build/*' 2>/dev/null)
    COLORS_JSON=$([ -s "$COLORS_RAW" ] && cat "$COLORS_RAW" | aggregate_string_tokens "value" || echo "[]")
    TYPO_JSON="[]"
    ICONS_JSON="[]"
    SPACING_JSON="[]"
    rm -f "$COLORS_RAW"
    WARNINGS+=("kotlin typography/icons/spacing extraction not yet implemented")
}

# ─── dispatch ────────────────────────────────────────────────────────────

case "$PLATFORM" in
    ios)     extract_ios ;;
    web)     extract_web ;;
    flutter) extract_flutter ;;
    kotlin)  extract_kotlin ;;
    *)
        echo "unsupported platform: $PLATFORM" >&2
        exit 1
        ;;
esac

# ─── emit JSON ───────────────────────────────────────────────────────────

WARN_JSON="["
first=1
for w in "${WARNINGS[@]:-}"; do
    [ -z "$w" ] && continue
    [ $first -eq 1 ] || WARN_JSON+=","
    WARN_JSON+="\"$(json_escape "$w")\""
    first=0
done
WARN_JSON+="]"

printf '{"platform":"%s","colors":%s,"typography":%s,"icons":%s,"spacing":%s,"warnings":%s}\n' \
    "$PLATFORM" \
    "$(echo "$COLORS_JSON" | tr -d '\n')" \
    "$(echo "$TYPO_JSON" | tr -d '\n')" \
    "$(echo "$ICONS_JSON" | tr -d '\n')" \
    "$(echo "$SPACING_JSON" | tr -d '\n')" \
    "$WARN_JSON"
