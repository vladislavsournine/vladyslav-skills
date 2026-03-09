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
- Skills declare `Type: Architect (Opus)` or `Type: Engineer (Sonnet)` in their header
- Architect skills end with a prepared prompt for the Sonnet terminal
- Engineer skills end with a report + next step
- Do not add translations until the finalization phase (pre-release-check)

## Versioning

Version is defined in `.claude-plugin/plugin.json`. Bump on every meaningful change.

## Dependencies

- [Superpowers plugin](https://github.com/obra/superpowers) — all 13 non-meta superpowers skills are referenced
