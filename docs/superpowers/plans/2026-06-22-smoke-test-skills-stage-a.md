# smoke-test-skills (Stage A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a deterministic, repo-wide static validator for all skills plus a thin skill/command to run it on demand.

**Architecture:** A pure-bash validator (`scripts/validate-skills.sh`) takes an optional `ROOT` arg (defaults to repo root) and runs five independent checks across `skills/`, `commands/`, and `README.md`, printing `FAIL:` lines and exiting non-zero on any failure. A bash test harness (`scripts/test-validate-skills.sh`) builds temporary fixture trees with deliberate defects and asserts the validator's exit codes. A `Type: Architect` skill `smoke-test-skills` (with a thin command delegate) runs the validator and reports.

**Tech Stack:** POSIX bash + awk/grep/sed only — no python/node (same constraint as the existing `lint-skill-frontmatter.sh` hook, because macOS python3 stub can fail without an Xcode license).

## Global Constraints

- Pure POSIX bash; works on macOS + Linux. No python/node dependency.
- Validator must accept `ROOT` as `$1` (default: repo root = `$(dirname "$0")/..`) so tests can target fixture trees.
- `skills/_shared` is exempt from every per-skill check (it has no command and is not a skill).
- Validator emits `FAIL: <skill>: <reason>` for each failure and exits `1` if any failure occurred, `0` if clean, `2` if `skills/` is absent.
- Skill `name:` in frontmatter must equal its directory name (`skills/<name>/SKILL.md` → `name: <name>`).
- New skill requires: matching `commands/<name>.md`, README "Skills that require MemPalace" list updated only if it calls `mempalace_*` (it does not), `CHANGELOG.md` entry, `.claude-plugin/plugin.json` minor bump.

---

### Task 1: Test harness + validator skeleton + Check A (frontmatter integrity)

**Files:**
- Create: `scripts/validate-skills.sh`
- Create: `scripts/test-validate-skills.sh`

**Interfaces:**
- Produces: `validate-skills.sh [ROOT]` — exit `0` clean, `1` on failure, `2` if no `skills/`. Helper shell funcs `frontmatter <file>`, `body <file>`, `err <msg>`.
- Produces (harness): `T <desc> <expected_exit> <root>`; `make_valid` → prints a fresh temp root containing one valid skill `alpha`, its command, a `_shared/references/conv.md`, and a README with mempalace markers.

- [ ] **Step 1: Write the test harness with the baseline + a frontmatter-defect test**

Create `scripts/test-validate-skills.sh`:

```bash
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

printf '\n%s passed, %s failed\n' "$pass" "$failc"
[ "$failc" -eq 0 ]
```

- [ ] **Step 2: Run the harness to verify it fails (validator does not exist yet)**

Run: `bash scripts/test-validate-skills.sh`
Expected: every `T` reports `FAIL` (validator missing → exit 127 ≠ expected), final line non-zero.

- [ ] **Step 3: Write the validator skeleton + Check A**

Create `scripts/validate-skills.sh`:

```bash
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
```

- [ ] **Step 4: Run the harness to verify Check A passes**

Run: `bash scripts/test-validate-skills.sh`
Expected: the baseline + three Check-A tests print `ok`; final line `4 passed, 0 failed` and exit 0.

- [ ] **Step 5: Commit**

```bash
chmod +x scripts/validate-skills.sh scripts/test-validate-skills.sh
git add scripts/validate-skills.sh scripts/test-validate-skills.sh
git commit -m "feat: skill validator skeleton + frontmatter check (Stage A)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: Check B (command delegation + orphans)

**Files:**
- Modify: `scripts/validate-skills.sh` (add `check_commands`, wire into `main`)
- Modify: `scripts/test-validate-skills.sh` (add two tests)

**Interfaces:**
- Consumes: `for_each_skill`, `err`, `$COMMANDS`, `$SKILLS` from Task 1.
- Produces: `check_commands` — flags a skill with no `commands/<name>.md`, a command that never mentions its skill name, and an orphan command with no skill dir.

- [ ] **Step 1: Add the failing tests**

Append before the summary block in `scripts/test-validate-skills.sh`:

```bash
# --- Check B: command delegation + orphans ---
R="$(make_valid)"; rm "$R/commands/alpha.md"
T "missing command delegate fails" 1 "$R"

R="$(make_valid)"; printf 'unrelated text\n' > "$R/commands/alpha.md"
T "command not referencing skill fails" 1 "$R"

