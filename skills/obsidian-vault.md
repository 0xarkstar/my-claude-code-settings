# Obsidian Dev Vault Rules

## CRITICAL: Vault Targeting
1. **ALWAYS include `vault="Dev"` in every obsidian command. Never omit the vault parameter.**
2. Personal vault access is strictly forbidden (enforced by deny patterns).
3. Never use `eval`, `dev:cdp`, or `command` subcommands.
4. Never use the `permanent` flag with `delete` — always let deleted files go to trash.

## CLI Usage
- Call CLI directly: `obsidian vault="Dev" <command> key=value`
- Key commands: `vault` (info), `files` (list/count), `folders`, `search`, `read`, `create`, `tags`
- `format=json` for structured output, `total` for counts
- No `status` or `list` commands — use `vault` and `files` instead
- Run `obsidian vault="Dev" help` to check latest available commands.

## Writing Notes
- Prefer **Write tool** directly to filesystem for note creation (works even if Obsidian app is closed).
- Use Obsidian CLI for vault operations: search, read, tags, backlinks, properties.
- See `rules/obsidian-knowledge-capture.md` for the 3-question gate and routing algorithm.

## Search Tips
- If Korean search fails, try English (e.g., try "monitoring" if no results for Korean equivalent).
- Watch for abbreviations: search both "HL" and "Hyperliquid".
- Use `search query="X" limit=20` to cast a wide net, then filter results.
