# Dependencies & tooling setup

How to install and update the external tools the skills rely on. Two tools matter:

- **MemPalace** — *required* by the 9 memory-using skills (cross-session memory).
- **Graphify** — *optional* companion (code knowledge graph). Not wired into any skill; install only if you want it ad-hoc.

---

## MemPalace (required)

Long-term cross-session memory. Python package `mempalace` (repo: [MemPalace/mempalace](https://github.com/MemPalace/mempalace)), exposed to Claude Code as an MCP stdio server. No API key required.

### Install (recommended: dedicated venv)

A dedicated virtualenv keeps `mempalace` isolated and immune to system / Homebrew Python upgrades:

```bash
python3.11 -m venv ~/.mempalace-venv                 # any Python >= 3.9
~/.mempalace-venv/bin/pip install --upgrade mempalace
```

Then register it as an MCP server (user scope). Copy the `mcpServers.mempalace` block from [`examples/mcp-config.example.json`](../../examples/mcp-config.example.json) into your `~/.claude.json`, pointing `command` at the venv's interpreter and setting your palace path:

```json
"mempalace": {
  "type": "stdio",
  "command": "/Users/<you>/.mempalace-venv/bin/python",
  "args": ["-m", "mempalace.mcp_server"],
  "env": { "MEMPALACE_PALACE_PATH": "/absolute/path/to/your/.mempalace" }
}
```

> **Use an absolute interpreter path — never bare `python3`.** The MCP server launches with whatever `command` resolves to at startup. A bare `python3` can resolve to an interpreter where `mempalace` is **not** installed (e.g. a newer Homebrew Python) — the server then fails with `No module named 'mempalace'`. A dedicated venv with an absolute path removes this whole class of breakage.
>
> After editing the config, **restart Claude Code** (or reload MCP servers) — a running MCP connection keeps the old config until reload.

### Update

```bash
~/.mempalace-venv/bin/pip install --upgrade mempalace
~/.mempalace-venv/bin/mempalace --version            # verify
```

Then restart Claude Code so the MCP server reloads on the new version. Latest known version: 3.3.5.

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
