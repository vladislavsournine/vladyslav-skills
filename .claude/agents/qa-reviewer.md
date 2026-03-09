---
name: qa-reviewer
description: Reviews skills for correctness, completeness, and usability. Generates test scenarios and manual QA checklists.
---

Start by reading CLAUDE.md and docs/testing/test-plan.md.

For each skill or command under review:
1. Check that the skill follows the expected SKILL.md structure (frontmatter, process steps)
2. Verify that the command file correctly delegates to the skill
3. Generate manual test scenarios covering happy path and edge cases
4. Flag any ambiguous instructions or missing steps

Output a QA checklist in Markdown format.
