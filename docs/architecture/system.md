# System Architecture

## Skill Layout

Skills are Markdown-only — no code is shipped from this plugin. Each skill lives at `skills/<name>/` and follows one of two layouts:

**Flat layout** (default for short skills, ≤ ~250 lines):

```
skills/<name>/
  SKILL.md
```

**Modular layout** (introduced in v2.2.0 for `init-project`; reused for any skill where the SKILL.md grows past ~400 lines or where stack/variant-specific instructions can be loaded on demand):

```
skills/<name>/
  SKILL.md            # thin orchestrator + cross-cutting steps
  references/         # on-demand fragments composed into prompts
    <variant>.md      # e.g. stack-python.md, stack-swift.md
  assets/             # file templates the skill writes verbatim into projects
```

`references/` files are composed into the subagent prompt by Opus main during pre-flight — only the variants relevant to the user's choices are read. `assets/` files are read at execution time by the subagent (or the skill itself) and copied/substituted into the target project. Templates that are shared across multiple skills stay at the repo-root `templates/` (currently only `templates/DesignSystem.md`, shared between `init-project` and `design-sync`).

## Lifecycle Hooks

The plugin registers four Claude Code lifecycle hooks in `.claude/settings.json`. Hook scripts live in `.claude/hooks/` and must be portable bash (no python/node — `python3` on macOS without Xcode license fails silently).

| Hook | Script | Purpose | Failure mode |
|------|--------|---------|--------------|
| `SessionStart` | `session-start.sh` | One-line stdout reminder of the MemPalace wing for this project. Always exits 0. | Never blocks. |
| `PostToolUse` (matcher: `Edit\|Write\|MultiEdit`) | `lint-skill-frontmatter.sh` | Validates SKILL.md frontmatter (`name`, `description`, `Type:`) on every edit to `skills/**/SKILL.md`. | Exits 2 with stderr message — Claude Code surfaces the failure to the model so the bad edit can be corrected. |
| `Stop` | `check-docs-sync.sh` | Before Claude stops a turn, scans `git status` for plugin-internals changes (`skills/`, `.claude/hooks/`, `.claude-plugin/`, `commands/`, `examples/`). If found without any matching change to `docs/`, `CHANGELOG.md`, `CLAUDE.md`, `README.md`, or `SkillsManual.md`, blocks the stop and reminds the model to update documentation. Skipped when the `stop_hook_active` flag is true (loop guard). | Exits 2 with reminder; model continues working until docs are updated or it justifies the no-op. |
| `PreCompact` | inline `echo` in `settings.json` | Reminds the model to invoke `vladyslav:compact-save` before context summarisation. | Informational only. |

Hook scripts must be (a) idempotent, (b) under ~200 ms, (c) failing closed only when the failure is meaningful — `SessionStart` always succeeds; `PostToolUse` and `Stop` hooks may block to enforce invariants.

## Continuity Primitive

`vladyslav:compact-save` (added in 2.1.0, replaced stash/unstash) provides automatic intra-session state preservation. Triggered by the `PreCompact` Claude Code hook before context compaction; stores a minimal YAML snapshot in MemPalace with `room="compact-save"`. No manual resume command — the global `~/.claude/CLAUDE.md` **Compact-Save Continuity** rule re-loads state at session start or after detecting a compaction event. Latest-wins semantics: the newest drawer per wing (by `created_at`) is the live snapshot.
