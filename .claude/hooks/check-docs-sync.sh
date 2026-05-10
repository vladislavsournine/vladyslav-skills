#!/usr/bin/env bash
# Stop hook — guard against doc drift.
# When Claude is about to finish a turn, scan `git status` for changes that
# typically need a documentation counterpart (skills, hooks, plugin metadata,
# commands, new assets/references). If any are present but no documentation
# file was touched, block the Stop event with exit 2 and surface a reminder
# to the model — it will receive stderr and continue work.
#
# Skipped when:
#   * stop_hook_active is true   (avoid infinite loop on already-blocked stop)
#   * we're not inside a git working tree
#   * no changes are pending     (tree clean)
#   * trigger files unchanged    (no plugin internals touched)
#   * at least one doc file was touched in the same session

set -u

PAYLOAD="$(cat)"

# Avoid loop: if we already blocked once and the model is trying to stop again,
# let it. Claude Code sets stop_hook_active=true on the second invocation.
if printf '%s' "$PAYLOAD" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# Not a git repo → nothing to compare against. Bail.
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# Collect every file with changes (staged, unstaged, untracked).
# `git status --porcelain` writes "XY <path>" or "XY <old> -> <new>"; strip the
# first 3 chars and the optional "old -> " prefix to recover the path.
CHANGED="$(git status --porcelain 2>/dev/null \
    | sed -E 's/^.{3}//; s/^.* -> //')"

[ -z "$CHANGED" ] && exit 0

trigger=0
doc_updated=0

while IFS= read -r f; do
    [ -z "$f" ] && continue
    # Match prefix-style — `git status --porcelain` reports untracked
    # directories as a single trailing-slash entry (e.g. `?? skills/foo/`),
    # so file-specific globs like `skills/*/SKILL.md` would miss them.
    case "$f" in
        skills/*) trigger=1 ;;
        .claude/hooks/*|.claude/settings.json) trigger=1 ;;
        .claude-plugin/*) trigger=1 ;;
        commands/*) trigger=1 ;;
        examples/*) trigger=1 ;;
        CLAUDE.md|README.md|CHANGELOG.md|SkillsManual.md) doc_updated=1 ;;
        docs/*) doc_updated=1 ;;
    esac
done <<EOF
$CHANGED
EOF

if [ "$trigger" -eq 1 ] && [ "$doc_updated" -eq 0 ]; then
    cat >&2 <<'MSG'
[check-docs-sync] You modified plugin internals (skills, hooks, plugin.json, commands, or examples) but did not update any documentation file in this session.

Doc surfaces that typically need to stay in sync — review and update whichever apply:
  - CHANGELOG.md                    — version bump, what changed and why
  - CLAUDE.md                       — if working rules / structure / hook list changed
  - README.md                       — if user-facing surface changed (skills list, commands, requirements)
  - SkillsManual.md                 — if skill catalogue or template paths changed
  - docs/architecture/system.md     — if internal patterns / hooks / skill layout changed
  - docs/diagrams/*.md              — if a flow diagram now mismatches reality

Either update the relevant docs now, or — if these changes genuinely have no doc impact (typo fix, internal-only refactor) — say so explicitly in your reply to the user before stopping. The user can override this guard by deleting the file path from `.claude/hooks/check-docs-sync.sh` registration in `.claude/settings.json` if it gets in the way.
MSG
    exit 2
fi

exit 0
