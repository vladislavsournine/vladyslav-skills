---
name: design-sync
description: Use when an existing UI project has no docs/design/system.md yet OR when design has drifted (multiple colors for "primary", inconsistent spacing, duplicate icons) - scans the actual codebase, extracts canonical tokens, reports drift, writes docs/design/system.md, and seeds MemPalace with design decisions so future sessions automatically reuse the canon instead of inventing
---

# Design Sync

## Overview

Scans an existing UI codebase, extracts the **actual** design tokens being used (colors, typography, icons, spacing, components), detects drift (same "thing" defined multiple ways), presents findings to the user for canonization, and writes `docs/design/system.md` + MemPalace decision records so future sessions reuse the canon instead of inventing new tokens.

**When to run:**
- First time you realize new screens don't look like old screens (design drift is already happening)
- After `init-project` on a UI project that already has a few screens
- Before starting a major design refresh (canonize what exists → plan what changes)
- Periodically on active projects to catch drift early

**When NOT to run:**
- Pure backend / CLI project — no UI, nothing to sync
- Brand-new project with zero screens — the template from `init-project` is enough; run this after 2-3 screens exist

**Type:** Architect (Opus)

## Process

### Step 0: Verify model, scope, and working directory

Check current model. If not Opus, switch: `/model opus`.

**Verify working directory and canonical wing name:**
1. Check that `CLAUDE.md` exists in `pwd`. If not → STOP: "No CLAUDE.md found. Are you in the right project directory?"
2. Derive canonical wing name: `basename $(pwd)` → lowercase → hyphens → platform prefix (e.g. `swift-sudoku`, not `swift-Sudoku`).
3. Run `mempalace_list_wings`. If a wrong-case duplicate exists → warn the user before proceeding. Always write to the lowercase canonical wing.

Verify this is a UI project. Check for at least one:
- `swift/` directory with `.swift` files OR `*.xcodeproj` / `Package.swift` with UI targets
- `flutter/` directory with `pubspec.yaml`
- `kotlin/` directory with Android app module
- `frontend/` / `web/` directory with `package.json` + React/Svelte/Vue/etc.
- Any `Assets.xcassets`, `tailwind.config.*`, `ThemeData` usage, `colors.xml`

If none → stop and tell the user: "No UI code detected. `design-sync` only makes sense for UI projects. If this project has a UI layer elsewhere, tell me where to look."

### Step 1: Read existing state

Read in parallel:
- `CLAUDE.md` — project conventions
- `docs/design/system.md` if it exists — the current (possibly empty) canon
- `docs/architecture/system.md` — understand the app architecture
- `docs/product/start-project.md` — brand direction / audience / platform

