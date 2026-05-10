# YAML return contract (heavy-engineer skills)

This is the structured contract that every heavy-engineer skill's Sonnet subagent must end its response with. Composed verbatim into each subagent prompt.

The orchestrator extracts the LAST fenced ` ```yaml ` block via `scripts/parse-yaml-return.sh` and renders the human-facing summary based on `status`.

---

End your response with EXACTLY one YAML block:

````
```yaml
status: success | partial | scope_expansion_required | error
files_written:
  - path: <path>
    action: created | modified | replaced
files_skipped:
  - <paths that were skipped, if any>
warnings:
  - <non-blocking issue, if any>
scope_expansion_required:
  - path: <if applicable>
    reason: <if applicable>
next_step_suggestion: <slash-command for the next skill the user should run>
summary: |
  <1-3 sentence human-readable description of what changed and why>
```
````

## Status semantics

- `success` — every file in the allowlist that was supposed to be created or modified was, no warnings worth surfacing.
- `partial` — some files were skipped (e.g. user-edited stubs preserved). `files_skipped` lists them; `summary` explains.
- `scope_expansion_required` — a file outside the allowlist is needed. The subagent did NOT write it. `scope_expansion_required[].path` and `.reason` describe the request. The orchestrator will ask the user whether to approve the expansion.
- `error` — a fatal blocker (missing plugin asset, failed external command, etc.). `summary` MUST contain the error message verbatim.

## Field rules

- `files_written` is empty `[]` only when `status: error` or `status: scope_expansion_required`. Otherwise list every path that was created or modified.
- `files_skipped` lists paths the subagent intentionally did NOT write (e.g. existing user-authored stubs). Empty list `[]` if nothing was skipped.
- `warnings` is for non-blocking observations the user should see (e.g. "swiftui-pro suggests updating deployment target"). Empty list if none.
- `next_step_suggestion` should be a literal slash-command string that the user can type next. Pick the most natural follow-up for this skill.
- `summary` is rendered to the user verbatim — write it as a 1-3 sentence narrative, not a bulleted list.
