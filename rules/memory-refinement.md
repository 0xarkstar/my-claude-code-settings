# Memory Refinement Directive

## Rule

WHEN updating files in `memory/`, `claude-memory/`, or any file under `~/.claude/projects/*/memory/`:
- ALWAYS prefer rewriting stale content over appending
- NEVER add "Update (YYYY-MM-DD)" timestamped sections to existing memory files
- DELETE facts that are no longer true — do not keep both old and new versions in the same file
- UPDATE the file's `updated:` timestamp in frontmatter when refining

## Why

User has explicitly chosen kepano methodology as the priority knowledge management philosophy (see `~/Obsidian/Dev/Meta/knowledge-architecture.md`). Kepano's evergreen refinement model requires rewriting rather than append-only accumulation, which is the Karpathy LLM Wiki default behavior and conflicts with long-term knowledge quality at this user's scale (10+ projects, cross-project knowledge reuse).

## How to apply

### When an auto-memory file contains a fact that has changed

1. Find the existing fact
2. Delete it, or rewrite it in place
3. Write the new fact cleanly
4. Update `updated:` in frontmatter to current ISO timestamp
5. Do NOT leave an "Update (YYYY-MM-DD)" section as a historical trail

### When a file has grown beyond 2KB without refinement

- Flag it mentally for the next weekly review (Sundays)
- The user will refine during review — do not force refinement mid-session

### When adding a new fact to an existing topic

- Check if it belongs in an existing file
- If yes, refine that file in place, not append a new section
- If no, create a new file with a focused scope and atomic responsibility

### When the user explicitly asks to "save" a fact

- Still apply the refinement principle: check for existing file, refine instead of duplicate
- Only create a new file if there is no semantically related existing file

## Exceptions

- **Git log** and **operational audit trails** are not memory — they are event streams. Do not apply refinement to them.
- **Session-log pages** (if ever enabled) are not memory — they are raw capture. This directive does not apply to them.
- This directive applies to **curated knowledge**, not to raw data.

## Relationship to Karpathy default

Karpathy's LLM Wiki design uses append-only merge as a safety mechanism (preserve history against LLM mistakes). This directive explicitly overrides that default because:
1. Git provides the history preservation Karpathy's append-only gives
2. User has git-backed vault, so the safety argument is handled elsewhere
3. Long-term knowledge quality requires distillation, which is incompatible with append-only
