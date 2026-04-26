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

## Scope by zone

This directive applies to **Zone 2 only** — `~/Obsidian/Dev/claude-memory/` and its symlink alias `~/.claude/projects/*/memory/`.

- **Zone 1** (`~/Obsidian/Dev/{Decisions,Infra,Research,Patterns,Meta,Archives}/`) is human-curated. LLMs should NOT write to Zone 1 paths via Edit/Write/obsidian CLI without explicit user direction. To add to Zone 1, draft in Zone 2 and surface a promotion request.
- **Zone 3** (`~/Projects/.omc/wiki/`) follows Karpathy append-only by design and is NOT git-tracked. Do NOT apply rewrite rules to Zone 3 files. Use only the OMC `wiki` skill / `wiki_*` tools. Manual edits will be overwritten by autoCapture.

`.omc-config.json`'s `obsidian.allowedFolders` constrains the obsidian CLI only. Filesystem-level Edit/Write tools can still touch Zone 1 — the human-only rule is policy, not enforcement. Honor it as policy.

## Canonical zone routing

When deciding where to write a fact, use this routing table:

| Topic class | Canonical zone | Rationale |
|---|---|---|
| Cross-project infrastructure (Mac fleet, OCI, Tailscale, SSH) | Zone 1 `Infra/` | reused across projects |
| Architectural decisions, paradigm shifts, ADRs | Zone 1 `Decisions/` | evergreen; durable across the project's lifetime |
| Reusable patterns (Fire-and-forget DB, Three-layer halt, Cross-check drift) | Zone 1 `Patterns/` | applicable beyond a single project |
| External research (data API gotchas, microstructure findings) | Zone 1 `Research/` | factual, attributable, not session-scoped |
| Project state, waves, current bot status, feedback notes | Zone 2 | weeks–months lifespan, LLM-drafted |
| Session traces, scratch hypotheses, ephemeral lookups | Zone 3 | session-scoped, append-only |

**Single source of truth rule**: each topic should have ONE canonical file. If the same content exists in 2+ zones (e.g., bluenode in Z1+Z2+Z3), the non-canonical copies should be replaced with pointer stubs (10-30 lines max) that link to the canonical.

## MEMORY.md as index, not content

`MEMORY.md` is loaded automatically into every Claude Code session. It MUST stay an index of pointers, not a content store.

- Each entry: ONE line, under 150 characters, format `- [Title](file.md) — one-line hook`
- No frontmatter (MEMORY.md is structurally an index, not a memory file)
- Lines after 200 are truncated by the harness — keep under 180 with margin
- If a topic block exceeds ~6 lines or any line exceeds 150 chars, extract the narrative to a dedicated `claude-memory/<topic>.md` file and replace with pointers
- Project blocks should be 5-12 pointer lines maximum

**Detection heuristic**: if MEMORY.md has prose paragraphs, dense narrative, or wave-by-wave detail, it has structurally collapsed into an audit log. Distill back to pointers immediately.

## Cross-zone deduplication

When you discover the same content exists in multiple zones:

1. Identify the canonical zone via the routing table above.
2. Do NOT silently delete the non-canonical copies — surface the conflict to the user.
3. If user confirms: leave canonical untouched, replace non-canonical with a 10-30 line pointer stub that links to canonical.
4. If user defers: note the duplication in the file's frontmatter or a HEADER comment so future sessions can find it.

Never manually edit Zone 1 or Zone 3 to "fix" duplication — Zone 1 is human-only, Zone 3 will regenerate via autoCapture.

## Exceptions

- **Git log** and **operational audit trails** are not memory — they are event streams. Do not apply refinement to them.
- **Session-log pages** (Zone 3 autoCapture) are not memory — they are raw capture. This directive does not apply to them.
- **Append-eligible logs** (project audit logs like `polymarket_audit_log.md` whose frontmatter `description` declares them event streams) may receive new dated sections without violating rewrite-over-append, BUT existing sections within them still follow the rewrite-not-update rule.
- This directive applies to **curated knowledge**, not to raw data.

## Relationship to Karpathy default

Karpathy's LLM Wiki design uses append-only merge as a safety mechanism (preserve history against LLM mistakes). This directive explicitly overrides that default for **Zone 2** because:
1. Git provides the history preservation Karpathy's append-only gives
2. User has git-backed vault, so the safety argument is handled elsewhere
3. Long-term knowledge quality requires distillation, which is incompatible with append-only

**The override's premise (git history) does NOT hold for Zone 3.** Zone 3 is not git-tracked — append-only is its only safety mechanism. Therefore the kepano rewrite-rule does NOT apply to Zone 3, even though it lives under `~/Projects/.omc/`. Honor Karpathy's default there.
