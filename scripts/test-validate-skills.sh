#!/usr/bin/env bash
# Test harness for validate-skills.sh — builds fixture trees, asserts exit codes.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
VALIDATOR="$HERE/validate-skills.sh"
pass=0; failc=0

T() { # desc, expected_exit, root
  local desc="$1" exp="$2" root="$3" got
  "$VALIDATOR" "$root" >/dev/null 2>&1; got=$?
  if [ "$got" -eq "$exp" ]; then
    pass=$((pass+1)); printf 'ok   - %s\n' "$desc"
  else
    failc=$((failc+1)); printf 'FAIL - %s (exit %s, want %s)\n' "$desc" "$got" "$exp"
  fi
}

make_valid() { # prints path to a fresh valid fixture root
  local r; r="$(mktemp -d)"
  mkdir -p "$r/skills/alpha" "$r/skills/_shared/references" "$r/commands"
  cat > "$r/skills/alpha/SKILL.md" <<'EOF'
---
name: alpha
description: A valid sample skill.
---

**Type:** Engineer (light)

Body referencing skills/_shared/references/conv.md
EOF
  printf 'conv\n' > "$r/skills/_shared/references/conv.md"
  printf 'delegates to the alpha skill\n' > "$r/commands/alpha.md"
  cat > "$r/README.md" <<'EOF'
# Sample
<!-- mempalace-skills:start -->
Skills that require MemPalace:
<!-- mempalace-skills:end -->
EOF
  printf '%s' "$r"
}

# --- Baseline ---
R="$(make_valid)"; T "valid fixture passes" 0 "$R"

# --- Check A: frontmatter integrity ---
R="$(make_valid)"; sed -i.bak 's/^name: alpha/name: wrong/' "$R/skills/alpha/SKILL.md"
T "frontmatter name != dir fails" 1 "$R"

R="$(make_valid)"; sed -i.bak '/^description:/d' "$R/skills/alpha/SKILL.md"
T "missing description fails" 1 "$R"

R="$(make_valid)"; sed -i.bak '/^\*\*Type:/d' "$R/skills/alpha/SKILL.md"
T "missing Type line fails" 1 "$R"

R="$(make_valid)"; sed -i.bak 's/^name: alpha/name:/' "$R/skills/alpha/SKILL.md"
T "blank name field fails" 1 "$R"

R="$(make_valid)"; rm -rf "$R/skills/alpha" "$R/commands/alpha.md"
T "empty skills dir does not false-positive" 0 "$R"

# --- Check B: command delegation + orphans ---
R="$(make_valid)"; rm "$R/commands/alpha.md"
T "missing command delegate fails" 1 "$R"

R="$(make_valid)"; printf 'unrelated text\n' > "$R/commands/alpha.md"
T "command not referencing skill fails" 1 "$R"

R="$(make_valid)"; printf 'orphan\n' > "$R/commands/ghost.md"
T "orphan command (no skill) fails" 1 "$R"

printf '\n%s passed, %s failed\n' "$pass" "$failc"
[ "$failc" -eq 0 ]
