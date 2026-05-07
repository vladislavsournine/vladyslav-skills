# Changelog

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
