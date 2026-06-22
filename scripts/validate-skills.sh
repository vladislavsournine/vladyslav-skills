#!/usr/bin/env bash
# Repo-wide static validator for skills. See docs/superpowers/specs/2026-06-22-smoke-test-skills-design.md
set -u

ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
SKILLS="$ROOT/skills"
COMMANDS="$ROOT/commands"
README="$ROOT/README.md"
fail=0

err() { printf 'FAIL: %s\n' "$1"; fail=1; }

# Print the frontmatter block (between the first two --- lines).
frontmatter() {
  awk 'NR==1&&/^---[[:space:]]*$/{f=1;next} f&&/^---[[:space:]]*$/{exit} f' "$1"
}
# Print the body (everything after the frontmatter block).
body() {
  awk 'state=="body"{print}
       NR==1&&/^---[[:space:]]*$/{state="fm";next}
       state=="fm"&&/^---[[:space:]]*$/{state="body"}' "$1"
}

# Iterate real skills (skip _shared). Usage: for_each_skill <fn>
for_each_skill() {
  local fn="$1" d name
  for d in "$SKILLS"/*/; do
    name="$(basename "$d")"
    [ "$name" = "_shared" ] && continue
    "$fn" "$name" "$d/SKILL.md"
  done
}

check_frontmatter() { # name, file
  local name="$1" f="$2" fm nm
  [ -f "$f" ] || { err "$name: missing SKILL.md"; return; }
  fm="$(frontmatter "$f")"
  [ -n "$fm" ] || { err "$name: no frontmatter block"; return; }
  nm="$(printf '%s\n' "$fm" | sed -nE 's/^name:[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1/p' | head -1)"
  [ "$nm" = "$name" ] || err "$name: frontmatter name '$nm' != dir"
  printf '%s\n' "$fm" | grep -qE '^description:[[:space:]]*\S' || err "$name: missing description"
  body "$f" | grep -qiE '^\**Type:' || err "$name: body missing Type: line"
}

main() {
  [ -d "$SKILLS" ] || { printf 'FAIL: no skills/ under %s\n' "$ROOT"; exit 2; }
  for_each_skill check_frontmatter
  if [ "$fail" -ne 0 ]; then printf -- '--- validate-skills: FAILURES found\n'; exit 1; fi
  printf -- '--- validate-skills: all checks PASS\n'; exit 0
}
main
