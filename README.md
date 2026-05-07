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
- [Superpowers plugin](https://github.com/obra/superpowers) — used by `add-feature`, `fix-bug`, `analyze-project`, `pre-release-check`, `write-test-docs`
- **MemPalace MCP server** (required for 9 skills marked 🧠 below) — long-term cross-session memory. Configure as an MCP server in your Claude Code setup; without it, the skills below will fail when trying to read/write memory.

### Skills that require MemPalace 🧠

`add-feature`, `fix-bug`, `discover`, `discover-apple-check`, `design-sync`, `seed-mempalace`, `pre-release-check`, `stash`, `unstash`

The other skills (`init-project`, `attach-project`, `analyze-project`, `write-*`, `help`, `swiftui-pro`, `design-page`) work without MemPalace.

## One-Terminal Workflow (v2.0)

Run any skill from a single Opus session. Skills delegate execution work to Sonnet subagents automatically — no manual `/model` switching required.

| Skill type | Where it runs |
|-----------|---------------|
| **Architect** (8 skills) | Opus main session — interactive design + synthesis. Internal `Agent(...)` dispatches annotated explicitly with `model="sonnet"` (executor work) or `model="opus"` (synthesis/research). |
| **Heavy Engineer** (6 skills) | Pre-flight Q&A in Opus main → body wrapped in Sonnet subagent dispatch (with file allowlist + structured YAML return). |
| **Light Engineer** (`stash`, `unstash`) | Opus main inline (~30s utility operations). |

> Migrating from v1.x? The old dual-terminal split (Opus + Sonnet in separate windows) is gone. Close the second terminal — one Opus session handles everything.

## Skills

**Architect:**

| Skill | Purpose |
|-------|---------|
| `/vladyslav:analyze-project` | Analyze existing codebase |
| `/vladyslav:add-feature` | Add feature (full cycle, 9 superpowers) |
| `/vladyslav:fix-bug` | Fix bug (full cycle, 7 superpowers) |
| `/vladyslav:discover` | Auto-fill product/start-project.md via AI research |
| `/vladyslav:discover-apple-check` | Apple App Store compliance pre-check (iOS only) |
| `/vladyslav:design-sync` | Extract design tokens from code into docs/design/system.md |
| `/vladyslav:design-page` | Design app screens in Pencil via parallel subagents |
| `/vladyslav:seed-mempalace` | Bootstrap MemPalace memory from git log + docs |

**Heavy Engineer:**

| Skill | Purpose |
|-------|---------|
| `/vladyslav:init-project` | Create new project |
| `/vladyslav:attach-project` | Add structure to existing project |
| `/vladyslav:write-user-stories` | Update user stories |
| `/vladyslav:write-test-docs` | Test plan + manual QA docs |
| `/vladyslav:write-project-docs` | README, onboarding, deployment |
| `/vladyslav:pre-release-check` | Pre-release verification |

**Light Engineer:**

| Skill | Purpose |
|-------|---------|
| `/vladyslav:stash` | Snapshot conversation state to MemPalace |
| `/vladyslav:unstash` | Restore latest stash for the current wing |
| `/vladyslav:help` | This reference |

## Workflows

**New project:**
```
init-project → analyze-project → add-feature → write-test-docs → pre-release-check
```

**Existing project:**
```
attach-project → analyze-project → add-feature
```

**Before release:**
```
write-user-stories → write-test-docs → write-project-docs → pre-release-check
```

**Bug fix:**
```
fix-bug → write-test-docs → pre-release-check
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
