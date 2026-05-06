# vladyslav-skills

Claude Code plugin providing skills for project scaffolding, analysis, documentation, and release management.

## Project Type

Claude Code plugin (`vladyslav` namespace). No traditional backend/frontend stack — all functionality is delivered via Markdown skill files.

## Source of Truth

| Doc | Purpose |
|-----|---------|
| `README.md` | Installation, usage, workflow overview |
| `docs/product/prd.md` | Product requirements |
| `docs/architecture/system.md` | Plugin architecture and skill design |
| `docs/plans/tasks.md` | Active tasks |
| `docs/plans/backlog-next.md` | Upcoming work |

## Structure

```
skills/          # Skill SKILL.md files (one dir per skill)
commands/        # Slash command .md files (one per skill)
.claude-plugin/  # Plugin metadata (plugin.json)
.claude/         # Claude Code local config and agents
docs/            # Architecture, product, and planning docs
```

## Working Rules

- Each skill lives in `skills/<name>/SKILL.md`
- Each command lives in `commands/<name>.md` and delegates to its skill
- Skill names follow `vladyslav:<name>` namespace
- Skills declare `Type: Architect`, `Type: Engineer`, or `Type: Engineer (light)` in their header
- **Architect skills** run interactively in Opus main session. When they dispatch a subagent via `Agent(...)`, they MUST specify `model` explicitly: `model="sonnet"` for executor work (write tests, write impl, run review/security checks); `model="opus"` for synthesis/research work (deep analysis, multi-source research, design decisions)
- **Heavy Engineer skills** wrap their body in a Sonnet subagent dispatch with pre-flight Q&A in Opus main + a YAML return contract. Pre-flight verifies inputs and asks the user about ambiguity; the subagent runs deterministic work against a strict file allowlist
- **Light Engineer skills** (`stash`, `unstash`) run inline in main thread (~30s utility operations; dispatch overhead would exceed the work)
- Engineer skill summaries end with a "Next: …" suggestion; Architect skills end with a "Next steps:" list. Both use one-terminal language — no decorator-handoff blocks, no model-switch instructions
- Do not add translations until the finalization phase (pre-release-check)

## Versioning

Version is defined in `.claude-plugin/plugin.json`. Bump on every meaningful change.

## Dependencies

- [Superpowers plugin](https://github.com/obra/superpowers) — all 13 non-meta superpowers skills are referenced
- **MemPalace MCP server** — required by 9 skills (`add-feature`, `fix-bug`, `discover`, `discover-apple-check`, `design-sync`, `seed-mempalace`, `pre-release-check`, `stash`, `unstash`). When editing or adding skills that call `mempalace_*` tools, declare the dependency in the skill's SKILL.md and update the README "Skills that require MemPalace" list.
