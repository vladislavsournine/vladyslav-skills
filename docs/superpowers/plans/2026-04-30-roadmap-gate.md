# Roadmap Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional phased roadmap generation step to `add-feature` and `init-project` skills so large features and new projects can produce a tracked `docs/roadmap/<slug>.md` or `ROADMAP.md` file before implementation begins.

**Architecture:** Two SKILL.md files are modified directly — no code, no tests (skill files are markdown instructions). Each modification inserts one new step at a precise location in the existing step sequence. The roadmap file format is defined in the design spec at `docs/superpowers/specs/2026-04-30-roadmap-gate-design.md`.

**Tech Stack:** Markdown skill files only. No build system. Verification is manual review of modified file content.

---

## File Map

| Action | File |
|--------|------|
| Modify | `skills/add-feature/SKILL.md` |
| Modify | `skills/init-project/SKILL.md` |
| Reference (read-only) | `docs/superpowers/specs/2026-04-30-roadmap-gate-design.md` |

---

### Task 1: Add roadmap gate to `add-feature` (Step 4.7 + existing roadmap detection)

**Files:**
- Modify: `skills/add-feature/SKILL.md`

Two insertions in this task:

**Insertion A** — existing roadmap detection at start of Step 4 (brainstorming).
**Insertion B** — new Step 4.7 (roadmap gate) between Step 4.5 and Step 5.

- [ ] **Step 1: Read current `add-feature` SKILL.md**

  Open `skills/add-feature/SKILL.md` and locate:
  - The line `### Step 4: Design the feature` (line ~83)
  - The block `### Step 4.5: Define contract` (line ~97)
  - The block `### Step 5: Create implementation plan` (line ~125)

- [ ] **Step 2: Insert existing-roadmap detection into Step 4**

  In `### Step 4: Design the feature`, add the following block at the very top of that section, before "**Manual mode:**":

  ```markdown
  **Existing roadmap check (both modes):**
  Before starting brainstorming, check if `docs/roadmap/` contains any `.md` file whose slug matches the feature name from Step 2 (compare lowercased, hyphens-normalized). If a match is found, ask:
  > "Знайшов роадмап `<slug>`. Продовжуємо з наступної незакінченої фази?"
  - **Yes** → skip brainstorming and contract (Steps 4, 4.5). Load the roadmap file, identify the first phase with unchecked items, pass those items as the scope to writing-plans (Step 5). Record that this run is a phase continuation.
  - **No** → proceed with normal brainstorming as if no roadmap exists.
  ```

- [ ] **Step 3: Insert new Step 4.7 between Step 4.5 and Step 5**

  After the closing line of the `### Step 4.5` block (the `Auto-stash checkpoint: contract-approved` section ends around line 123), insert this new step:

  ```markdown
  ### Step 4.7: Roadmap gate

  **Applies to:** both modes. Runs after contract approval, before writing-plans.

  Assess whether the feature is multi-phase using **any one** of:
  - Design from Step 4 has ≥3 distinct components/subsystems
  - Design from Step 4 implies ≥5 major tasks
  - User language in Step 2 signals phasing: "поетапно", "спочатку X потім Y", "фази", "поступово", "gradually", "phases", "step by step"

  If any condition is true, ask:
  > "Ця фіча виглядає багатофазно — є сенс розбити на фази з роадмапом перед тим як писати детальний план. Зробити?"

  **If yes:**
  1. Create `docs/roadmap/` directory if it does not exist.
  2. If a file `docs/roadmap/<feature-slug>.md` already exists, ask: "Роадмап для `<slug>` вже існує. Перезаписати чи створити новий?"
  3. Generate `docs/roadmap/<feature-slug>.md` using this format:

  ```markdown
  # Roadmap: <Feature Name>

  > Created: YYYY-MM-DD

  ## Phase 1: <Name>
  **Done when:** <one sentence criteria>

  - [ ] Task 1
  - [ ] Task 2

  ## Phase 2: <Name>
  **Done when:** <one sentence criteria>

  - [ ] Task 1
  - [ ] Task 2
  ```

  4. Commit: `git add docs/roadmap/<feature-slug>.md && git commit -m "docs: add roadmap for <feature-slug>"`
  5. Pass **only Phase 1 tasks** as the scope to writing-plans in Step 5.

  **`<feature-slug>` derivation:** feature name from Step 2, lowercased, spaces replaced with hyphens. Example: "User Authentication" → `user-authentication`.

  **If no (or gate did not fire):**
  Proceed to Step 5 with the full feature scope as before. No file is created.
  ```

