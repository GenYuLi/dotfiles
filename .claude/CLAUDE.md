# Global Engineering Standards

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
