# System Architecture

TBD

## Continuity Primitive

`vladyslav:stash` / `vladyslav:unstash` (added in 1.7.0) provide explicit pause-and-resume across sessions. Persistence is in MemPalace as drawers with `room="stash"`; drawer `content` is YAML with an embedded `created_at`. Semantics are Latest-wins: the newest drawer per wing IS the active stash (drawer API is add-only — immutability drove this choice over a mutable `active` flag). Integration with other skills happens via two global rules in `~/.claude/CLAUDE.md` (Scope Sentinel + Active Stash Notification) and via auto-stash checkpoints inside `vladyslav:add-feature` and `vladyslav:fix-bug`.
