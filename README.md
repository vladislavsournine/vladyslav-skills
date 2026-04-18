# vladyslav-skills

Claude Code skills for project scaffolding, analysis, documentation, and release management.

## Install

```bash
git clone git@github.com:VladislavSournine/vladyslav-skills.git ~/.vladyslav-skills
```

Then install the Claude Code plugin:
```bash
claude
# Inside Claude: /plugin marketplace add VladislavSournine/vladyslav-skills
#                /plugin install vladyslav@vladyslav-marketplace
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview)
- [Superpowers plugin](https://github.com/obra/superpowers) (dependency)

## Two-Terminal Workflow

Keep two terminals open:
- **Opus terminal** — research, design, diagnosis
- **Sonnet terminal** — implementation, documentation

Each skill verifies its model on start and switches if needed (`/model opus` or `/model sonnet`).

**Architect skills (Opus)** end with a prepared prompt for the Sonnet terminal.
**Engineer skills (Sonnet)** end with an implementation report + next step.

## Skills

**Architect (Opus terminal):**

| Skill | Purpose |
|-------|---------|
| `/vladyslav:analyze-project` | Analyze existing codebase |
| `/vladyslav:add-feature` | Add feature (full cycle, 9 superpowers) |
| `/vladyslav:fix-bug` | Fix bug (full cycle, 7 superpowers) |

**Engineer (Sonnet terminal):**

| Skill | Purpose |
|-------|---------|
| `/vladyslav:init-project` | Create new project |
| `/vladyslav:attach-project` | Add structure to existing project |
| `/vladyslav:write-user-stories` | Update user stories |
| `/vladyslav:write-test-docs` | Test plan + manual QA docs |
| `/vladyslav:write-project-docs` | README, onboarding, deployment |
| `/vladyslav:pre-release-check` | Pre-release verification |
| `/vladyslav:help` | This reference |

## Workflows

**New project:**
```
init-project (Sonnet) → analyze-project (Opus) → add-feature (Opus) → write-test-docs (Sonnet) → pre-release-check (Sonnet)
```

**Existing project:**
```
attach-project (Sonnet) → analyze-project (Opus) → add-feature (Opus)
```

**Before release:**
```
write-user-stories → write-test-docs → write-project-docs → pre-release-check (all Sonnet)
```

**Bug fix:**
```
fix-bug (Opus) → write-test-docs (Sonnet) → pre-release-check (Sonnet)
```

## Stack Support

**Backend:** `python` (default), `go`, `other`, `none`
**Frontend/Mobile:** `flutter`, `swift`, `kotlin`, `other`, `none`

Predefined stacks get full scaffold. "Other" = directory + docs only.

## Superpowers Integration

All 13 non-meta superpowers skills are integrated:

| Superpowers Skill | Used In | When |
|-------------------|---------|------|
| `brainstorming` | `add-feature` | Design phase |
| `writing-plans` | `add-feature` | Planning phase |
| `executing-plans` | `add-feature` | Execution (parallel session) |
| `subagent-driven-development` | `add-feature` | Execution (this session) |
| `dispatching-parallel-agents` | `add-feature`, `analyze-project` | Parallel components |
| `using-git-worktrees` | `add-feature`, `fix-bug` | Isolated branch |
| `test-driven-development` | `add-feature`, `fix-bug`, `write-test-docs` | Tests + implementation |
| `systematic-debugging` | `fix-bug` | Diagnose root cause |
| `requesting-code-review` | `add-feature`, `fix-bug` | After implementation |
| `receiving-code-review` | `add-feature`, `fix-bug` | Process feedback |
| `finishing-a-development-branch` | `add-feature`, `fix-bug` | Merge/PR |
| `verification-before-completion` | `pre-release-check` | Evidence-based checks |
| `writing-skills` | (meta) | Edit vladyslav skills |

### Session Continuity

- **`/vladyslav:stash`** — pause an in-progress task. Captures the current mental state (open question, decisions made, pending files, deferred items) to MemPalace as a `stash` drawer for the current wing.
- **`/vladyslav:unstash`** — resume a previously stashed task. Reads the latest stash (Latest-wins by `created_at`) for the current wing and restores its open question, prior work, pending files, and deferred items into the conversation. Validates `pending_files` against git state before showing them.

One active stash per wing via Latest-wins semantics — the newest `stash` drawer for a wing IS the active one. Older drawers remain as history (MemPalace drawer API is add-only). `vladyslav:add-feature` and `vladyslav:fix-bug` invoke `stash` automatically at defined checkpoints so incomplete runs are recoverable.

Companion to two global rules in `~/.claude/CLAUDE.md`: **Scope Sentinel** (catches scope creep mid-execution) and **Active Stash Notification** (informs you at session start if a stash exists for this wing).
