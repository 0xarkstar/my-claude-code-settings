# Obsidian Knowledge Capture

## Purpose

The Obsidian vault at `~/Obsidian/Dev/` is the developer's long-term, human-readable
knowledge base. It is NOT a log or a dump of session outputs. It captures the WHY behind
decisions — narrative context that MEMORY.md cannot provide.

## Three-Tier Architecture

| Tier | Store | Format | Audience | Update |
|------|-------|--------|----------|--------|
| 1 | MEMORY.md | Bullets (1-2 lines) | Claude Code on session start | Claude auto-updates |
| 2 | ~/Obsidian/Dev/ | Narrative paragraphs (50-150 words) | Developer reading independently | Claude writes at decision points |
| 3 | MCP memory graph | Entity-relation triples | Claude cross-entity queries | Claude updates when explicit |

## When to Write an Obsidian Note (3-Question Gate)

Write a note ONLY if ALL THREE questions are YES:

1. Would the developer benefit from reading this in paragraph form 6 months from now?
2. Is this NOT findable in official documentation with a quick search?
3. Did discovering this require >10 minutes of non-obvious debugging or experimentation?

**Default behavior: DO NOT write a note.** Only write when the gate is passed.

## Decision-Point Triggers (examples that typically pass the gate)

- A bug required >3 edit-test cycles to resolve and the root cause was non-obvious
- A decision was made between 2+ named alternatives with a non-obvious reason for rejection
- A new external service/SDK was integrated and has gotchas not in official docs
- A test pattern emerged that works reliably for a recurring problem class
- A cross-project pattern was identified (same problem appears in 2+ projects)

## Explicit NOT-capture Examples

Do NOT write a note for:
- Standard library usage (grep, git commands, basic Python)
- Information directly in official docs (CCXT docs, Pydantic docs)
- Test runs, file edits, bash commands — these are process, not knowledge
- Bugs that were typos, missing imports, or obvious syntax errors
- Every git commit (even feat: commits are usually not noteworthy)
- Metrics that change over time (test counts, coverage %, line counts)

## Routing Algorithm

After solving a non-trivial problem, evaluate:

```
Q1: Is the core insight one sentence (a fact/pattern)?
    YES → Add to MEMORY.md as a bullet point
    NO  → continue

Q2: Did this require >10 min of non-obvious work?
    NO  → discard (recoverable)
    YES → continue

Q3: Is the insight time-stable (not a metric that changes)?
    NO  → MEMORY.md with a "(check for staleness)" marker
    YES → continue

Q4: Does a similar note already exist in ~/Obsidian/Dev/?
    YES → read it and APPEND/UPDATE, do not create duplicate
    NO  → create new note
```

## Note Format (use exactly)

```markdown
---
type: adr|til|post-mortem|pattern
project: {cwd project name or infer from context}
date: YYYY-MM-DD
tags: [tag1, tag2]
---

# {Descriptive title in plain English}

## Context
{One sentence: what were we trying to do?}

## Decision / Finding
{2-5 sentences: what was discovered or decided, and why.
Include the alternatives that were rejected and the reason.}

## Why This Matters
{1-2 sentences: what goes wrong if you ignore this?}

## Related
{Optional: [[wikilinks to related notes]]}
```

## File Naming and Location

```
~/Obsidian/Dev/Projects/{project-name}/{YYYY-MM-DD}-{kebab-case-title}.md
~/Obsidian/Dev/Resources/patterns/{YYYY-MM-DD}-{kebab-case-title}.md  (cross-project)
~/Obsidian/Dev/Resources/TIL/{YYYY-MM-DD}-{kebab-case-title}.md       (atomic learnings)
~/Obsidian/Dev/Areas/infra/{YYYY-MM-DD}-{kebab-case-title}.md         (infra/fleet/tools)
```

Examples:
- `Projects/arb-bot/2026-03-11-ccxt-authentication-error-mock.md`
- `Resources/patterns/2026-03-11-decimal-division-python.md`
- `Areas/infra/2026-03-11-claude-code-stop-hook-constraints.md`

## How to Write (Mechanism)

Use the **Write tool** directly to the filesystem path. Do NOT use Obsidian CLI.
The vault is a directory of .md files — Obsidian picks up new files automatically.

**New projects:** If `~/Obsidian/Dev/Projects/{project}/` does not exist, create it with
`mkdir -p ~/Obsidian/Dev/Projects/{project}/` before writing the first note.
The project name should match the directory name in `/Users/arkstar/Projects/`.

Always check with Glob first: `~/Obsidian/Dev/Projects/{project}/*.md`
If a similar note exists, use Edit to append rather than creating a duplicate.

## After Writing

Mention it briefly in your response:
> "Saved to Obsidian: `Projects/arb-bot/2026-03-11-ccxt-auth-mock.md`"

Do NOT ask the user whether to save. Write silently and mention it after.

## Security

NEVER include in Obsidian notes:
- API keys, tokens, secrets (even partial or masked)
- Wallet addresses, private keys
- Environment variable values
- Passwords or credentials of any kind

If the finding involves a secret, describe the pattern abstractly without the value.

## Ownership Split (Critical)

Obsidian notes must NOT contain:
- Current test counts, coverage percentages, line counts (these belong in MEMORY.md)
- "As of today" facts that will be stale next week
- Duplicate content already in MEMORY.md

Obsidian notes SHOULD contain:
- The story behind a decision (not just the decision)
- Why an alternative was rejected (not just what was chosen)
- The failure path that led to the solution
