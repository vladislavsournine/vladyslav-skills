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

| Command | Purpose | Model |
|---------|---------|-------|
| `vd-init` | Create new project | Sonnet |
| `vd-attach` | Add structure to existing project | Sonnet |
| `vd-analyze` | Analyze existing codebase | Opus |
| `vd-feature` | Add feature (full cycle) | Opus |
| `vd-stories` | Update user stories | Sonnet |
| `vd-tests` | Test documentation | Sonnet |
| `vd-docs` | Human documentation | Sonnet |
| `vd-release` | Pre-release check | Sonnet |
| `vd-help` | Show help | Sonnet |

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
