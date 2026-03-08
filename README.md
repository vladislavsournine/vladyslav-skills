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
