# MCP Tool Priority — Web Search + Scraping

Use the lightest tool that gets the page. Order from a small test on 2026-11-05 (16 URLs, 8 queries; browser tools not yet tested). Local stack: OCI Docker (Tailscale `<tailscale-ip>`), free & unlimited.

## Search
1. **WebSearch** first.
2. **SearXNG** via curl for volume, or when WebSearch misses. Pass `engines=yandex,naver`: from the OCI IP, Google, DuckDuckGo, Brave, Startpage, Mojeek and Qwant are blocked, and the default Bing is Japan-biased and returns junk for Korean (tested 2026-11-05). These queries go to Yandex and Naver.
   `curl -s -G "http://<tailscale-ip>:8888/search" --data-urlencode "q=QUERY" -d format=json -d engines=yandex,naver | jq '.results[:5] | .[] | {title, url}'`
   Categories: add `-d categories=images|news|videos|it` instead of `engines` (default = web).

## Read a page
1. **Raw or API variant** if one exists: GitHub raw, npm registry, `.md` docs, `llms.txt`.
2. **`curl -sL`** with a browser user-agent for static pages. Check the body: block pages can return HTTP 200, and JS pages return an empty shell.
3. **WebFetch** when you need an answer rather than the original text. It reads only the first 100k characters.
4. **Crawl4AI** (c4ai-sse MCP) for JS-heavy or bot-protected pages or when the original text matters: `mcp__c4ai-sse__md` with `fit`, then `raw` if content is missing. Output can be very large on docs pages; avoid the `bm25` filter (returned nav links or 340k chars).
   Also `__html` · `__screenshot` · `__pdf` · `__crawl` (multi-page). `__execute_js` returns 403 on Crawl4AI 0.9.5 (disabled server-side).
   Crawl4AI 0.9.5 requires a bearer token. c4ai-sse runs through `~/.local/bin/c4ai-mcp-stdio`, which reads `~/.config/crawl4ai/api_token`. If its tools return HTTP 401, reconnect c4ai-sse with `/mcp` (sessions started before 2026-11-01 have no token).

## Fallbacks
- SearXNG down → `ssh oci 'docker restart searxng'`, then built-in WebSearch.
- SearXNG degraded (HTTP 200 but 0 results — engines suspended, seen 2026-10-28) → retry with `-d engines=yandex`, then restart as above.
- Crawl4AI down → `ssh oci 'docker restart crawl4ai'`, then Firecrawl (`firecrawl_agent`, 500-credit cap — autonomous exploration only).
