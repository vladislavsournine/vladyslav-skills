# Present summary (heavy-engineer skills)

This block is the orchestrator-side counterpart to `yaml-return.md`. After the Sonnet subagent returns, the orchestrator parses the YAML block and renders one of four human-facing summaries based on `status`. Composed into the body of each heavy-engineer SKILL.md as the post-dispatch step (typically Step 2 or Step 3).

---

## Step: Present summary

Parse the YAML block in the subagent's response. Use `scripts/parse-yaml-return.sh` (pipe the response into it) — it returns JSON `{ok, yaml, reason}`. Treat as **parse failure** when `ok: false`, OR when the parsed YAML lacks a `status:` field, OR when YAML is malformed.

**If parse fails** → print the full subagent output, run `git status --short`, tell the user:

```
✗ Subagent returned unstructured response.
  Files on disk: <git status --short>
  Review manually.
```

**If parse succeeds**, render based on `status`:

### `status: success`

```
✓ Engineer summary (<skill-name>)
  Wrote: <files_written paths joined>
  Skipped: <files_skipped, if any>
  Warnings: <warnings, if any>
  Files unstaged. Review before commit.
  Next: <next_step_suggestion>
```

### `status: partial`

Same as `success`, plus a final line:

```
  Note: <files_skipped> were not created. See warnings.
```

### `status: scope_expansion_required`

```
⚠ Engineer halted (<skill-name>)
  Subagent wanted to modify <path> (outside allowlist).
  Reason: <reason>

  Options:
    1. Approve — re-dispatch with extended allowlist
    2. Skip — leave file untouched
    3. Abort
```

Wait for user choice. Decision matrix:

- **(1) Approve** → re-dispatch the subagent with the allowlist extended by `scope_expansion_required[0].path`. Reuse the pre-flight outputs already in memory — do NOT re-run AskUserQuestion. After re-dispatch, parse the new YAML block and render again.
- **(2) Skip** → record the skipped path in your local notes, render the rest of the summary as if `status: partial`, do not re-dispatch.
- **(3) Abort** → exit cleanly. Do not run any further steps.

### `status: error`

```
✗ Engineer failed (<skill-name>)
  Error: <error message from summary field>
```

Do not retry automatically. Surface the error and stop.