R="$(make_valid)"; printf 'orphan\n' > "$R/commands/ghost.md"
T "orphan command (no skill) fails" 1 "$R"
```

- [ ] **Step 2: Run to verify the new tests fail**

Run: `bash scripts/test-validate-skills.sh`
Expected: the three new tests report `FAIL` (Check B not implemented → fixtures still exit 0).

- [ ] **Step 3: Implement `check_commands` and wire it**

Add after `check_frontmatter` in `scripts/validate-skills.sh`:

```bash
check_commands() { # name, file (file unused; kept for for_each_skill signature)
  local name="$1" cmd="$COMMANDS/$1.md"
  if [ ! -f "$cmd" ]; then err "$name: missing commands/$name.md"; return; fi
  grep -q "$name" "$cmd" || err "$name: command does not reference skill"
}

check_orphan_commands() {
  local cmd name
  for cmd in "$COMMANDS"/*.md; do
    [ -f "$cmd" ] || continue
    name="$(basename "$cmd" .md)"
    [ -d "$SKILLS/$name" ] || err "command $name.md has no skill dir"
  done
}
```

Then add to `main`, after `for_each_skill check_frontmatter`:

```bash
  for_each_skill check_commands
  check_orphan_commands
```

- [ ] **Step 4: Run to verify all pass**

Run: `bash scripts/test-validate-skills.sh`
Expected: `7 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/validate-skills.sh scripts/test-validate-skills.sh
git commit -m "feat: validator command-delegation + orphan check (Stage A)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Check C (cross-reference existence)

> **CORRECTED during implementation:** the shipped Check C validates ONLY
> `skills/_shared/references/*.md`. The `docs/**.md` branch shown below was
> dropped — those paths are targets the skill creates in the end user's
> project, not files in this repo (they caused ~30 false positives). Also
> `for_each_skill` was changed to iterate only directories containing a
> `SKILL.md`. See the shipped `scripts/validate-skills.sh` for the final code.

**Files:**
- Modify: `scripts/validate-skills.sh` (add `check_crossrefs`, wire into `main`)
- Modify: `scripts/test-validate-skills.sh` (add one test)

**Interfaces:**
- Consumes: `for_each_skill`, `err`, `$ROOT` from Task 1.
- Produces: `check_crossrefs` — for each `skills/_shared/references/*.md` or `docs/**.md` path mentioned in a SKILL.md, fail if the file does not exist under `ROOT`.

- [ ] **Step 1: Add the failing test**

Append before the summary block in `scripts/test-validate-skills.sh`:

```bash
# --- Check C: cross-reference existence ---
R="$(make_valid)"
printf 'see skills/_shared/references/missing.md\n' >> "$R/skills/alpha/SKILL.md"
T "broken _shared reference fails" 1 "$R"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash scripts/test-validate-skills.sh`
Expected: the new test reports `FAIL` (fixture still exits 0).

- [ ] **Step 3: Implement `check_crossrefs` and wire it**

Add after `check_orphan_commands` in `scripts/validate-skills.sh`:

```bash
check_crossrefs() { # name, file
  local name="$1" f="$2" refs ref
  [ -f "$f" ] || return
  refs="$(grep -oE '(skills/_shared/references/[A-Za-z0-9_./-]+\.md|docs/[A-Za-z0-9_./-]+\.md)' "$f" | sort -u)"
  for ref in $refs; do
    [ -e "$ROOT/$ref" ] || err "$name: broken reference $ref"
  done
}
```

Add to `main`, after `check_orphan_commands`:

```bash
  for_each_skill check_crossrefs
```

- [ ] **Step 4: Run to verify all pass**

Run: `bash scripts/test-validate-skills.sh`
Expected: `8 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/validate-skills.sh scripts/test-validate-skills.sh
git commit -m "feat: validator cross-reference existence check (Stage A)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: Check D (explicit `model=` in Architect `Agent()` calls)

**Files:**
- Modify: `scripts/validate-skills.sh` (add `check_agent_model`, wire into `main`)
- Modify: `scripts/test-validate-skills.sh` (add one test + a valid-Architect baseline)

**Interfaces:**
- Consumes: `for_each_skill`, `body`, `err` from Task 1.
- Produces: `check_agent_model` — only for skills whose body `Type:` is `Architect`; any line containing `Agent(` that lacks `model` fails. Heuristic (line-scoped), per spec.

- [ ] **Step 1: Add the failing test + a passing-Architect control**

Append before the summary block in `scripts/test-validate-skills.sh`:

```bash
# --- Check D: Architect Agent() must pass model= ---
R="$(make_valid)"
sed -i.bak 's/^\*\*Type:\*\* Engineer (light)/**Type:** Architect/' "$R/skills/alpha/SKILL.md"
printf 'Dispatch: Agent(prompt, subagent_type="x")\n' >> "$R/skills/alpha/SKILL.md"
T "Architect Agent() without model fails" 1 "$R"

R="$(make_valid)"
sed -i.bak 's/^\*\*Type:\*\* Engineer (light)/**Type:** Architect/' "$R/skills/alpha/SKILL.md"
printf 'Dispatch: Agent(prompt, model="sonnet")\n' >> "$R/skills/alpha/SKILL.md"
T "Architect Agent() with model passes" 0 "$R"
```

- [ ] **Step 2: Run to verify the first new test fails**

Run: `bash scripts/test-validate-skills.sh`
Expected: "Architect Agent() without model fails" reports `FAIL` (not yet implemented).

- [ ] **Step 3: Implement `check_agent_model` and wire it**

Add after `check_crossrefs` in `scripts/validate-skills.sh`:

```bash
check_agent_model() { # name, file
  local name="$1" f="$2" line
  [ -f "$f" ] || return
  body "$f" | grep -qiE '^\**Type:\**[[:space:]]*Architect' || return
  while IFS= read -r line; do
    printf '%s' "$line" | grep -q 'model' || err "$name: Agent() without model= -> $line"
  done < <(grep -E 'Agent\(' "$f")
}
```

Add to `main`, after `for_each_skill check_crossrefs`:

```bash
  for_each_skill check_agent_model
```

- [ ] **Step 4: Run to verify all pass**

Run: `bash scripts/test-validate-skills.sh`
Expected: `10 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/validate-skills.sh scripts/test-validate-skills.sh
git commit -m "feat: validator Architect Agent() model= check (Stage A)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: Check E (README ↔ MemPalace bidirectional sync)

> **CORRECTED during implementation:** the shipped backward pass checks ONLY
> that each listed name is a real skill directory — it does NOT require a
> literal `mempalace_` token. Orchestrators (`add-feature`, `fix-bug`) require
> MemPalace via natural-language instructions without naming the tool, so the
> token-based backward check shown below false-positived on them. The forward
> pass (literal callers must be listed) is unchanged. See the shipped
> `scripts/validate-skills.sh` for the final code.

**Files:**
- Modify: `scripts/validate-skills.sh` (add `check_mempalace_readme`, wire into `main`)
- Modify: `scripts/test-validate-skills.sh` (add two tests)

**Interfaces:**
- Consumes: `err`, `$README`, `$SKILLS` from Task 1. Relies on README markers `<!-- mempalace-skills:start -->` / `<!-- mempalace-skills:end -->` (already present in `make_valid`; added to the real README in Task 6).
- Produces: `check_mempalace_readme` — forward: every skill calling `mempalace_*` is listed between the markers; backward: every backticked name between the markers is a real skill that calls `mempalace_*`; fails if markers absent.

- [ ] **Step 1: Add the failing tests**

Append before the summary block in `scripts/test-validate-skills.sh`:

```bash
# --- Check E: README <-> MemPalace sync ---
R="$(make_valid)"
printf 'calls mempalace_search here\n' >> "$R/skills/alpha/SKILL.md"
T "mempalace caller missing from README fails" 1 "$R"

R="$(make_valid)"
sed -i.bak 's/Skills that require MemPalace:/Skills that require MemPalace: `beta`/' "$R/README.md"
T "README lists unknown/non-caller skill fails" 1 "$R"
```

- [ ] **Step 2: Run to verify the new tests fail**

Run: `bash scripts/test-validate-skills.sh`
Expected: both new tests report `FAIL` (not yet implemented).

- [ ] **Step 3: Implement `check_mempalace_readme` and wire it**

Add after `check_agent_model` in `scripts/validate-skills.sh`:

```bash
check_mempalace_readme() {
  local section d name f listed
  [ -f "$README" ] || { err "README: file missing"; return; }
  section="$(awk '/<!-- mempalace-skills:start -->/{p=1;next} /<!-- mempalace-skills:end -->/{p=0} p' "$README")"
  if ! grep -q 'mempalace-skills:start' "$README"; then
    err "README: mempalace-skills markers not found"; return
  fi
  # forward: every mempalace caller is listed
  for d in "$SKILLS"/*/; do
    name="$(basename "$d")"; [ "$name" = "_shared" ] && continue
    f="$d/SKILL.md"; [ -f "$f" ] || continue
    grep -q 'mempalace_' "$f" || continue
    printf '%s' "$section" | grep -q "\`$name\`" || err "$name: calls mempalace_* but missing from README list"
  done
  # backward: every listed name is a real mempalace caller
  for name in $(printf '%s' "$section" | grep -oE '`[a-z0-9-]+`' | tr -d '`' | sort -u); do
    if [ ! -d "$SKILLS/$name" ]; then err "README list has unknown skill \`$name\`"; continue; fi
    grep -q 'mempalace_' "$SKILLS/$name/SKILL.md" 2>/dev/null || err "README lists \`$name\` but it has no mempalace_* call"
  done
}
```

Add to `main`, after `for_each_skill check_agent_model`:

```bash
  check_mempalace_readme
