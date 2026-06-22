#!/usr/bin/env bash
# agents.sh — write requested .claude/agents/*.md files.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/_lib.sh"
AGENTS=""
parse_common_args "$@"
i=0; while [ $i -lt ${#REMAINING_ARGS[@]} ]; do
    case "${REMAINING_ARGS[$i]}" in
        --agents) AGENTS="${REMAINING_ARGS[$((i+1))]}"; i=$((i+2)) ;;
        *) i=$((i+1)) ;;
    esac
done
cd "$PROJECT_PWD" || die "cannot cd to $PROJECT_PWD"

agent_body() {
    case "$1" in
        architect-reviewer) printf '%s' '---
name: architect-reviewer
description: Reviews changes against PRD, architecture docs, and active tasks
---

Read CLAUDE.md and the source-of-truth docs before reviewing any change. Verify
alignment with the PRD and architecture, and update docs/plans/tasks.md if the change
closes a task.
' ;;
        backend-engineer) printf '%s' '---
name: backend-engineer
description: Implements backend features following the project API and DB schema
---

Read CLAUDE.md before implementing. Follow existing patterns in src/. Write or update
tests alongside implementation. Do not modify frontend/mobile code.
' ;;
        qa-reviewer) printf '%s' '---
name: qa-reviewer
description: Generates test scenarios and QA plans from PRD and user stories
---

Read CLAUDE.md and docs/product/prd.md. Generate scenarios covering happy path, error
cases, edge cases, and empty states. Write to docs/testing/.
' ;;
        release-manager) printf '%s' '---
name: release-manager
description: Prepares release documentation and runs pre-release checklist
---

Read CLAUDE.md and docs/plans/tasks.md. Verify tasks complete, tests pass, docs current.
Update the changelog with the release summary.
' ;;
        *) return 1 ;;
    esac
}

IFS=','; for a in $AGENTS; do
    a="$(printf '%s' "$a" | tr -d '[:space:]')"
    [ -z "$a" ] && continue
    body="$(agent_body "$a")" || { WARNINGS+=("unknown agent: $a"); continue; }
    write_file ".claude/agents/${a}.md" "$body"
done
unset IFS

emit_json "success"
exit 0