If `docs/design/system.md` already exists and is **not just the template**, ask the user:
> "Existing design system found at `docs/design/system.md`. Options:
> (1) **Update** — merge what I find in code with the existing doc (recommended if you've been maintaining it)
> (2) **Rebuild from code** — ignore the existing doc, re-scan everything (recommended if the doc is stale)
> (3) **Abort** — don't touch it"

Record the choice. Default to (1) if empty/template.

### Step 2: MemPalace — prior design decisions (hypothesis, NOT truth)

Search the project wing:
```
mempalace_search wing=<project> "design"
mempalace_search wing=<project> "color"
mempalace_search wing=<project> "palette"
mempalace_search wing=<project> "icon"
mempalace_search wing=<project> "typography"
mempalace_search wing=<project> "font"
mempalace_search wing=<project> "spacing"
mempalace_search wing=<project> "component"
```

**Path validation first:** For any result containing absolute file paths, verify each path exists on disk. If a path does not exist → mark the drawer `[STALE]` and exclude it from the findings list entirely.

**Present findings as hypothesis — never apply silently:**

After gathering results, for each significant design decision found (color direction, icon library, primary accent, typography system), present it to the user and ask explicitly:

> "MemPalace has this from `<date>`: **`<finding>`**
> Is this still the design direction?
> (y) Yes — use as a constraint in this session
> (n) No — ignore it, the code / mockup is the source of truth
> (?) Unsure — I'll verify it against current code before deciding"

Wait for confirmation before including any MemPalace finding in the design decisions list.

**Why this rule exists:** On 2026-04-10, design-sync silently applied a stale Indigo direction from MemPalace, overriding the user's actual Modern Pink direction. The result: a full design system document in the wrong color direction that had to be manually corrected. One wrong memory silently corrupted an hour of work.

**Only after user confirmation**, compile the validated list into "known design decisions". If any conflict with what's in the code, that's a sync problem — flag for Step 6.

### Step 3: Extract color tokens

**iOS (Swift / SwiftUI):**
1. Read `Assets.xcassets` — for every `.colorset`, extract the color name and the hex from `Contents.json` (both `any` and `dark` appearance if present)
2. Grep Swift source for `Color(...)`, `UIColor(...)`, `.foregroundColor(...)`, `.background(...)`, `.tint(...)`
3. Separate into:
   - **Named tokens** — `Color("accent/primary")`, `Color.primary` (already canonical)
   - **Raw literals** — `Color(red: 0.3, green: 0.6, blue: 0.9)`, `Color(hex: "#4A90E2")`, `Color(.systemRed)` (DRIFT candidates)
4. For raw literals: count frequency, group near-identical colors (ΔE < 5 in LAB space — if you can't compute LAB, use hex distance as rough proxy)

**Web (Tailwind / CSS):**
1. Read `tailwind.config.*` — extract `theme.colors` and `theme.extend.colors`
2. Read any `*.css` / `*.scss` for CSS variables (`--color-*`)
3. Grep source for `className="...bg-[#...] text-[#...]..."` (arbitrary values — DRIFT) and raw hex in JSX style props

**Flutter:**
1. Read `ThemeData` definitions in `main.dart` / `theme.dart` / similar
2. Grep for `Color(0xFF...)`, `Colors.xxx` not wrapped in theme extension

**Kotlin (Android):**
1. Read `res/values/colors.xml` and `res/values-night/colors.xml`
2. Grep for hex literals in Compose / XML layouts

For each platform, produce a list of:
- **Canonical tokens** (names + values, as they exist in the asset catalog / theme file)
- **Raw usages** (file:line, hex, count) — candidates for token extraction
- **Drift candidates** (multiple near-identical colors with different names/definitions)

### Step 4: Extract typography

**iOS:** grep for `.font(...)` — separate into `.font(.body)` / `.font(.headline)` (canonical, uses Dynamic Type) vs `.font(.system(size: N, weight: W))` (raw, DRIFT).

**Web:** extract `fontFamily`, `fontSize`, `fontWeight`, `lineHeight` from tailwind config + any `text-[...]` arbitrary classes.

**Flutter:** extract `TextStyle` definitions, find inline `TextStyle(fontSize: ...)` usages.

**Kotlin:** extract `Typography` in Material 3 theme, find raw `TextStyle(...)` in Compose.

Compile into a table: token (or "unnamed"), size, weight, line height, usage count.

### Step 5: Extract icons, spacing, components

**Icons:**
- iOS: grep for `Image(systemName: "...")` — count unique names, flag if the same concept has two names (e.g., `gear` and `gearshape` both used for settings)
- Web: `<Icon name="..." />` or specific icon component imports
- Flutter: `Icons.xxx` usage
- Android: `@drawable/ic_*` references

**Spacing:**
- iOS: grep for `.padding(N)` and `.padding(.horizontal/.vertical, N)` — list frequencies of each N
- Web: `p-N`, `m-N`, `gap-N` from Tailwind + arbitrary values
- Flutter: `EdgeInsets.all(N)`, `SizedBox(height: N)`
- Android: `@dimen/...` refs + raw `dp` values

**Components:**
- Grep for `struct XxxView: View` / `function XxxComponent(...)` / `class Xxx extends StatelessWidget` / etc.
- List the top-level component declarations — these are candidates for canonization in section 5 of the design system doc

### Step 6: Drift analysis

Compile a drift report with these categories:

1. **Multiple tokens for the same role** — e.g., 5 places use `Color("accent")`, 3 places use `Color(hex: "#4A90E2")` (same value, different form). Canonicalize → replace all raw with the named one.
2. **Near-identical colors with different names** — e.g., `Color("brandBlue")` = `#4A90E2` and `Color("primaryBlue")` = `#4A91E3`. Ask user which is the canon, delete the other.
3. **Spacing values that don't match the 4pt grid** — e.g., `.padding(13)` — flag as bug.
4. **Same icon concept, different symbols** — e.g., `gear` and `gearshape` both used. Pick one.
5. **Raw typography** — any `.font(.system(size: N, weight: W))` that should be a semantic token.
6. **MemPalace conflicts** — if MemPalace has a design decision that contradicts the code (e.g., "we decided on accent = #FF6B35" but code uses #4A90E2), flag as BIG RED FLAG.

Present the drift report to the user as:

```
━━━ Drift report for <project> ━━━━━━━━━━━━━━━━

Colors:
  ✓ Canonical (<N>): accent/primary, background/primary, label/primary, ...
  ⚠ Raw literals (<N>): Color(hex: "#4A90E2") × 7 places, Color(red: 0.2...) × 3 places
  ⚠ Near-duplicates: "brandBlue" (#4A90E2) vs "primaryBlue" (#4A91E3) — same visual
  ✗ MemPalace conflict: memory says accent = #FF6B35, code uses #4A90E2

Typography:
  ✓ Canonical (<N>): 24 uses of .font(.body), 12 uses of .font(.headline)
  ⚠ Raw sizes (<N>): 3 places with .font(.system(size: 17, weight: .semibold)) — equals .headline

Icons:
  ✓ Canonical (<N>): xmark (close) × 5, chevron.left (back) × 8, gearshape (settings) × 2
  ⚠ Duplicated concept: "gear" × 1 AND "gearshape" × 2 — both for settings

Spacing:
  ✓ 4pt-aligned: 8, 16, 24 all present
  ⚠ Off-grid: .padding(13) × 2, .padding(7) × 1

Components (top 10 by usage):
  PrimaryButton, Card, ListRow, HeaderView, ...
```

### Step 7: User canonization

Present the drift report and ask the user to make decisions:

1. For each near-duplicate → "Which is canon? A or B or neither (propose new)?"
2. For MemPalace conflicts → "Which wins: memory or code? (if memory wins, we'll refactor code; if code wins, we'll update memory)"
3. For off-grid spacing → "Auto-fix to nearest 4pt multiple, or keep as-is?"
4. For duplicated icons → "Pick one"
5. For unnamed top-components → "Should this become a canonical reusable component in the design system doc? (yes = documented + extracted for reuse, no = project-specific one-off)"

Use the AskUserQuestion tool for each decision point (batch them if possible). Do NOT make these calls silently — these are product decisions that belong to the user.

### Step 8: Write docs/design/system.md

Based on Step 1 choice (update vs rebuild):

**Rebuild path:**
1. Read `~/.vladyslav-skills/templates/DesignSystem.md` as base
2. Fill in discovered + canonized tokens
3. Preserve the structure and comments (they're instructions to future AI sessions)
4. Add **Drift log** entries (section 8) for every issue from Step 6 with status `resolved` (if user canonized in Step 7) or `pending` (if user chose to auto-fix later)
5. Write the final file

**Update path:**
1. Read existing `docs/design/system.md`
2. For each section, merge: keep user-written content, append new tokens found in code that aren't documented, flag anything documented that's no longer in code as `[STALE]`
3. Do NOT silently delete anything the user wrote manually
4. Add drift log entries for new issues

### Step 9: Seed MemPalace with design decisions

Write these decision records to the project wing via `mempalace_add_drawer` (check duplicates first with `mempalace_check_duplicate`):

- **room:** `decision`
- **added_by:** `design-sync`
- Records to write:
  1. `[WHAT] Design system canonized, [PALETTE] <list of canonical color tokens with values>, [SOURCE] docs/design/system.md §1, [DATE] <today>`
  2. `[WHAT] Typography tokens, [TOKENS] <list with sizes>, [SOURCE] docs/design/system.md §2, [DATE] <today>`
  3. `[WHAT] Icon set, [SOURCE_LIBRARY] <SF Symbols / Material / ...>, [CANONICAL_ICONS] <list of role→symbol>, [DATE] <today>`
  4. `[WHAT] Spacing scale, [SCALE] 4/8/16/24/32/48, [DATE] <today>`
  5. `[WHAT] Canonical components, [LIST] <list of top-level reusable components>, [SOURCE] docs/design/system.md §5, [DATE] <today>`

Why separate records: when a future session asks "what colors do we use?", `mempalace_search wing=<project> "palette"` hits one record, not five. More searchable.

### Step 10: Optional auto-fix

Ask the user:
> "Drift report has <N> auto-fixable issues (off-grid spacing, raw hex that maps to a canonical token, duplicate icons). Want me to apply them now in a worktree?
> - yes → I'll open a worktree, make the replacements, run tests, show you the diff
> - later → I'll leave them in the drift log with `pending` status, you can run `design-sync --apply-fixes` later
> - no → skip"

If yes:
1. Create worktree via `superpowers:using-git-worktrees` (or `git checkout -b design/canonize-<date>` if not a git project)
2. Apply replacements — strictly within scope: only token replacements, no structural refactoring
3. Run project tests if available
4. Show diff, ask for approval
5. Do NOT merge automatically — leave on the branch for user review

### Step 11: Architect report

```
✓ Architect report — Design Sync

Project: <name>
Platform: <stack>
Mode: <rebuild | update>

Tokens extracted:
- Colors: <N> canonical, <M> drift items (resolved: <K>, pending: <L>)
- Typography: <N> canonical, <M> drift
- Icons: <N> canonical, <M> drift
- Spacing: <N> canonical, <M> drift
- Components: <N> canonized for reuse

Conflicts with MemPalace: <count> (resolved: all | remaining: N)

Files written:
- docs/design/system.md (<rebuild | update>)
- <N> MemPalace decision records in wing <project>

Drift auto-fix: <applied in branch design/canonize-<date> | pending | skipped>

━━━ Next ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Review docs/design/system.md — check §1 palette, §3 icons, §5 components
2. Fill in brand/product-specific values where template has placeholders
3. If auto-fix branch was created: review the diff and merge if clean
4. Going forward: every UI task now reads docs/design/system.md FIRST
   (enforced by global rule in ~/.claude/CLAUDE.md §"Design System Discipline")
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Notes

- **This skill does not add UI features.** It only canonizes what already exists. For new screens, use `/vladyslav:add-feature` after `design-sync` has been run.
- **The drift log is load-bearing.** It's the memory of what was inconsistent at a point in time — future sessions can see the history and know that "we fixed 12 colors on 2026-04-10".
- **User decisions are not optional.** Don't silently pick a canonical token when there's a conflict. This is a product decision, not a technical one.
- **MemPalace conflicts are the most dangerous finding.** They mean the knowledge base and the code diverged at some point. Always surface them loudly and force a decision.
- **Re-run this skill periodically.** Design drift creeps in slowly. Running `design-sync` every few sprints catches it before it becomes expensive to fix.