```

- [ ] **Step 4: Run to verify all pass**

Run: `bash scripts/test-validate-skills.sh`
Expected: `12 passed, 0 failed`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/validate-skills.sh scripts/test-validate-skills.sh
git commit -m "feat: validator README<->MemPalace sync check (Stage A)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: Skill + command + docs; run validator on the real repo

**Files:**
- Create: `skills/smoke-test-skills/SKILL.md`
- Create: `commands/smoke-test-skills.md`
- Modify: `README.md` (add the skill; wrap the MemPalace list in markers)
- Modify: `CHANGELOG.md` (new entry)
- Modify: `.claude-plugin/plugin.json` (minor version bump)

**Interfaces:**
- Consumes: `scripts/validate-skills.sh` from Tasks 1-5.
- Produces: skill `smoke-test-skills` invocable as `/vladyslav:smoke-test-skills`.

- [ ] **Step 1: Create the skill**

Create `skills/smoke-test-skills/SKILL.md`:

```markdown
---
name: smoke-test-skills
description: Use to batch-validate all skills in this plugin. Runs deterministic repo-wide static checks (frontmatter, command delegation, cross-references, Architect model= rule, README<->MemPalace sync) and reports pass/fail.
---

**Type:** Architect

Run the deterministic validator and report results. This is Stage A
(static checks only); isolated subagent invocation of smoke-safe skills is a
planned follow-up (Stage B).

