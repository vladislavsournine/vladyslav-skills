# Stack: "other" (custom user-defined)

This fragment is composed into the `init-project` subagent prompt when the user selects `other` as a backend or frontend/mobile stack. It is parameterised — the pre-flight Q&A collected three fields per "other" stack:

- `label` — free-text description (e.g. `"Rust backend"`, `"React Native frontend"`)
- `dir` — directory name to create at the project root (e.g. `rust/`, `rn/`)
- `gitignore_entries` — comma-separated list of `.gitignore` patterns the user wants for this stack

## Directory

Create:

```
<dir>/
```

Add a `<dir>/.gitkeep` so the empty directory is committed.

## .gitignore additions

Append to `.gitignore` each entry from `gitignore_entries`, one per line. Skip empty entries. Trim surrounding whitespace.

## Files

None — `init-project` does not scaffold language- or framework-specific files for "other" stacks. The user is responsible for initialising their stack inside `<dir>/` after `init-project` finishes.

## Documentation hint (cross-stack section)

When generating `CLAUDE.md` (Step 6 in the orchestrator), include a `Stack` line for each "other" stack:

```
- <label> (in <dir>/)
```
