# System Architecture

## Skill Layout

Skills are Markdown-only — no code is shipped from this plugin (apart from a small set of helper bash scripts in `scripts/`). Each skill lives at `skills/<name>/` and follows one of two layouts:

**Flat layout** (default for short skills, ≤ ~250 lines):

```
skills/<name>/
  SKILL.md
```

**Modular layout** (introduced in v2.2.0 for `init-project`; in v2.3.0 also applied to `add-feature`, `pre-release-check`, and `discover`):

```
skills/<name>/
  SKILL.md            # thin orchestrator + cross-cutting steps
  references/         # on-demand fragments composed into prompts
    <variant>.md      # e.g. stack-python.md, auto-mode.md, ios-apple-check.md
  assets/             # file templates the skill writes verbatim into projects
```

`references/` files are composed into the subagent prompt (or used as a load-on-demand sub-flow) by Opus main during pre-flight — only the variants relevant to the user's choices or the current branch of execution are read. `assets/` files are read at execution time by the subagent and copied/substituted into the target project. Templates shared across multiple skills stay at the repo-root `templates/` (currently only `templates/DesignSystem.md`, shared between `init-project` and `design-sync`).

### Shared references (`skills/_shared/references/`)

Five shared reference files live under `skills/_shared/references/` and are composed into multiple skills. Owners must keep them as the canonical source of truth — heavy-engineer skills should reference them, not inline copies.

| Reference | Used by | Purpose |
|---|---|---|
| `subagent-preamble.md` | All 6 heavy-engineer skills | Sonnet subagent's role + the five mandatory rules (allowlist, no AskUserQuestion, plugin assets, idempotency, reporting) |
| `yaml-return.md` | All 6 heavy-engineer skills | Structured YAML return contract: `status`, `files_written`, `files_skipped`, `warnings`, `scope_expansion_required`, `next_step_suggestion`, `summary` |
| `present-summary.md` | All 6 heavy-engineer skills | Orchestrator-side rendering for the four `status` branches plus the re-dispatch flow |
| `mempalace-record.md` | All 8 MemPalace-using skills | Required record shape: `[WHAT] [WHY] [FILES] [DATE]` plus room-type rules and wing canonicalisation |
| `verify-pwd.md` | Architect skills with project context | Step 0.1 contract: `CLAUDE.md` presence check + canonical wing derivation, used before any user Q&A |

## Helper Scripts (`scripts/`)

Deterministic operations are extracted into bash scripts so skills don't have to instruct Claude through them. Each script is POSIX-portable (macOS + Linux), has a one-line synopsis at the top, and emits structured output (JSON or plain) that skills can pipe through `parse-yaml-return.sh` or read with simple grep.

| Script | Used by | Purpose |
|---|---|---|
| `detect-stack.sh` | `attach-project`, `discover-apple-check`, `design-sync`, `pre-release-check`, `add-feature` | Probes pwd → JSON `{ios, swift, flutter, kotlin, android, python, go, node, web, backend, plugin, ui, docker}` |
| `derive-wing.sh` | `add-feature`, `fix-bug`, `seed-mempalace`, `design-sync`, `design-page`, `compact-save` | Canonical MemPalace wing name (lowercase, platform-prefixed) — eliminates case-mismatch bugs |
| `write-stub.sh` | All scaffolding skills | Idempotent placeholder Markdown writer: `# Title\n\n*to be filled*\n` |
| `init-git-repo.sh` | `init-project`, `add-feature`, `fix-bug` | Idempotent `git init` + initial commit; safe to call on existing repos |
| `grep-replace-me.sh` | `pre-release-check` | Quote-safe placeholder grep with consistent excludes |
| `parse-yaml-return.sh` | All 6 heavy-engineer skills | Locates the last fenced ` ```yaml ` block in a subagent's response, validates `status:`, emits JSON |
| `section-status.sh` | `discover` | Scans `start-project.md` for filled vs pending sections (placeholder detection) |
| `changelog-from-git.sh` | `pre-release-check` | Drafts a Markdown CHANGELOG section from `git log` (human edits before commit) |
| `check-plan-scope.sh` | `add-feature` Auto-mode guard rails | Verifies the diff stays within the approved plan (files, contract hash, read-only globs) |

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
