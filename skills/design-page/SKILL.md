---
name: design-page
description: Use after docs/design/system.md is approved to design app screens in Pencil. Dispatches one subagent per screen, draws against the design system contract.
---

# Design Page

Orchestrates parallel subagent design of multiple app screens in Pencil. Each subagent owns one screen, reads `docs/design/system.md` as the master contract, runs an optional HIG audit (iOS), and draws its screen at a pre-assigned canvas position.

**When to run:**
- After `docs/design/system.md` is written and approved (via `design-sync` or manually)
- You have a list of screens to design and want to avoid context overflow from designing all screens in one session
- After design direction is confirmed from a mockup — this skill produces the Pencil screens

**When NOT to run:**
- `docs/design/system.md` doesn't exist yet → run `design-sync` first
- You're still deciding the design direction → finalize system.md first
- Only one small screen / single component → just design it directly without orchestration

**Type:** Architect

---

## Process

### Step 0: Verify directory

Verify working directory: `CLAUDE.md` must exist in `pwd`. Derive canonical wing name (lowercase, hyphens, platform prefix). If wrong → STOP.

### Step 1: Load master design contract

Read `docs/design/system.md` in full. This is the immutable contract for all subagents.

If it doesn't exist → **STOP**:
> "No design system found. Run `/vladyslav:design-sync` first to create `docs/design/system.md`, then come back."

Extract and hold in memory:
- §1 color palette (all tokens + hex values)
- §2 typography tokens
- §3 iconography (canonical SF Symbol / icon map)
- §4 spacing scale
- §5 canonical components
- Platform (iOS / web / Flutter / Android) — from CLAUDE.md or §0

### Step 2: Build the screen queue

Ask the user (one message):
> "Which screens should I design? List them with a one-line scope each, or say 'derive from docs' and I'll read the product docs.
>
> Example:
> - HomeView: difficulty tiles grid + daily challenge hero card
> - GameView: 9×9 sudoku grid + number pad + timer + error counter
> - RecordsView: leaderboard list with 6 difficulty tabs"

If user says **"derive from docs"** → read `docs/product/start-project.md` (§ navigation / screens) and `docs/plans/tasks.md` to build the list automatically. Present it for a quick confirm (y/n only — not a full approval gate).

Build screen queue: `[{ name, scope, dependencies: [] }]`

Classify dependencies:
- Default: all screens are **independent** (parallel)
- Mark as dependent only if the user explicitly notes it (e.g. "SettingsView appears as a sheet from HomeView") OR if one screen reuses a component being defined in another

### Step 3: Open Pencil and sync tokens

1. Call `mcp__pencil__get_editor_state`. If no .pen file is active:
   - Check for `*.pen` in `docs/design/` or project root
   - If found → `mcp__pencil__open_document(path)`
   - If not found → `mcp__pencil__open_document("new")` to create `docs/design/<project-name>.pen`

2. Call `mcp__pencil__get_variables`. Compare with system.md §1 tokens:
   - If Pencil variables match system.md → proceed
   - If missing or mismatched → call `mcp__pencil__set_variables` to sync all tokens from §1 before dispatching subagents

   **This is the only token sync point.** All subagents inherit these variables — they must NOT call `set_variables` themselves (race condition risk).

### Step 4: Pre-assign canvas coordinates

**Critical for parallel safety:** Pencil canvas is shared. If subagents independently call `find_empty_space_on_canvas`, they may receive the same coordinates and overlap.

Pre-assign regions from the orchestrator:

1. Call `mcp__pencil__get_guidelines` for platform-appropriate screen dimensions:
   - iOS: 393 × 852 pt (iPhone 16 Pro)
   - Web: 1440 × 900
   - Flutter/Android: 360 × 800

2. Call `mcp__pencil__find_empty_space_on_canvas` once per screen in sequence, reserving a slot for each:
   - Margin between screens: 80pt horizontal, 120pt vertical
   - Arrange in a grid: up to 3 per row

3. Record the assigned `{ x, y }` for each screen. Each subagent receives its coordinates and **must not** look for empty space itself.

### Step 5: Dispatch parallel subagents

For each **independent batch** (screens with no dependencies between them), dispatch Agent tool calls in a **single message** (true parallel execution):

```
For each screen in batch:
  Agent(
    description: "Design <screen-name> screen in Pencil",
    subagent_type: "general-purpose",
    model: "opus",
    prompt: <see subagent prompt template below>
  )
```

**Subagent prompt template:**

