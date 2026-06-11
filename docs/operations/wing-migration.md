# Fixing split / duplicate MemPalace wings

A *wing* is the per-project namespace MemPalace files records under. If the same
project ends up under two wing names, your memory is silently split in half:
searches hit one wing, writes land in the other.

This guide is for cleaning that up. **Most users have nothing to fix** — read
"Am I affected?" first.

---

## Am I affected?

The two known causes of split wings:

| Cause | Where it lived | Who's affected |
|-------|----------------|----------------|
| `derive-wing.sh` lowercased names and force-added a stack prefix (`phD`→`phd`, `vladyslav-skills`→`plugin-vladyslav-skills`) | shipped in the plugin, **≤ v4.2.0** | Low impact — the skills don't call `derive-wing.sh`; they reconcile the wing against your `~/.claude/CLAUDE.md` wings list. Fixed in **v4.3.0** (basename-only). |
| A personal `SessionEnd` auto-miner derived the wing as `<parent-dir>-<basename>` (e.g. `Development-myapp`) | a personal `~/.claude/scripts/` hook, **not shipped by the plugin** | Only if you set up that miner yourself. |

For the vast majority: **just update to v4.3.0** and future writes are correct:

```
/plugin update vladyslav@vladyslav-marketplace
```

You only need the rest of this doc if you actually see duplicate wings.

---

## Step 1 — Check for duplicates

In a Claude session with the MemPalace MCP server connected:

> Call `mempalace_status` and show the wings list. Are there pairs that look
> like one project under two names — case differences (`swift-Sudoku` vs
> `swift-sudoku`), or an extra prefix (`plugin-foo` / `Development-foo` vs `foo`)?

If there are no duplicates, you're done.

---

## Step 2 — Merge the duplicates

Pick whichever name is canonical (matches your directory basename and your
`CLAUDE.md` wings list) as the **destination**, and merge the other into it.

> ⚠️ **Back up first** (the merge only edits metadata, but the palace is
> irreplaceable):
> ```bash
> cp ~/.mempalace/chroma.sqlite3 ~/.mempalace/chroma.sqlite3.bak
> ```

### Option A — Prompt (simplest; good for small wings)

Paste into a session with MemPalace connected:

> Move every record from wing `<WRONG>` into wing `<RIGHT>`: call
> `mempalace_list_drawers` for `<WRONG>`, then for each `drawer_id` call
> `mempalace_update_drawer` changing `wing` to `<RIGHT>`. Show a summary.

`mempalace_update_drawer` only rewrites the `wing` metadata field — vectors and
IDs are untouched, so search keeps working.

### Option B — Script (fast; for large wings)

Run with the **same Python that runs your MemPalace MCP server**. Find it:

```bash
grep -A3 mempalace ~/.claude.json | grep -i command
# typically: ~/.mempalace-venv/bin/python
```

```python
#!/usr/bin/env python3
# merge-wing.py SRC DST  — move all records from wing SRC into wing DST
import os, sys, time
os.environ.setdefault("MEMPALACE_PALACE_PATH", os.path.expanduser("~/.mempalace"))
SRC, DST = sys.argv[1], sys.argv[2]
LOCK = os.path.join(os.environ["MEMPALACE_PALACE_PATH"], ".palace-write.lock")
w = 0
while True:
    try: os.mkdir(LOCK); break          # serialize against the SessionEnd miner
    except FileExistsError:
        time.sleep(2); w += 2
        if w > 120: sys.exit("lock timeout")
try:
    from mempalace import mcp_server as m
    col = m._get_collection()
    r = col.get(where={"wing": SRC}, include=["metadatas"])
    ids, metas = r["ids"], r["metadatas"]
    for md in metas:
        md["wing"] = DST
    for i in range(0, len(ids), 100):
        col.update(ids=ids[i:i+100], metadatas=metas[i:i+100])
    print(f"moved {len(ids)}: {SRC} -> {DST}")
finally:
    try: os.rmdir(LOCK)
    except OSError: pass
```

```bash
~/.mempalace-venv/bin/python merge-wing.py Development-myapp myapp
```

Verify afterwards with `mempalace_status` — the wrong wing should be empty (the
script leaves it with 0 records; an empty wing simply stops appearing).

---

## Step 3 (only if you have the personal miner)

If you copied a `~/.claude/scripts/mempalace-mine-session.sh` that derived the
wing from two path components, change that one line to a bare basename so future
sessions stop creating `<parent>-<project>` wings:

```bash
# before:  WING=$(echo "$CWD" | awk -F/ '{print $(NF-1) "-" $NF}' | sed 's|^-||')
WING=$(basename "$CWD")
```

Then merge any existing `<parent>-<project>` wings with Step 2.

---

## Why basename-only is canonical

The plugin's `scripts/derive-wing.sh` (v4.3.0+) emits the project directory
**basename**, case preserved, with no added stack prefix. The convention is that
the directory name *is* the wing — it already carries a prefix where one applies
(`swift-calories`, `python-tax`) and omits it where it doesn't (`brain`,
`documents`, `phD`, `vladyslav-skills`). Anything that lowercases or re-prefixes
re-introduces the split this guide exists to fix.
