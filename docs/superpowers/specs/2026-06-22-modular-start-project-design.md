# Design: Modular adaptive `init-project` (in-place rewrite)

> Created: 2026-06-22

## Summary

Rewrite `vladyslav:init-project` in place: keep the command name and entry point, but
replace its monolithic fixed-tree behavior with a single adaptive orchestrator. Instead
of scaffolding a fixed project tree, the skill always lays a bare AI shell (CORE) and
creates everything else **only on explicit confirmation**. The monolithic
`scripts/scaffold-project.sh` is decomposed into independent, idempotent, re-runnable
per-component module scripts under `scripts/modules/`, which the orchestrator calls
à la carte.

Guiding principle, end to end: **"don't know → don't create."** No empty stub files,
no uniform tree imposed on every project.

> **Decided at review:** keep the name `init-project` (muscle memory) with the new
> behavior. Version bump = **minor**.

---

## Motivation

Today there are two entry points:

| Skill | For | Code stack | Docs tree |
|-------|-----|-----------|-----------|
| `init-project` | new project | **yes** — FastAPI `main.py`, `requirements.txt`, Dockerfile, compose, Swift project, etc. | heavy: product / architecture / ux / plans / testing / release / marketing / operations |
| `attach-project` | existing project | no — AI shell only | light (3 stubs) |

Neither offers "give me just the meta layer, minimal, no junk folders, no stack
boilerplate." The closest, `init-project --backend none --frontend none`, still emits
the full 8-category docs tree, no design system, no docker, no MemPalace/memory seed.

Every project differs; a fixed template creates dead stub files that hang unfilled for
months. The fix is to make creation adaptive at the orchestration layer while keeping
the proven deterministic bash for the mechanical work.

---

## Locked decisions

1. **`init-project` keeps its name and command**, rewritten in place as the adaptive
   orchestrator (single new-project entry point).
2. **`scaffold-project.sh` is decomposed** into modular scripts that the rewritten
   `init-project` consumes. The monolith is deleted.
3. **`attach-project` is unchanged** (separate scenario: existing projects).
4. **CORE is always created, with zero questions.** Everything else is opt-in, default = no.
5. **Docs are on-demand**, not core (final call after discussion).
6. **No frontend/Swift code modules** — their projects are born from Xcode / `flutter create`.
7. **No new orchestrator/helper skills** — the lifecycle family already covers this.
8. **Roadmap-gate is inherited** by `init-project` (from
   `docs/superpowers/specs/2026-04-30-roadmap-gate-design.md`).
9. **Smart `Next:`** suggestion at the end of `init-project`, based on what was created.

---

## Skill flow

### Phase 1 — Pre-flight (Opus main)
- Verify working directory (`ls -A`); if non-empty, ask continue/abort (as `init-project` does).
- Ask **project name** (free text).
- Ask **mode** (single-select) — the only mandatory question:
  - `minimal` → CORE only, no further questions, ~1 s.
  - `interactive` → CORE + module menu.
- Resolve plugin root (same Glob approach as today).

### Phase 2 — CORE (always, no questions)
Written by `scripts/modules/core.sh`:
- `CLAUDE.md`
- `.claude/settings.json`
- `.gitignore` (base)
- MemPalace wing seed — a wing-reminder line in `CLAUDE.md` (no MCP write; wing
  materializes on first `kg_add`)
- `.remember/` skeleton

**No docs, no code files.** This is the entire `minimal` output.

### Phase 3 — Module menu (`interactive` only)
The orchestrator asks via **grouped multi-select** `AskUserQuestion` checklists (one
group per category), **default = nothing ticked**. Semantics identical to "need this?
need this?" but fewer round-trips. Only ticked modules run. Unsure → leave unticked →
nothing created.

Group order:
1. **docs**
2. **backend-infra**
3. **agents**

All groups are always shown with everything unticked. There is no separate "what's
your stack?" question — if a project has no backend, the user simply leaves the
backend-infra group untouched. This keeps "don't know → don't create" literal and
avoids stack-detection guesswork at init time.

### Phase 4 — Run selected modules
For each selected module, the orchestrator runs `scripts/modules/<name>.sh
--pwd <pwd> --plugin-root <root> [module-specific flags]`, collects each module's JSON,
and merges into one summary.

### Phase 5 — Roadmap-gate (inherited)
After modules run, ask the `init-project` roadmap question from the roadmap-gate spec:
> "Які ключові фічі плануєш в цьому проекті? Розіб'ємо на MVP-фази в `ROADMAP.md`"

- Features given → generate `ROADMAP.md` at project root with MVP phases, commit.
- Skipped ("потім" / "не знаю" / no answer) → no file. Non-blocking.

### Phase 6 — Summary + smart `Next:`
Render the merged JSON summary, then a context-aware `Next:` line:
- no docs created → "Next: docs народяться за потреби — `discover` (research),
  `write-user-stories`, `write-test-docs` коли дійдеш до них."
- backend-infra created → "Next: `add-feature` щоб почати фічу."
- minimal mode → "Next: повернись із `interactive`, або одразу `add-feature`."

The skill **never auto-runs** the next skill — it only suggests (per Scope Sentinel /
"offer is the gate").

---

## Module catalog

### CORE (always)
`core.sh` → `CLAUDE.md`, `.claude/settings.json`, `.gitignore`, MemPalace wing seed,
`.remember/`.

