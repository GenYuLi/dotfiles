
## Codex only: shared memory with Claude Code

This section is appended for Codex (home/codex.nix builds `~/.codex/AGENTS.md`
as `.claude/CLAUDE.md` + this file). Claude Code has the same behaviour built
into its harness, so the two agents read and write one memory.

Claude Code keeps a curated, file-based memory per project. Treat it as the
single source of truth; do not keep separate notes elsewhere.

- **Location**: `~/.claude/projects/<slug>/memory/`. `<slug>` is the absolute
  path of the directory the agent is launched from (normally the repo root)
  with every character that is not a letter or digit replaced by `-`.
  Example: `/home/me/.config/foo` becomes `-home-me--config-foo`.
- **Recall**: at the start of a task, if that directory exists, read
  `MEMORY.md` (an index, one line per memory) and open the files whose hook
  looks relevant. A memory reflects what was true when it was written: check
  that a file, flag or command it names still exists before relying on it.
- **Save**: for something durable (who the user is, a correction or confirmed
  approach for how to work, a project decision not derivable from the code,
  a pointer to an external resource) write ONE file per fact:

  ```markdown
  ---
  name: <short-kebab-case-slug>
  description: <one line, used to decide relevance during recall>
  metadata:
    type: user | feedback | project | reference
  ---

  <the fact; for feedback/project add **Why:** and **How to apply:** lines.
  Link related memories as [[their-name]]. Use absolute dates.>
  ```

  then add one pointer line to `MEMORY.md`: `- [Title](file.md) — hook`.
  Update an existing file instead of creating a duplicate; delete memories
  that turn out to be wrong. Never put memory content in `MEMORY.md` itself.
- **Do not save** what the repo already records (code structure, git history,
  this file) or what only matters to the current conversation.
- Writing there is outside the workspace sandbox, so expect to ask for
  approval. That is intended: the user sees what gets remembered.
