# MCP Tool Priority

## Web Search + Scraping (Local Stack)

**SearXNG (search) + Crawl4AI (scraping) — both local Docker, free, unlimited.**

### Search → Scrape Workflow

When search is needed, always follow this order:

```
1. Search via SearXNG (Bash)
   curl -s "http://localhost:8888/search?q=QUERY&format=json" | jq '.results[:5] | .[] | {title, url}'

2. Scrape URLs via Crawl4AI (MCP)
   mcp__c4ai-sse__md   → extract page as markdown
   mcp__c4ai-sse__ask  → AI-powered summary
```

### SearXNG Search Categories

```bash
# Web search (default)
curl -s "http://localhost:8888/search?q=QUERY&format=json"

# Images
curl -s "http://localhost:8888/search?q=QUERY&format=json&categories=images"

# News
curl -s "http://localhost:8888/search?q=QUERY&format=json&categories=news"

# Videos
curl -s "http://localhost:8888/search?q=QUERY&format=json&categories=videos"

# IT / Dev
curl -s "http://localhost:8888/search?q=QUERY&format=json&categories=it"
```

### Crawl4AI Tool Mapping

| Task | Tool | MCP Server |
|------|------|------------|
| Page → Markdown | `mcp__c4ai-sse__md` | c4ai-sse |
| Page → HTML | `mcp__c4ai-sse__html` | c4ai-sse |
| Screenshot | `mcp__c4ai-sse__screenshot` | c4ai-sse |
| PDF extraction | `mcp__c4ai-sse__pdf` | c4ai-sse |
| Multi-page crawl | `mcp__c4ai-sse__crawl` | c4ai-sse |
| JS execution | `mcp__c4ai-sse__execute_js` | c4ai-sse |
| AI Q&A on page | `mcp__c4ai-sse__ask` | c4ai-sse |

### Priority Rules

1. **Search → SearXNG** via `curl localhost:8888` (prefer over WebSearch, firecrawl_search)
2. **Scraping → Crawl4AI** via c4ai-sse MCP tools (prefer over firecrawl_scrape)
3. **WebSearch (built-in)** → fallback only when SearXNG curl fails
4. **Firecrawl** → `firecrawl_agent` (autonomous exploration) only, 500 credits limited
5. If Crawl4AI is down → suggest `docker restart crawl4ai`, then fallback to Firecrawl
6. If SearXNG is down → suggest `docker restart searxng`, then fallback to WebSearch
