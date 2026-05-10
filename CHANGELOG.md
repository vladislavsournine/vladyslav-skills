# Changelog

## v2.3.2 — 2026-05-10

### Fixed

- **Bypass Skill tool dispatch in all 17 commands.** During v2.3.1 smoke-tests, `/vladyslav:<name>` slash-commands were still showing `Successfully loaded skill` repeatedly with no SKILL.md body delivered to the model. Root cause: in current Claude Code (2.1.138), the `Skill` tool — which gets invoked when a command body says `Invoke the X skill` — returns a launch acknowledgement but does not actually deliver the skill body into the conversation. v2.3.1 fixed the pre-existing `disable-model-invocation` block, but did not change this dispatch path.
- All 17 `commands/*.md` rewritten so their bodies tell the model to **read SKILL.md directly via `Glob` + `Read`**, never going through the `Skill` tool. The new pattern is:

  ```
  Locate and read the skill body for vladyslav:<name>. Use the Glob tool with
  pattern '~/.claude/plugins/cache/vladyslav-marketplace/vladyslav/*/skills/<name>/SKILL.md'
  to find it (the version directory varies). If Glob returns no match, fall back to
  '/Volumes/DevSSD/Development/vladyslav-skills/skills/<name>/SKILL.md' (development clone).
  Read the matched file with the Read tool, then follow its instructions exactly from
  top to bottom. Do not call the Skill tool — load the file directly.
  ```

### Migration

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…and restart your Claude session. `/vladyslav:<name>` slash-commands now load SKILL.md content reliably.

---

## v2.3.1 — 2026-05-10

### Fixed

- **Removed `disable-model-invocation: true`** from all 16 `commands/*.md` frontmatter. The original intent (block automatic model-driven skill invocation while keeping explicit slash-commands available) was broken by current Claude Code semantics: the field also blocked the `Skill` tool from delivering the SKILL.md body to the model when a slash-command was used. Result was endless `Successfully loaded skill` echoes with no instructions reaching the model. Removing the field restores normal slash-command behaviour. Skills still self-describe in their `description:` field so the model knows when *not* to invoke automatically.
- `marketplace.json` and `plugin.json` synced to v2.3.1.
- `SkillsManual.md` updated to remove the obsolete policy paragraph.

### Migration

After pulling this version, run inside Claude Code:

```
/plugin marketplace update vladyslav-marketplace
/plugin update vladyslav
```

…then restart your Claude session. Slash-commands like `/vladyslav:init-project` will now load the skill body normally.

---

## v2.3.0 — 2026-05-10

Strategic refactor pass: deduplicate boilerplate across heavy-engineer skills, lift deterministic operations into bash scripts, propagate the modular Hybrid layout introduced for `init-project` to the next three largest skills.

### Added

- **`skills/_shared/references/`** — five shared reference files used across 6 heavy-engineer skills:
  - `subagent-preamble.md` — Sonnet subagent role + five mandatory rules (allowlist, no AskUserQuestion, plugin assets, idempotency, reporting)
  - `yaml-return.md` — structured YAML return contract (single source of truth for `status` / `files_written` / `scope_expansion_required` / etc.)
  - `present-summary.md` — orchestrator-side rendering for the four `status` branches plus re-dispatch flow
  - `mempalace-record.md` — required `[WHAT] [WHY] [FILES] [DATE]` record shape and room-type rules
  - `verify-pwd.md` — Step 0.1 contract for architect skills: `CLAUDE.md` check + canonical wing derivation

