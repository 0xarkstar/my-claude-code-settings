---
name: memory-write
description: Rules for writing to Zone-2 auto-memory (rewrite-not-append, kepano refinement). Load this BEFORE editing MEMORY.md or any file under ~/Obsidian/Dev/claude-memory/ or ~/.claude/projects/*/memory/. Every Z2 memory write goes through this skill. Triggers when saving/updating a fact to memory, refining a topic file, or the user says "save this", "remember this", "update memory".
user-invocable: false
---

# memory-write

Policy for Zone-2 memory only (`~/Obsidian/Dev/claude-memory/` and its symlink
`~/.claude/projects/*/memory/`). Zone-1 is human-only. The Z3 wiki is RETIRED: there is no live path on disk and it must never be recreated.

## Z2 writes go through this skill
Every write to Z2 (MEMORY.md, topic files) follows these rules. Don't route Z2 facts through OMC's `wiki` or `remember` skills, the `wiki_*` / `project_memory_*` / `notepad_*` tools, or `.omc/` stores. Those are separate per-project stores, out of scope for Z1/Z2, and not the user's memory.

## Core rule: rewrite, never append
- Refine stale content in place; DELETE facts that are no longer true — never keep old and new side by side.
- NEVER add "Update (YYYY-MM-DD)" trailing sections to a memory file.
- Set `metadata.updated` to today when you refine.
- Git already preserves history, so append-only safety is unnecessary here (this is why Z2 overrides the Karpathy append default).

## Topic file frontmatter
Canonical shape, matching the harness memory schema:
```yaml
---
name: <short-kebab-case-slug>
description: <one-line summary, used to decide relevance during recall>
metadata:
  type: user | feedback | project | reference
  updated: YYYY-MM-DD
---
```
Extra keys go under `metadata`. When you refine an older file that still has top-level `type:` or `updated:`, move them under `metadata:`.

## Adding a new fact
1. Check for an existing topic file; if found, refine it in place.
2. Only create a new file when no semantically related file exists — focused scope, one responsibility.
3. Even when the user says "save this", check for an existing file first — refine, don't duplicate.

## MEMORY.md is an index, not a store
- One pointer line per entry, ≤150 bytes (not characters; Korean text is 3 bytes per character): `- [Title](file.md) — one-line hook`. No frontmatter.
- Harness truncates past line ~200 — keep the file short (target <180 lines; highest-reuse blocks FIRST).
- If a block exceeds ~6 lines or a line exceeds 150 bytes, extract the narrative to `claude-memory/<topic>.md` and leave pointers.
- Finished/submitted/expired projects: move their block to `claude-memory/ARCHIVE-INDEX.md` (one line each); topic files stay on disk.
- Detection: prose paragraphs or wave-by-wave detail = it has collapsed into an audit log; distill back to pointers.

## Canonical zone routing (where a fact belongs)
| Topic | Zone |
|---|---|
| Cross-project infra (Mac fleet, OCI, Tailscale, SSH) | Z1 `Infra/` |
| Architectural decisions / ADRs | Z1 `Decisions/` |
| Reusable patterns | Z1 `Patterns/` |
| External research findings | Z1 `Research/` |
| Project state, waves, bot status, feedback | Z2 |

One canonical file per topic. If the same content lives in 2+ zones, surface the conflict to the user — do NOT silently delete Z1. If confirmed, replace the non-canonical copy with a 10-30 line pointer stub linking to canonical. Never Edit/Write Z1 to "fix" it without explicit direction; draft in Z2 and request promotion.

## Exceptions (not subject to rewrite-not-append)
- Git logs and operational audit trails are event streams, not memory.
- Append-eligible project logs whose frontmatter `description` declares them event streams may get new dated sections — but existing sections within them still follow rewrite-not-update.
