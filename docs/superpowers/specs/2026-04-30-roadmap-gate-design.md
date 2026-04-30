# Design: Roadmap Gate for add-feature and init-project

> Created: 2026-04-30

## Summary

Add an optional roadmap generation step inside `add-feature` and `init-project` skills. For large features or new projects, Claude generates a phased roadmap markdown file before writing the implementation plan. The roadmap becomes the parent document; the implementation plan is scoped to one phase at a time.

---

## Trigger Logic (size-gate)

Applies to: `add-feature` only (after brainstorming, before writing-plans).

The gate fires if **any one** of the following conditions is true:
- 3+ distinct components/subsystems in the design
- User language implies phasing: "поетапно", "спочатку X потім Y", "фази", "поступово", "gradually", "phases", "step by step"
- Design scope implies multiple sessions: 5+ major tasks in the initial plan

When the gate fires, Claude asks exactly:
> "Ця фіча виглядає багатофазно — є сенс розбити на фази з роадмапом перед тим як писати детальний план. Зробити?"

- **Yes** → generate roadmap, commit, scope writing-plans to Phase 1
- **No** → proceed directly to writing-plans as before (no roadmap created)

---

## Roadmap Document Structure

### add-feature → `docs/roadmap/<feature-slug>.md`

```markdown
# Roadmap: <Feature Name>

> Created: YYYY-MM-DD

## Phase 1: <Name>
**Done when:** <one sentence criteria>

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Phase 2: <Name>
**Done when:** <one sentence criteria>

- [ ] Task 1
- [ ] Task 2
```

### init-project → `ROADMAP.md` at project root

Same structure. Phases represent MVP milestones (what ships in the first release vs. what comes after).

**File naming for add-feature:** `<feature-slug>` is derived from the feature name, lowercased, spaces replaced with hyphens. Example: "User Authentication" → `user-authentication.md`.

After generation, the file is committed to git immediately.

Ongoing tracking is manual: the developer opens the file and checks off items as phases complete.

---

## Changes to `add-feature`

### Before
```
brainstorming → writing-plans → executing-plans
```

### After
```
brainstorming → [roadmap gate] → roadmap (if large) → writing-plans (Phase 1 scope) → executing-plans
```

### New step in SKILL.md

Insert between brainstorming and writing-plans:

> **Roadmap gate:** After brainstorming, assess feature complexity. If ≥3 components, ≥5 major tasks, or user signals phasing → ask "Ця фіча виглядає багатофазно — є сенс розбити на фази з роадмапом перед тим як писати детальний план. Зробити?"
>
> If yes: generate `docs/roadmap/<feature-slug>.md` with phases and done-when criteria, commit to git, then pass only Phase 1 as the scope to writing-plans.
>
> If no: proceed to writing-plans with the full feature scope as before.

---

## Changes to `init-project`

### Before
```
scaffolding → directory structure → documentation
```

### After
```
scaffolding → [MVP question] → ROADMAP.md (optional) → documentation
```

### New step in SKILL.md

After scaffolding is complete, before final documentation:

> **Roadmap question:** "Які ключові фічі плануєш в цьому проекті? Розіб'ємо на MVP-фази в `ROADMAP.md`"
>
> If user provides features: generate `ROADMAP.md` at project root with MVP phases, commit.
>
> If user skips ("потім", "не знаю", no answer): do not create the file, continue normally.
>
> This question is non-blocking — `init-project` completes regardless of the answer.

---

## Phase Transitions

When Phase 1 is complete (executing-plans finishes), the developer:
1. Manually checks off completed items in `docs/roadmap/<feature-slug>.md`
2. Runs `add-feature` again for Phase 2 — the skill detects the existing roadmap file and asks: "Знайшов роадмап `<slug>`. Продовжуємо Phase 2?"
3. If yes: writing-plans is scoped to Phase 2 tasks from the roadmap

Detection: at the start of `add-feature` brainstorming, check if `docs/roadmap/` contains a file matching the current feature context. If found → offer to continue from the next incomplete phase.

---

## Error Cases

- If `docs/roadmap/` directory does not exist → create it before writing the file.
- If a roadmap file for the same feature slug already exists → ask user: "Роадмап для `<slug>` вже існує. Перезаписати чи створити новий?"
- If user skips the roadmap gate → no file is created, no reference is made in the plan.