- **`scripts/` directory** — 9 portable bash helpers replacing deterministic in-skill instructions:
  - `detect-stack.sh` — probes pwd → JSON describing detected stacks
  - `derive-wing.sh` — canonical MemPalace wing name (eliminates case-mismatch bugs)
  - `write-stub.sh` — idempotent placeholder Markdown writer
  - `init-git-repo.sh` — idempotent `git init` + initial commit
  - `grep-replace-me.sh` — quote-safe placeholder grep
  - `parse-yaml-return.sh` — extracts and validates the last fenced ```yaml block from a subagent response
  - `section-status.sh` — scans `start-project.md` for filled vs pending sections
  - `changelog-from-git.sh` — drafts a Markdown CHANGELOG section from `git log`
  - `check-plan-scope.sh` — verifies an `add-feature` Auto-mode diff stays within the approved plan

- **New per-skill references** for the three additional Hybrid refactors:
  - `skills/add-feature/references/auto-mode.md` — Auto-mode-specific Steps 6-8 plus approval map
  - `skills/pre-release-check/references/ios-apple-check.md` — iOS-only Apple-review block
  - `skills/discover/references/discover-section.md` — generic per-section flow plus per-step parameter blocks for Steps 4-7

### Changed

- **All 17 skill descriptions shortened** in frontmatter — total 3437 → 2034 chars (~350 token saving in system prompt). Top three reductions: `design-sync` (375 → 173), `discover-apple-check` (321 → 154), `design-page` (300 → 154).
- **Six heavy-engineer SKILL.md** files refactored to compose from shared references instead of carrying inline boilerplate:
  - `init-project` 439 → 379 lines
  - `attach-project` 215 → 162
  - `write-user-stories` 172 → 125
  - `write-test-docs` 183 → 134
  - `write-project-docs` 259 → 208
  - `pre-release-check` 370 → 320 (further reduced to 240 in the Hybrid pass below)
- **Three additional Hybrid layouts** (SKILL.md + `references/` per skill, following the `init-project` pattern):
  - `add-feature` 388 → 294 lines (Auto-mode → `references/auto-mode.md`)
  - `pre-release-check` 320 → 240 (iOS Apple-check → `references/ios-apple-check.md`)
  - `discover` 330 → 140 (per-section flow → `references/discover-section.md`)
- `docs/architecture/system.md` updated with new `Shared references` and `Helper Scripts` sub-sections under Skill Layout.

### Strategic notes

- Combined effect: **~10k tokens of duplication removed** from skill bodies + **~350 tokens shaved from the system-prompt skill listing**. The latter is what unblocks `vladyslav:*` skills from the `descriptions dropped` budget when many other plugins are installed.
- Lean and untouched (already well-factored): `compact-save` (60 lines), `swiftui-pro` (61), `analyze-project` (89), `help` (106), `fix-bug` (117).
- NOT collapsed: `init-project` ↔ `attach-project` (workflows different — clean-slate vs append-only). `add-feature` ↔ `fix-bug` (phases and ordering differ enough that a shared core would leak).

---

## v2.2.0 — 2026-05-09

### Added

- `.claude/hooks/session-start.sh` — silent SessionStart hook reminding which MemPalace wing this project uses.
- `.claude/hooks/lint-skill-frontmatter.sh` — PostToolUse hook validating SKILL.md frontmatter (`name`, `description`, `Type:`) on every Edit/Write/MultiEdit. Pure bash + awk, no python/node dependency.
- `.claude/hooks/check-docs-sync.sh` — Stop hook that blocks turn-stop with `exit 2` if plugin internals (`skills/`, `.claude/hooks/`, `.claude-plugin/`, `commands/`, `examples/`) were modified without a matching update to `docs/`, `CHANGELOG.md`, `CLAUDE.md`, `README.md`, or `SkillsManual.md`. Loop-safe via `stop_hook_active` flag. Forces documentation to stay in sync with code automatically.
- `examples/mcp-config.example.json` — copy-paste MCP config block for the MemPalace dependency. Linked from the README Requirements section.
- CLAUDE.md sections: `Review Checklist`, `Skill Testing`, `Hooks`. The checklist enumerates the rules that the new lint hook enforces automatically and the rules that remain manual.

### Changed

- **`init-project` skill restructured into the modular `SKILL.md` + `references/` + `assets/` layout (Hybrid refactor).**
  - Stack-specific scaffolding instructions extracted into `skills/init-project/references/stack-{python,go,swift,flutter,kotlin,other}.md` and `references/backend-shared.md`. Each fragment is composed into the subagent prompt only when its stack was selected in pre-flight.
  - Exclusive file templates moved from the repo-root `templates/` into `skills/init-project/assets/` (preserving the `swift/`, `backend/`, `infra/`, `docs/operations/` subtree). Only `templates/DesignSystem.md` stays at the root because it is shared with the `design-sync` skill.
  - `SKILL.md` shrunk from 621 lines to 439 — pre-flight Q&A and cross-stack scaffolding (CLAUDE.md template, agents, doc stubs, git init) remain in place; everything stack-specific now loads on demand.
  - Subagent dispatch pattern preserved: pre-flight in Opus main → Sonnet subagent writes the scaffold → YAML return contract. No user-facing behavioural change.
  - Added new `Step 1: Compose stack fragments` to the Process section, documenting how Opus main reads the relevant `references/` files and substitutes them into the `<STACK_FRAGMENTS>` placeholder of the subagent prompt.

### Fixed

- `skills/help/SKILL.md` and `skills/swiftui-pro/SKILL.md` were missing the `Type:` line required by `CLAUDE.md` working rules. Added `Type: Engineer (light)` and `Type: Architect` respectively.
- README requirements line previously claimed "9 skills" require MemPalace; the actual list is 8.

---

## v2.0.0 — 2026-05-06

### BREAKING

- **Drop two-terminal workflow.** Single-terminal: Opus main session + Sonnet subagent dispatch for execution work. Manual `/model` switching no longer needed.
- **Architect skills** no longer print `━━━ Next (Sonnet terminal) ━━━` handoff blocks. They run interactively in Opus main and end with a plain "Next steps:" list.
- **Heavy Engineer skills** (`write-test-docs`, `write-project-docs`, `write-user-stories`, `attach-project`, `init-project`, `pre-release-check`) now wrap their body in a Sonnet subagent dispatched from Opus main, with pre-flight Q&A in the main session and a YAML-formatted return contract enforcing a strict file allowlist.
- **Light Engineer skills** (`stash`, `unstash`) keep inline behavior in main thread (~30s utility operations; dispatch overhead would exceed the work).
- Architect skills with internal `Agent(...)` dispatches now annotate every dispatch with explicit `model=` (`"sonnet"` for executor work, `"opus"` for synthesis/research). Affected: `add-feature` (5 dispatches → sonnet), `design-page` (1 dispatch → opus).
- Skill `Type:` headers updated: `Architect (Opus)` → `Architect`; `Engineer (Sonnet)` → `Engineer` (heavy) or `Engineer (light)` (stash, unstash).
- `commands/*.md` files no longer contain `/model …` switch instructions.

### Migration

If you were on the v1.x two-terminal workflow:
1. Close your "Engineer" terminal.
2. Run all skills from a single Opus session.
3. No code changes on your side — skills handle dispatching internally.

### Documentation

- `README.md`, `CLAUDE.md`, `skills/help/SKILL.md` updated to describe the one-terminal workflow.
- New design doc: `docs/superpowers/specs/2026-05-06-opus-subagent-dispatch-design.md`.
- New plan doc: `docs/superpowers/plans/2026-05-06-opus-subagent-dispatch.md`.

---

## v1.8.0 — 2026-04-30

Roadmap gate for `add-feature` and `init-project`.