### docs (opt-in)
| Module | Writes |
|--------|--------|
| `docs.sh` (prd + planning) | `docs/product/prd.md`, `docs/plans/{tasks,backlog-next}.md` |
| `design-system.sh` | `docs/design/system.md` (always available, not UI-gated) |
| `architecture.sh` | `docs/architecture/system.md` |

### backend-infra (opt-in)
| Module | Writes |
|--------|--------|
| `docker.sh` | `Dockerfile`, `docker-compose.yml`, `docs/operations/docker.md` |
| `postgres.sh` | postgres service in compose, `.env` keys |
| `redis.sh` | redis service in compose |
| `alembic.sh` | `alembic.ini`, `migrations/`, first revision stub |
| `backend-skeleton.sh` | `requirements.txt`, `src/main.py` (minimal, **not** FastAPI boilerplate) |

### agents (opt-in)
`agents.sh` → `.claude/agents/<name>.md` for any of:
architect-reviewer, backend-engineer, qa-reviewer, release-manager.

---

## Module script architecture

`scripts/scaffold-project.sh` is split into `scripts/modules/`:

```
scripts/modules/
  core.sh            docs.sh            design-system.sh   architecture.sh
  docker.sh          postgres.sh        redis.sh           alembic.sh
  backend-skeleton.sh                   agents.sh
```

Each module:
- Accepts `--pwd <project> --plugin-root <root>` plus module-specific flags
  (e.g. `docker.sh --domain`, `backend-skeleton.sh --lang`).
- Emits a single JSON line: `{ "status", "files_written", "files_skipped", "warnings", "error" }`.
- Is **idempotent and re-runnable** — never overwrites an existing file; reports it in
  `files_skipped`. Re-running adds only what's missing. This is what makes
  *"docker оновлювався просто"* work: re-run `docker.sh` after adding postgres/redis and
  it appends the missing service without clobbering the user's edits.
- `alembic.sh` lays the migration scaffold only; actual revisions are generated by the
  developer with `alembic revision` afterward and live their own life.

The orchestrator is the only consumer; modules are not exposed as user commands.

A small shared helper (`scripts/modules/_lib.sh`) holds the JSON-emit + skip-if-exists
helpers so each module stays short and consistent.

---

## What `init-project` does NOT create (on-demand ownership)

These docs are never stubbed at init. Each is created by the skill that owns it, when
that work actually happens:

| Doc | Owning skill |
|-----|--------------|
| competitors / market | `discover` |
| user-stories | `write-user-stories` |
| testing (test-plan, manual-qa) | `write-test-docs` |
| release (checklist, changelog, rollback) | `pre-release-check` / release-manager |
| ux (screens, flows) | `design-page` / `add-feature` |
| marketing (launch-notes) | `discover` |
| adr | `add-feature` / `fix-bug` |

Result: a folder appears when its owning skill runs — no dead stubs.

---

## Frontend / Swift

No code-scaffolding modules. For Swift/Flutter/Kotlin projects, `init-project`
contributes only CORE + (opt-in) docs + design-system + agents. The actual project is
created by native tooling (Xcode / `xcodegen`, `flutter create`). The backend-infra
group is still shown but left untouched for a pure frontend/Swift project.

---

## Migration (in-place rewrite of `init-project`)

- Rewrite `skills/init-project/SKILL.md` body to the adaptive orchestrator flow.
  Command name and `commands/init-project.md` are kept (command delegates as before).
- Refactor `scripts/scaffold-project.sh` → `scripts/modules/*` (delete the monolith).
- Keep `scripts/detect-stack.sh` (still used by `attach-project`).
- Update `skills/help/SKILL.md`: `init-project` row description + "New project" workflow
  reflect the new minimal/interactive behavior (name unchanged).
- Update `README.md` and `CLAUDE.md` `init-project` descriptions where they imply a fixed
  full tree.
- `CHANGELOG.md` entry + `.claude-plugin/plugin.json` **minor** version bump.
- `references/stack-*.md` retained for human reading (as today).

---

## Out of scope (YAGNI)

- No new "helper" skill that proposes next steps — covered by per-skill `Next:` + `help`.
- No auto-running of downstream skills — confirmation is always the gate.
- No new lifecycle orchestrators — the family already exists.
- No extended-docs bulk-stub module — on-demand ownership replaces it.
- No changes to `attach-project`.

---

## Testing / verification

- **Frontmatter lint** — automatic via `PostToolUse` hook on `init-project/SKILL.md`.
- **Smoke run** — invoke `init-project` in a fresh `/tmp/` dir; confirm `minimal`
  produces exactly CORE and nothing else.
- **Module idempotency** — run each module twice; second run must report all paths in
  `files_skipped`, write nothing new.
- **End-to-end** — `interactive` run selecting docs + docker + postgres + alembic on a
  throwaway project; verify compose has both services, alembic scaffold present, no FastAPI
  boilerplate, no dead doc stubs.
- **Rewrite check** — `/vladyslav:init-project` still resolves and now runs the
  minimal/interactive flow; `help` and `README` describe the new behavior, not the old
  fixed tree; no references to `scaffold-project.sh` remain.

---

## Resolved at review

1. **Name** — keep `init-project` (in-place rewrite, no rename).
2. **Version bump** — **minor**.