```
You are designing the <screen-name> screen for <project-name> in Pencil.

MASTER CONTRACT (docs/design/system.md summary):
<paste full system.md §1–§5 content here>

YOUR SCREEN:
Name: <screen-name>
Scope: <scope>
Canvas position: x=<x>, y=<y>
Platform: <iOS / web / Flutter>
Pencil file: <path>

STEPS:
1. Call mcp__pencil__open_document("<path>") to open the .pen file.
2. [iOS only] HIG audit before drawing. Read `~/.vladyslav-skills/skills/swiftui-pro/references/ios-hig.md`
   for the full checklist. At minimum verify for this screen:

   **CRITICAL (block — do NOT draw the violation):**
   - Tap targets ≥ 44×44pt for every interactive element
   - Safe areas respected (no content under Dynamic Island / home indicator)
   - Tab bar at bottom for top-level navigation (not hamburger/drawer)
   - Every interactive element has a VoiceOver label

   **HIGH (flag in report, draw with placeholder if no token exists):**
   - All text uses Dynamic Type semantic styles from §2 (no hardcoded sizes)
   - All colors from §1 asset catalog tokens — no raw hex
   - WCAG AA contrast (4.5:1 body, 3:1 large text / UI)
   - Primary action placed in thumb zone (bottom)
   - Layout adapts SE (375pt) → Pro Max (430pt)
   - Spacing follows 8pt grid (4pt for fine adjustments)

   Flag each violation found: include in your report as `HIG: <rule> — <element>`.
   **Do NOT draw violations.** Draw a placeholder labeled `[HIG BLOCKED: <rule>]` instead.
3. Call mcp__pencil__get_style_guide_tags, then mcp__pencil__get_style_guide to pick a style preset matching the design system (Modern Pink / Apple HIG).
4. Call mcp__pencil__batch_design to draw the screen at x=<x>, y=<y>:
   - Use ONLY tokens defined in the master contract (§1 colors, §2 typography, §3 icons, §4 spacing, §5 components).
   - If you need a token that doesn't exist in system.md → STOP immediately. Do not invent it. Write a note: "NEEDS TOKEN: <name> for <purpose>" and return without drawing that element.
5. After drawing, call mcp__pencil__snapshot_layout to verify the layout rendered correctly.
6. Write docs/design/pages/<screen-name>.md with:
   - Which canonical components you used (§5 references)
   - Any layout decisions not covered by system.md
   - Any "NEEDS TOKEN" items found
   - HIG issues flagged (if any)
   - Canvas coordinates used: x=<x>, y=<y>

Return a brief summary: screen name, status (complete / needs-token / hig-violation), list of decisions.
```

### Step 6: Process sequential screens

After all parallel batches complete, process screens with dependencies **one at a time**. Use the same subagent prompt but pass coordinates from a new `find_empty_space_on_canvas` call (parallel batch has settled, safe to search again).

### Step 7: Collect results and handle blockers

Read all `docs/design/pages/<screen-name>.md` files created by subagents.

**If any subagent returned "NEEDS TOKEN":** aggregate all token requests and present to user as a single list:
> "Subagents found <N> missing tokens. For each:
> (a) Add to system.md §X now → I'll update the file and resume
> (b) Skip for now → draw that element as a placeholder

Resolve all tokens first, then re-run only the affected screen(s) (not the full batch).

**If any subagent reported an HIG violation:** present as a list. These are warnings, not blockers — the screen was drawn without the violation. User decides whether to address now or log in system.md §8 drift log.

### Step 8: Architect report

```
✓ Architect Report — Design Page

Project: <name>
Platform: <platform>
Screens designed: <N>

Results:
  ✅ HomeView      — complete, x=0, y=0
  ✅ GameView      — complete, x=473, y=0
  ✅ RecordsView   — complete, x=946, y=0
  ⚠  SettingsView  — 1 missing token: surface/modalSheet
  ✅ DailyView     — complete, x=0, y=972

Missing tokens: <list or "none">
HIG violations flagged: <list or "none">
Page decisions: docs/design/pages/

Next steps:
- `/vladyslav:design-page` — design more screens (if applicable)
- `/vladyslav:add-feature` — implement features tied to designed screens
- `/vladyslav:write-test-docs` — generate test plan including design QA
```

---

## Notes

- **Parallel safety:** Canvas coordinates are pre-assigned by the orchestrator (Step 4). Subagents MUST draw at their assigned position and MUST NOT call `find_empty_space_on_canvas` — this is how we avoid overlap in parallel execution.
- **Token sync is orchestrator-only:** Only the orchestrator calls `set_variables` (Step 3). Subagents read variables but never write them.
- **Full-auto boundary:** The only hard stops are (1) missing design tokens — these require a product decision, (2) Pencil API errors. Everything else runs without approval.
- **Context budget:** Each subagent gets only `system.md §1–§5` + its screen scope as context. It does NOT get the full conversation history. This is intentional — it keeps each subagent's context small and prevents cross-screen contamination.
- **Re-running one screen:** Pass `--screen <ScreenName>` in your request and this skill will skip Step 2 (use existing queue) and process only that screen.
- **Inspired by:** ui-ux-pro-max-skill's `--persist` pattern (MASTER.md + per-page overrides). `docs/design/system.md` = MASTER, `docs/design/pages/` = per-page decisions.
