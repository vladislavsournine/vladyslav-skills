#!/usr/bin/env bash
# detect-stack.sh — probe a project directory and emit JSON describing
# which technology stacks are present.
#
# Usage: detect-stack.sh [path]
#   path defaults to the current working directory.
#
# Output: one line of JSON to stdout. All values are booleans.
#
#   {
#     "ios":     true|false,   # *.xcodeproj | Package.swift | project.yml + app/*App.swift
#     "swift":   true|false,   # any Swift sources outside iOS app structure
#     "flutter": true|false,   # pubspec.yaml
#     "kotlin":  true|false,   # *.kt | build.gradle*  (android or jvm)
#     "android": true|false,   # AndroidManifest.xml | build.gradle with android plugin
#     "python":  true|false,   # requirements.txt | pyproject.toml | setup.py
#     "go":      true|false,   # go.mod
#     "node":    true|false,   # package.json
#     "web":     true|false,   # tailwind.config.* | next.config.* | vite.config.* | index.html at root
#     "backend": true|false,   # python|go|node + (Dockerfile | docker-compose*)
#     "plugin":  true|false,   # .claude-plugin/plugin.json
#     "ui":      true|false,   # ios|flutter|kotlin|android|web (anything user-facing)
#     "docker":  true|false    # any Dockerfile or docker-compose*.yml at root or backend/
#   }
#
# Designed to be portable: only POSIX shell + standard utilities.
# Exit codes:
#   0  — JSON written to stdout (always 0 even when path is missing/empty;
#         in that case all booleans are false)
#   2  — invalid argument

set -u

PROJECT="${1:-.}"

if [ ! -e "$PROJECT" ]; then
    echo '{"error":"path does not exist","path":"'"$PROJECT"'"}'
    exit 2
fi

# Helper: returns "true" if the glob in $1 matches at least one path
# under $PROJECT (one level deep unless globstar is enabled by caller).
glob_match() {
    local pat="$1"
    # Use find for portability — avoids relying on shell globbing rules.
    if find "$PROJECT" -maxdepth 4 -name "$pat" -print -quit 2>/dev/null | grep -q .; then
        echo true
    else
        echo false
    fi
}

# Same, but returns "true" if any of the file names in the rest of the
# arguments exists at the project root.
file_at_root() {
    for f in "$@"; do
        [ -e "$PROJECT/$f" ] && { echo true; return; }
    done
    echo false
}

ios=false
swift=$(glob_match "*.swift")
[ "$(glob_match '*.xcodeproj')" = "true" ] && ios=true
[ "$(file_at_root 'Package.swift')" = "true" ] && ios=true
# project.yml + an *App.swift file = xcodegen iOS
if [ "$(file_at_root 'project.yml')" = "true" ] && find "$PROJECT" -maxdepth 3 -name '*App.swift' -print -quit 2>/dev/null | grep -q .; then
    ios=true
fi

flutter=$(file_at_root 'pubspec.yaml')

kotlin=false
[ "$(glob_match '*.kt')" = "true" ] && kotlin=true
[ "$(glob_match 'build.gradle')" = "true" ] && kotlin=true
[ "$(glob_match 'build.gradle.kts')" = "true" ] && kotlin=true

android=false
[ "$(glob_match 'AndroidManifest.xml')" = "true" ] && android=true

python=$(file_at_root 'requirements.txt' 'pyproject.toml' 'setup.py')

go=$(file_at_root 'go.mod')

node=$(file_at_root 'package.json')

web=false
[ "$(file_at_root 'tailwind.config.js' 'tailwind.config.ts' 'tailwind.config.cjs' 'tailwind.config.mjs')" = "true" ] && web=true
[ "$(file_at_root 'next.config.js' 'next.config.ts' 'next.config.mjs')" = "true" ] && web=true
[ "$(file_at_root 'vite.config.js' 'vite.config.ts')" = "true" ] && web=true
[ "$(file_at_root 'index.html')" = "true" ] && web=true

docker=false
[ "$(file_at_root 'Dockerfile')" = "true" ] && docker=true
[ -e "$PROJECT/backend/Dockerfile" ] && docker=true
if find "$PROJECT" -maxdepth 3 -name 'docker-compose*.yml' -print -quit 2>/dev/null | grep -q .; then
    docker=true
fi

backend=false
if { [ "$python" = "true" ] || [ "$go" = "true" ] || [ "$node" = "true" ]; } && [ "$docker" = "true" ]; then
    backend=true
fi
# Also count an explicit `backend/` directory with stack files inside.
if [ -d "$PROJECT/backend" ]; then
    if find "$PROJECT/backend" -maxdepth 2 \( -name 'requirements.txt' -o -name 'pyproject.toml' -o -name 'go.mod' -o -name 'package.json' \) -print -quit 2>/dev/null | grep -q .; then
        backend=true
    fi
fi

plugin=$(file_at_root '.claude-plugin/plugin.json')

ui=false
for s in "$ios" "$flutter" "$kotlin" "$android" "$web"; do
    [ "$s" = "true" ] && { ui=true; break; }
done

# Emit JSON. Order matches the docstring above.
printf '{"ios":%s,"swift":%s,"flutter":%s,"kotlin":%s,"android":%s,"python":%s,"go":%s,"node":%s,"web":%s,"backend":%s,"plugin":%s,"ui":%s,"docker":%s}\n' \
    "$ios" "$swift" "$flutter" "$kotlin" "$android" "$python" "$go" "$node" "$web" "$backend" "$plugin" "$ui" "$docker"
