# Design — `smoke-test-skills`

**Date:** 2026-06-22
**Status:** Approved (brainstorming)
**Author:** brainstorming session (vladiq)

## Problem

`CLAUDE.md` mandates a manual verification step after editing a skill: "invoke it
in a fresh session and confirm it loads without errors and produces the expected
first action." With 17 skills this is never done exhaustively. The existing
`PostToolUse` lint hook (`lint-skill-frontmatter.sh`) only checks **one file at
the moment it is edited** — it cannot catch cross-file regressions (a renamed
reference, a dropped command delegate, a stale README list).

We want a **batch smoke-test**: one pass that validates every skill and reports
pass/fail, runnable on demand and optionally on an interval via `/loop`.

## Key finding — `Type:` is a leaky classifier

The naive rule "statically check orchestrators, invoke the rest" does not work,
because the `Type:` header does not map cleanly to "safe to invoke":

| Skill | Type | Reality |
|-------|------|---------|
| `init-project`, `attach-project` | Engineer (light) | **scaffold files** (side effects) |
| `save`, `qsave`, `compact-save` | Engineer (light) | **write to MemPalace** (side effects) |
| `swiftui-pro` | Architect | read-only review (safe) |

Therefore "smoke-safe for invocation" is decided by an **explicit allowlist**,
not derived from `Type:`.

## Decisions

1. **What we catch:** hybrid — static cross-file checks for all 17 skills, plus
   isolated invocation for an explicit allowlist of smoke-safe skills.
2. **smoke-safe set:** explicit allowlist maintained inside the
   `smoke-test-skills` skill. Adding a skill means updating the allowlist.
3. **`/loop` role:** orthogonal scheduler. We build a one-shot command; `/loop`
   is documented (`/loop 10m /vladyslav:smoke-test-skills`), not wired in.
   `iterate-until-green` (auto-fix) is intentionally **out of scope** — auto-fixes
   without review violate the Blast Radius rule.
4. **Staging:** ship **Stage A (deterministic bash validator)** first — ~80% of
   the value at near-zero risk. **Stage B (subagent invocation)** is a documented
   follow-up.

## Architecture

Three components. Stage A delivers the first two; Stage B extends the skill.

### A. `scripts/validate-skills.sh` (Stage A)

Deterministic POSIX bash (macOS + Linux), no python/node — same constraint as the
existing hook. Repo-wide static checks the per-edit hook cannot do:

1. **Frontmatter integrity** — each `skills/<name>/SKILL.md` has a frontmatter
   block, `name:` equals `<name>`, `description:` present, body has a `Type:` line.
2. **Command delegation** — `commands/<name>.md` exists for every skill and
   references the skill name; and every `commands/<name>.md` has a matching skill
   (no orphans). `_shared` is exempt (no command).
3. **Cross-reference existence** — every `skills/_shared/references/*.md` path
   mentioned in a SKILL.md resolves to a real file. `docs/**.md` paths are NOT
   checked: in this plugin they are targets the skill creates in the END USER's
   project, not files in this repo. Only `skills/<name>/` directories that
   contain a `SKILL.md` are treated as skills (so `skills/docs/`, `skills/_shared/`
   are skipped).
4. **Explicit-model rule** — every `Agent(` dispatch inside a `Type: Architect`
   skill passes a `model` argument (CLAUDE.md orchestration rule). Block-aware
   heuristic: `model` may appear anywhere within the `Agent(...)` call block
   (e.g. on its own line in a multi-line call); a block closes on a line whose
   first non-space char is `)`, and `model` counts only with assignment syntax
   (`model=` / `model:`).
5. **MemPalace README sync** — forward: every skill whose SKILL.md contains a
   literal `mempalace_*` token appears in the README "Skills that require
   MemPalace" list (between marker comments). Backward: every name listed there
   is a real skill directory. The backward pass does NOT require a literal token
   — orchestrators (`add-feature`, `fix-bug`) require MemPalace via natural-language
   instructions without naming the tool, so a token check false-positives; the
   backward pass exists to catch stale/renamed/deleted entries.

Output: per-check `FAIL` lines with offending file paths and a non-zero exit on
any failure (CI- and `/loop`-friendly); a final all-pass line on success.

> **Implementation note (corrections during build):** Checks 3, 4, and 5 above
> reflect refinements made when the validator was first run against the real
> repo — the original draft checked `docs/**.md` (false positives on user-project
> targets), used a line-scoped `model` grep (false positives on multi-line
> `Agent()` calls), and required a literal `mempalace_` token in the backward
> pass (false positives on prose-style orchestrators). The descriptions here are
> the shipped behavior.

### B. `skills/smoke-test-skills/SKILL.md` (`Type: Architect`)

Orchestrator, run interactively in Opus main.

- **Stage A body:** run `scripts/validate-skills.sh`, surface its report.
- **Stage B body (follow-up):** after static checks, dispatch **parallel
  subagents** (`model="sonnet"` or `haiku` for this mechanical check), one per
  allowlisted smoke-safe skill, each with a strict **report-only contract**:
  > Invoke skill `<name>`. Report only: (a) did it load without error, (b) what
  > is the first action it instructs. Do NOT write files, call MemPalace, dispatch
  > agents, or ask the user anything. You are inspecting, not executing.

  Synthesize one consolidated report: per-skill ✓/✗ across static + invocation.

The smoke-safe allowlist lives in this skill's body (Decision 2).

### C. `commands/smoke-test-skills.md`

Thin delegate to the skill — matches the plugin's command→skill convention.

## Data flow

```
/vladyslav:smoke-test-skills
        │
        ▼
skills/smoke-test-skills (Architect, main session)
        │  Stage A
        ├─► scripts/validate-skills.sh ──► static report (exit code)
        │  Stage B (follow-up)
        ├─► parallel subagents (allowlist) ──► per-skill load + first-action
        ▼
   consolidated report  (optionally re-run periodically via /loop)
```

## Error handling

- Validator exits non-zero on any failed check so `/loop` and CI can branch on it.
- Each check is independent; one failure never aborts the rest of the pass.
- Stage B subagents are report-only; a subagent that errors is reported as a
  failed skill, not a crashed run (`.filter(Boolean)`-style tolerance).

## Testing

- **Stage A:** run `scripts/validate-skills.sh` on the current clean repo →
  expect all PASS. Then introduce a deliberate regression (rename a referenced
  file, drop a command delegate) → expect the matching FAIL and non-zero exit.
- **Stage B:** smoke-run `smoke-test-skills` itself (CLAUDE.md step 2) and confirm
  the report lists every allowlisted skill.

## Out of scope (YAGNI)

- Auto-fix / iterate-until-green.
- Invoking orchestrators (suppressed by allowlist, not report-only-for-all).
- A new `smoke:` frontmatter marker (rejected: 17 edits + contract change).
- Wiring `/loop` or CI by default — documented usage only.
