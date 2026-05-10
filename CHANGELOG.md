# Changelog

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
