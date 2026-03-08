# vladyslav-skills

Claude Code skills for project scaffolding, analysis, documentation, and release management.

## Install

```bash
git clone git@github.com:VladislavSournine/vladyslav-skills.git ~/.vladyslav-skills
~/.vladyslav-skills/install.sh
source ~/.zshrc
```

Then install the Claude Code plugin (inside a Claude session):
```
/plugin marketplace add VladislavSournine/vladyslav-skills
/plugin install vladyslav@vladyslav-marketplace
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview)
- [Superpowers plugin](https://github.com/obra/superpowers) (dependency)

## Commands

| Bash script | Slash command | Default model | Purpose |
|-------------|---------------|---------------|---------|
| `vd-init` | `/vladyslav:init-project` | Sonnet | Create new project |
| `vd-attach` | `/vladyslav:attach-project` | Sonnet | Add structure to existing project |
| `vd-analyze` | `/vladyslav:analyze-project` | Opus | Analyze existing codebase |
| `vd-feature` | `/vladyslav:add-feature` | Opus | Add feature (full cycle) |
| `vd-stories` | `/vladyslav:write-user-stories` | Sonnet | Update user stories |
| `vd-tests` | `/vladyslav:write-test-docs` | Sonnet | Test documentation |
| `vd-docs` | `/vladyslav:write-project-docs` | Sonnet | Human documentation |
| `vd-release` | `/vladyslav:pre-release-check` | Sonnet | Pre-release check |
| `vd-help` | `/vladyslav:help` | Sonnet | Show help |

Bash scripts open a new Claude session. Slash commands run inside the current session.

To override the model: `vd-init claude-opus-4-6`

## Workflows

**New project:**
```
vd-init → vd-feature → vd-tests → vd-release
```

**Existing project:**
```
vd-attach → vd-analyze → vd-feature
```

**Before release:**
```
vd-stories → vd-tests → vd-docs → vd-release
```

## Stack Support

Backend: `python` (default), `go`, `none`
Mobile: `flutter`, `swift`, `kotlin`, `none`

Combine freely: `python + swift`, `go + flutter + kotlin`, `none + flutter`, etc.
