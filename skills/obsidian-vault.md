# Obsidian Dev Vault Rules

## CRITICAL: Vault Targeting
1. **ALWAYS include `vault="Dev"` in every obsidian command. Never omit the vault parameter.**
2. Personal vault access is strictly forbidden (enforced by deny patterns).
3. Never use `eval`, `dev:cdp`, or `command` subcommands.
4. Never use the `permanent` flag with `delete` — always let deleted files go to trash.

## Usage
- Call CLI directly: `obsidian vault="Dev" <command> key=value`
- Run `obsidian vault="Dev" help` to check latest available commands.

## Note Creation Rules
1. Include `aliases` in frontmatter (both Korean and English terms).
   Example: `aliases: [HL, Hyperliquid]`
2. Add project tags: `#proj/arb-bot`, `#proj/polymarket-bot`, etc.
3. Add type tags: `#type/troubleshoot`, `#type/decision`, `#type/reference`, etc.
4. Include wikilinks to related existing notes in the body.

## Search Tips
- If Korean search fails, try English (e.g., try "monitoring" if no results for Korean equivalent).
- Watch for abbreviations: search both "HL" and "Hyperliquid".
- Use `search query="X" limit=20` to cast a wide net, then filter results.
