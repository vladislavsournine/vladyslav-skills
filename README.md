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
- **MemPalace MCP server** (required for 8 skills marked 🧠 below) — long-term cross-session memory. Configure as an MCP server in your Claude Code setup; without it, the skills below will fail when trying to read/write memory. See [`examples/mcp-config.example.json`](examples/mcp-config.example.json) for a copy-paste config block.

### Skills that require MemPalace 🧠

`add-feature`, `fix-bug`, `discover`, `discover-apple-check`, `design-sync`, `seed-mempalace`, `pre-release-check`, `compact-save`

The other skills (`init-project`, `attach-project`, `analyze-project`, `write-*`, `help`, `swiftui-pro`, `design-page`) work without MemPalace.

## One-Terminal Workflow (v2.0)

Run any skill from a single Opus session. Skills delegate execution work to Sonnet subagents automatically — no manual `/model` switching required.

| Skill type | Where it runs |
|-----------|---------------|
| **Architect** (8 skills) | Opus main session — interactive design + synthesis. Internal `Agent(...)` dispatches annotated explicitly with `model="sonnet"` (executor work) or `model="opus"` (synthesis/research). |
| **Heavy Engineer** (6 skills) | Pre-flight Q&A in Opus main → body wrapped in Sonnet subagent dispatch (with file allowlist + structured YAML return). |
| **Light Engineer** (`compact-save`) | Opus main inline (~15s utility operations). |

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
| `/vladyslav:compact-save` | Snapshot task state to MemPalace (auto before compact) |
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

- **`/vladyslav:compact-save`** — snapshot current task state (task description, modified files, last decision, next action) to MemPalace as a `compact-save` drawer. Called automatically via `PreCompact` hook before Claude Code compresses the context window. Can also be called manually at any time.

At session start (or after compaction), the global `~/.claude/CLAUDE.md` rule **Compact-Save Continuity** searches for a recent compact-save and restores context automatically — no manual resume command needed.
