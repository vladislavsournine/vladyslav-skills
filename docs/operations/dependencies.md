# Dependencies & tooling setup

How to install and update the external tools the skills rely on. Two tools matter:

- **MemPalace** — *required* by the 9 memory-using skills (cross-session memory).
- **Graphify** — *optional* companion (code knowledge graph). Not wired into any skill; install only if you want it ad-hoc.

---

## MemPalace (required)

Long-term cross-session memory. Python package `mempalace` (repo: [MemPalace/mempalace](https://github.com/MemPalace/mempalace)), exposed to Claude Code as an MCP stdio server. No API key required.

### Install

```bash
pip install mempalace          # Requires-Python >= 3.9
```

Then register it as an MCP server (user scope). Copy the `mcpServers.mempalace` block from [`examples/mcp-config.example.json`](../../examples/mcp-config.example.json) into your `~/.claude.json` (or `~/.claude/settings.json`) and adjust the palace path:

```json
"mempalace": {
  "type": "stdio",
  "command": "python3",
  "args": ["-m", "mempalace.mcp_server"],
  "env": { "MEMPALACE_PALACE_PATH": "/absolute/path/to/your/.mempalace" }
}
```

> **Pin the interpreter.** The MCP server launches with whatever `command` resolves to at startup. If your machine has several Python installs, a bare `python3` can resolve to an interpreter where `mempalace` is **not** installed — the MCP server then fails to start with `No module named 'mempalace'`. Use the **absolute path** to the interpreter that has `mempalace` (e.g. `/opt/homebrew/bin/python3.11`) as `command`, not bare `python3`.

### Update

```bash
<interpreter> -m pip install --upgrade mempalace   # use the SAME interpreter the MCP server runs
<interpreter> -m pip show mempalace                # verify the version
```

If you have more than one Python with `mempalace` installed, upgrade the one the MCP `command` points at — upgrading a different interpreter changes nothing for the running server.

### Data

Records live under `MEMPALACE_PALACE_PATH`. It is a local store (SQLite + index) — back it up; it is not regenerable.

---

## Graphify (optional companion — not integrated)

Turns a code folder into a queryable knowledge graph (entities + relationships) with CLI queries and an interactive `graph.html`. Package `graphifyy` on PyPI (CLI stays `graphify`); repo [safishamsi/graphify](https://github.com/safishamsi/graphify).

**Status:** evaluated for skill integration and deliberately **not** wired into any skill. On small/mid-size codebases its impact/`affected`/`path` queries were unreliable (missed real callers, routed through hub nodes), and a capable agent reading the code directly gives more reliable, staleness-free impact analysis. Keep it as an **ad-hoc** tool for exploring a large unfamiliar repo. Re-evaluate if working a codebase too large to read into context.

### Install

```bash
# needs Python 3.10+ ; pipx keeps it isolated
brew install pipx                                  # if pipx is missing
pipx install graphifyy --python /opt/homebrew/bin/python3.11
```

> Do **NOT** run `graphify install` / `graphify claude install`. They edit your global `~/.claude/CLAUDE.md` and add a `PreToolUse` hook to register graphify's own `/graphify` skill. This plugin does not use them — keep graphify CLI-only.

### Update

```bash
pipx upgrade graphifyy
```

### Ad-hoc usage

```bash
graphify update path/to/code        # AST-only build, no LLM, no API key → ./graphify-out/
graphify explain "SomeFunction()"   # node + its neighbors (clean, reliable)
graphify path "NodeA" "NodeB"       # shortest path between two nodes
graphify query "what touches auth?" # BFS traversal answer
open graphify-out/graph.html        # interactive visualization
```

Code extraction (`update`) is free (tree-sitter AST). Docs/PDF/image/video extraction (`graphify extract`) requires an LLM API key and is not needed for code graphs.

> **Gitignore the output.** `graphify-out/` holds a large `graph.json` plus a `cache/` directory — add `graphify-out/` to `.gitignore`, do not commit it.

### Uninstall

```bash
pipx uninstall graphifyy
```
