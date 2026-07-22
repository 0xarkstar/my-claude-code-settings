# MCP Tool Priority — Web Search + Scraping

Local stack on OCI Docker (Tailscale `<tailscale-ip>`), free & unlimited. Prefer it over WebSearch/Firecrawl.

## Order: search → scrape
1. **Search → SearXNG** via curl:
   `curl -s "http://<tailscale-ip>:8888/search?q=QUERY&format=json" | jq '.results[:5] | .[] | {title, url}'`
   Categories: add `&categories=images|news|videos|it` (default = web).
2. **Scrape → Crawl4AI** (c4ai-sse MCP), one tool per task:
   `mcp__c4ai-sse__md` (→markdown) · `__html` · `__screenshot` · `__pdf` · `__crawl` (multi-page) · `__execute_js`.

## Fallbacks
- SearXNG down → `ssh oci 'docker restart searxng'`, then built-in WebSearch.
- Crawl4AI down → `ssh oci 'docker restart crawl4ai'`, then Firecrawl (`firecrawl_agent`, 500-credit cap — autonomous exploration only).