- [ ] **Step 4: Update Step 5 to mention phase scope**

  In `### Step 5: Create implementation plan`, find the sentence that begins "Invoke the `superpowers:writing-plans` skill" (auto mode) and append:

  ```
  If a roadmap was created in Step 4.7, pass the Phase 1 task list as the scope constraint — writing-plans must produce a plan that implements Phase 1 only, not the full feature.
  ```

- [ ] **Step 5: Review the modified `add-feature` SKILL.md**

  Read the file and verify:
  - Step 4 now starts with "Existing roadmap check"
  - Step 4.7 appears between Step 4.5 and Step 5
  - Step 5 mentions phase scope
  - Step numbering is coherent (4 → 4.5 → 4.7 → 5 → 6...)
  - No duplicate headings

- [ ] **Step 6: Commit**

  ```bash
  git add skills/add-feature/SKILL.md
  git commit -m "feat(add-feature): add roadmap gate (Step 4.7) and existing roadmap detection"
  ```

---

### Task 2: Add roadmap question to `init-project` (Step 9.5)

**Files:**
- Modify: `skills/init-project/SKILL.md`

One insertion: new Step 9.5 between Step 9 (doc stubs) and Step 10 (git init).

- [ ] **Step 1: Read current `init-project` SKILL.md**

  Open `skills/init-project/SKILL.md` and locate:
  - The line `### Step 9: Create doc stubs` (line ~319)
  - The line `### Step 10: Git init and commit` (line ~343)

- [ ] **Step 2: Insert new Step 9.5 between Step 9 and Step 10**

  After the closing content of Step 9 (the last entry of the doc stubs list + the `> docs/operations/docker.md` note), insert:

  ```markdown
  ### Step 9.5: Roadmap question (optional)

  After creating doc stubs, ask the user:
  > "Які ключові фічі плануєш в цьому проекті? Розіб'ємо на MVP-фази в `ROADMAP.md` (Enter щоб пропустити)"

  **If user provides features:**
  Generate `ROADMAP.md` at the project root using this format:

  ```markdown
  # Roadmap: <Project Name>

  > Created: YYYY-MM-DD

  ## Phase 1: MVP
  **Done when:** <one sentence criteria>

  - [ ] <Feature from user>
  - [ ] <Feature from user>

  ## Phase 2: Post-MVP
  **Done when:** <one sentence criteria>

  - [ ] <Feature from user>
  ```

  Distribute the user's features across phases based on their description (MVP = core functionality, Post-MVP = enhancements). Ask if unclear.

  **If user skips (empty answer, "потім", "не знаю"):**
  Do not create the file. Continue to Step 10 immediately.

  This step is **non-blocking** — `init-project` completes regardless of the answer.
  ```

- [ ] **Step 3: Update Step 10 to include ROADMAP.md in git add**

  In `### Step 10: Git init and commit`, the commit command is:
  ```bash
  git add -A
  ```
  This already covers `ROADMAP.md` if it was created. No change needed — verify `git add -A` is still present.

- [ ] **Step 4: Update Step 11 finish report**

  In `### Step 11: Finish`, find the `✓ Engineer report:` block. After the `Design system:` line, add:

  ```
  - Roadmap: <ROADMAP.md written with N phases | skipped>
  ```

- [ ] **Step 5: Review the modified `init-project` SKILL.md**

  Read the file and verify:
  - Step 9.5 appears between Step 9 and Step 10
  - Step numbering is coherent (9 → 9.5 → 10 → 11)
  - Step 11 report includes roadmap line
  - No duplicate headings

- [ ] **Step 6: Commit**

  ```bash
  git add skills/init-project/SKILL.md
  git commit -m "feat(init-project): add roadmap question (Step 9.5)"
  ```

---

### Task 3: Sync commands and bump version

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Bump version in plugin.json**

  Open `.claude-plugin/plugin.json`. Change:
  ```json
  "version": "1.7.0"
  ```
  to:
  ```json
  "version": "1.8.0"
  ```

- [ ] **Step 2: Commit**

  ```bash
  git add .claude-plugin/plugin.json
  git commit -m "chore: bump version to 1.8.0 (roadmap gate)"
  ```

---

## Self-Review

**Spec coverage:**
- ✅ Trigger logic (size-gate) → Task 1, Step 3 (Insertion B)
- ✅ Roadmap doc structure → Task 1, Step 3; Task 2, Step 2
- ✅ `add-feature` changes → Task 1
- ✅ `init-project` changes → Task 2
- ✅ Phase transitions → Task 1, Step 2 (Insertion A)
- ✅ Error cases (dir missing, slug conflict) → Task 1, Step 3

**Placeholder scan:** No TBD or TODO in task steps. All code blocks are complete.

**Type consistency:** No code types — markdown only. Section names used consistently: "Step 4.7", "Step 9.5" throughout.
