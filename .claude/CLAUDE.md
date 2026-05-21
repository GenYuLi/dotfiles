# Global user instructions (cross-machine, dotfiles-managed)

This is the user-level CLAUDE.md for Withers (Hsuan-Yu Lin), symlinked from `~/dotfiles/.claude/CLAUDE.md` and loaded into every session on every machine. Keep it lean — it loads everywhere. Machine-specific or project-specific guidance belongs in a project CLAUDE.md, not here.

## Code Quality Bar

Write and review code at Jeff Dean / Linus Torvalds / Sanjay Ghemawat level:

- **Simplicity first.** If three lines of straight code beats a helper function, use three lines. No over-abstraction.
- **Self-review before presenting.** Ask: is this the simplest way? Can someone understand it in 30 seconds?
- **Verify before claiming.** Never report a bug without checking the source. No false positives.
- **Know the cost model.** ns/μs/ms matters. Don't guess — measure or cite.

## Presenting Work

When showing changes or asking for review, always provide:

1. **What changed and why** (1-2 sentences)
2. **Affected workflow / execution path** (so the reader knows the context)
3. **Where to start reading** (`file:line` references)
4. **How to verify** (commands to run, what to check)

Don't dump code. Lead with context.

## Making Changes

When the user asks "how do I do X" or asks for an explanation — explain first, don't immediately edit code. Only make changes when the user explicitly asks to apply them or confirms the approach.

## Writing Style

- Lead with the conclusion, not the reasoning.
- Every sentence earns its place. No filler.
- Diagrams must be verified against actual code — wrong is worse than none.
- If you don't know, say so.

## Tooling

- **Prefer `rg` (ripgrep) over `grep`.** Faster, respects `.gitignore`, better defaults. Only fall back to `grep` if `rg` is unavailable on the host (verify with `command -v rg` if uncertain).

## Authoring skills and agents

**When turning anything from a session into a reusable skill, you MUST go through `superpowers:writing-skills`. Do not hand-roll a SKILL.md.**

That skill encodes the required discipline:
- **Baseline test first (the Iron Law)**: no skill — and no *edit* to a skill — without first watching an agent fail without it. "It's obviously clear" / "just a small addition" do not exempt you.
- **Description = triggering conditions only, never a workflow summary.** A description that summarizes steps causes Claude to follow the summary and skip the skill body.
- **Discipline/gate skills get a rationalization table + red-flags list** so the rule survives under pressure.

**For agents (subagents / `~/.claude/agents/`), apply the same discipline.** There is no dedicated "writing-agents" skill, so use `superpowers:writing-skills` principles plus `skill-creator` where useful: define the failure you're solving before writing, keep the agent's trigger description to *when to invoke* (not what it does), and verify it behaves before relying on it.

**Why this rule exists**: Withers explicitly wants session learnings captured at the quality bar of well-known projects (e.g. superpowers), not as quick untested notes. A skill written without the RED phase is untested code — it will have gaps that only surface when another agent can't use it.