## Steps

1. Run `bash scripts/validate-skills.sh` from the repo root.
2. Surface its full output to the user.
3. If it exits non-zero, summarize each `FAIL:` line grouped by skill and
   suggest the fix. Do not auto-fix — report only.
4. End with a one-line `Next:` suggestion (e.g. re-run after fixes, or
   `/loop 10m /vladyslav:smoke-test-skills` for periodic checks).

The validator is pure bash (macOS + Linux), takes an optional `ROOT` argument
(defaults to repo root), and is safe to run anytime — it never writes files.
```

- [ ] **Step 2: Create the command delegate**

Create `commands/smoke-test-skills.md`:

```markdown
# /vladyslav:smoke-test-skills

Batch-validate all plugin skills. Delegates to the `smoke-test-skills` skill,
which runs `scripts/validate-skills.sh` (deterministic repo-wide static checks)
and reports pass/fail per skill.

Invoke the `smoke-test-skills` skill now.
```

- [ ] **Step 3: Wrap the README MemPalace list in markers**

In `README.md`, find the "Skills that require MemPalace" list and wrap it:

```markdown
<!-- mempalace-skills:start -->
... existing list of `add-feature`, `fix-bug`, ... unchanged ...
<!-- mempalace-skills:end -->
```

Also add `smoke-test-skills` to the general skills list/table (NOT the MemPalace
list — it does not call `mempalace_*`).

- [ ] **Step 4: Add a CHANGELOG entry and bump the version**

Add to `CHANGELOG.md` under a new version heading:

```markdown
### Added
- `smoke-test-skills` skill + `scripts/validate-skills.sh`: deterministic repo-wide
  static validation of all skills (frontmatter, command delegation, cross-references,
  Architect `model=` rule, README↔MemPalace sync). Stage A of the batch smoke-test.
```

Bump `.claude-plugin/plugin.json` `version` by a minor increment (new skill).

- [ ] **Step 5: Run the validator on the real repo and triage**

Run: `bash scripts/validate-skills.sh`
Expected: ideally `all checks PASS`. If real `FAIL:` lines appear, each is either
(a) a genuine pre-existing defect — fix it, or (b) a heuristic false positive
(e.g. `Agent(` inside prose) — note it and, if needed, narrow the check. Do not
silence a real failure to make the run green.

Also run the harness once more: `bash scripts/test-validate-skills.sh` → `12 passed, 0 failed`.

- [ ] **Step 6: Commit**

```bash
git add skills/smoke-test-skills/SKILL.md commands/smoke-test-skills.md \
  README.md CHANGELOG.md .claude-plugin/plugin.json
git commit -m "feat: smoke-test-skills skill + command + docs (Stage A)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Notes for Stage B (out of scope here)

Stage B extends `skills/smoke-test-skills/SKILL.md` with a parallel subagent
invocation phase over an explicit smoke-safe allowlist, using a strict
report-only contract. It is a separate plan.
