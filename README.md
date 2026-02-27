# Claude Code Setup

> A battle-tested Claude Code configuration with 7 agents, 17 hooks, 25 commands, 30+ skills, and a multi-agent pipeline system.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude_Code-2.1+-blue.svg)](https://docs.anthropic.com/en/docs/claude-code)

Built on top of configurations and ideas from:
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Anthropic hackathon winner's complete config collection
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — Karpathy's coding guidelines as Claude Code skills
- [claude-code-tips](https://github.com/ykdojo/claude-code-tips) — Practical tips and the `dx` plugin

## What's Included

| Component | Count | Description |
|-----------|------:|-------------|
| **Agents** | 7 | Custom agent definitions (3 Sonnet, 4 Haiku) — language/tool specialists only |
| **Rules** | 8 | Global behavioral rules (coding style, security, TDD, MCP priority, etc.) |
| **Hooks** | 17 | Event-driven automations across 8 lifecycle events |
| **Commands** | 25 | Slash commands for common workflows |
| **Skills** | 30+ | Reusable skill packages across multiple languages |
| **Scripts** | 25+ | Hook scripts, utilities, CI validators |
| **Contexts** | 3 | Reusable context files (dev, research, review) |
| **MCP Servers** | 15 | Pre-configured global MCP server templates |

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git
cd claude-code-setup
bash install.sh
```

The installer will:
1. Back up your existing `~/.claude/` configuration
2. Copy all config files to `~/.claude/`
3. Set executable permissions on scripts
4. Print a post-install checklist

Use `--dry-run` to preview changes without modifying anything:

```bash
bash install.sh --dry-run
```

## Architecture

```
~/.claude/
├── settings.json              # Permissions, env vars, status line, plugins
├── agents/                    # 7 custom agent definitions
├── rules/                     # 7 global rules (loaded into system prompt)
├── hooks/
│   └── hooks.json             # 17 hooks across 8 lifecycle events
├── commands/                  # 25 slash commands
├── scripts/
│   ├── *.sh, *.js             # 6 top-level utility scripts
│   ├── hooks/                 # 10 hook handler scripts
│   ├── lib/                   # 4 shared libraries
│   └── ci/                    # 5 CI validation scripts
├── skills/                    # 30+ skill packages
└── contexts/                  # 3 context files
```

## Agents

Agents are specialized sub-agents spawned by Claude Code for specific tasks. Each has a designated model tier based on task complexity.

| Model | Agent | Purpose |
|-------|-------|---------|
| **Sonnet** | `e2e-runner` | Playwright E2E test generation and execution |
| **Sonnet** | `refactor-cleaner` | Dead code detection (knip, depcheck, ts-prune) |
| **Sonnet** | `python-reviewer` | PEP 8, type hints, ruff/mypy/bandit checks |
| **Haiku** | `database-reviewer` | PostgreSQL optimization, schema review, RLS |
| **Haiku** | `doc-updater` | Documentation and codemap generation |
| **Haiku** | `go-reviewer` | Idiomatic Go, concurrency, error handling review |
| **Haiku** | `go-build-resolver` | Go build/vet error resolution |

> **Note**: Generic agents (architect, planner, code-reviewer, security-reviewer, tdd-guide, build-error-resolver) were removed — OMC provides superior equivalents with richer prompts. Only language/tool specialists that have no OMC equivalent are kept as custom agents.

## Rules

Rules are loaded into Claude Code's system prompt for every session.

| Rule | Focus |
|------|-------|
| `agent-teams-pipeline.md` | Multi-agent pipeline orchestration (phases, shutdown protocol, failure recovery) |
| `coding-style.md` | Immutability, file organization (<800 lines), error handling |
| `git-workflow.md` | Conventional commits, PR workflow, feature implementation |
| `karpathy-guidelines.md` | Think before coding, simplicity first, surgical changes |
| `performance.md` | Model selection strategy, context window management |
| `security.md` | Secret management, input validation, OWASP checklist |
| `testing.md` | 80% coverage minimum, TDD workflow, test types |
| `mcp-priority.md` | SearXNG + Crawl4AI local stack preferred over cloud APIs |

## Hook System

17 hooks fire across 8 lifecycle events to automate quality checks and workflow enforcement.

| Event | Hooks | Key Functions |
|-------|------:|---------------|
| **PreToolUse** | 7 | Block dev servers outside tmux, review before push, block random .md files, suggest compaction, 55% context block, pipeline-complete block |
| **PreCompact** | 1 | Save state before context compaction |
| **SessionStart** | 1 | Load previous session, detect package manager |
| **PostToolUse** | 4 | PR URL logging, build analysis, Prettier formatting, TypeScript checking (all async) |
| **Stop** | 2 | console.log detection, 75% context → force /half-clone |
| **TaskCompleted** | 1 | Pipeline deliverable verification |
| **TeammateIdle** | 1 | Pipeline idle reason check, orphan detection |
| **SessionEnd** | 2 | Persist session state, extract patterns |

## Commands

25 slash commands for common workflows:

| Command | Description |
|---------|-------------|
| `/plan` | Requirements analysis → implementation plan |
| `/tdd` | Enforce TDD (RED → GREEN → REFACTOR) |
| `/code-review` | Code review with agent |
| `/build-fix` | Fix build errors |
| `/test-coverage` | Coverage analysis |
| `/e2e` | E2E test generation (Playwright) |
| `/refactor-clean` | Dead code cleanup |
| `/checkpoint` | Save checkpoint |
| `/verify` | Run verification |
| `/orchestrate` | Multi-agent orchestration |
| `/sessions` | Session management |
| `/learn` | Extract patterns |
| `/skill-create` | Create skill from patterns |
| `/evolve` | Evolve instincts → skills |
| `/python-review` | Python code review |
| `/go-review` / `/go-build` / `/go-test` | Go workflows |
| `/update-codemaps` / `/update-docs` | Documentation |
| `/eval` | Session evaluation |
| `/setup-pm` | Package manager detection |
| `/instinct-*` | Instinct management (status, export, import) |

## Skills

30+ reusable skill packages covering multiple languages and frameworks:

**Web Development**: `frontend-patterns`, `backend-patterns`, `coding-standards`

**Python**: `python-patterns`, `python-testing`, `django-patterns`, `django-security`, `django-tdd`, `django-verification`

**Go**: `golang-patterns`, `golang-testing`

**Java/Spring**: `springboot-patterns`, `springboot-security`, `springboot-tdd`, `jpa-patterns`, `java-coding-standards`

**Database**: `postgres-patterns`, `clickhouse-io`

**Security**: `security-review` (includes cloud infrastructure security)

**Workflow**: `tdd-workflow`, `verification-loop`, `eval-harness`, `iterative-retrieval`, `strategic-compact`, `karpathy-guidelines`

**Learning**: `continuous-learning`, `continuous-learning-v2` (instinct-based system with observer agent, hooks, and CLI)

**Examples**: `project-guidelines-example`

## MCP Servers

### Global (16 servers, configured in `~/.claude.json`)

| Server | Type | Description |
|--------|------|-------------|
| `github` | HTTP | GitHub Copilot MCP (PRs, issues, repos) |
| `firecrawl` | stdio | Web scraping — `firecrawl_agent` only (500 credits limited) |
| `supabase` | HTTP | Supabase database, auth, storage |
| `vercel` | HTTP | Vercel deployment |
| `railway` | stdio | Railway deployment |
| `cloudflare-*` | HTTP | Docs, Workers builds, bindings, observability |
| `clickhouse` | HTTP | ClickHouse analytics |
| `magic` | stdio | Magic UI components |
| `filesystem` | stdio | Filesystem operations |
| `sequential-thinking` | stdio | Structured reasoning chains |
| `context7` | stdio | Live documentation lookup |
| `c4ai-sse` | SSE | Crawl4AI via Docker (localhost:11235) — primary scraping tool |
| `playwright` | stdio | Playwright browser automation (E2E testing, web interaction) |

> **Note**: MCP memory server (`@modelcontextprotocol/server-memory`) is intentionally excluded — Claude Code's built-in auto memory (`~/.claude/projects/*/memory/`) provides the same functionality natively with automatic loading and no extra process overhead.

### MCP Priority: Local Stack First

The `mcp-priority.md` rule enforces a **SearXNG → Crawl4AI** local workflow over cloud APIs:

```
Search  →  SearXNG (curl localhost:8888)     free, unlimited, local
Scrape  →  Crawl4AI (c4ai-sse MCP)           free, unlimited, local
Fallback → WebSearch (built-in) / Firecrawl   rate-limited, costs money
```

Firecrawl is reserved for `firecrawl_agent` (autonomous multi-step exploration) only. See `rules/mcp-priority.md` for full details.

Use `config/claude.json.template` as a starting point for your `~/.claude.json`.

## Agent Teams Pipeline

The `agent-teams-pipeline.md` rule enables a sophisticated multi-agent pipeline system:

```
P-1 Research → P0 Design → P0.5 Review → P1 Implementation → P1.5 Integration → P2 Verification → P3 Refactoring → P4 Documentation
```

Key features:
- Native teams (child_process.fork) — no teammate limit
- Lead delegates only — never touches code directly
- `p-` prefix naming for pipeline agents
- 4-step phase transition protocol with blocking shutdown verification
- Failure recovery with PROGRESS.md-based state
- Optional git worktree strategy for branch isolation
- Context safety: blocks ExitPlanMode above 55%, forces clone above 75%
- Team routing: `/team` for native pipeline, `/omc-teams` for tmux CLI workers

## Permissions

The `settings.json` includes a carefully tuned permission model:

- **Allow**: Read, Edit, Write, Glob, Grep, WebFetch, WebSearch, and common CLI tools (git, npm, python, etc.)
- **Deny**: `rm -rf /`, `rm -rf ~`, `sudo`, reading `.env` files
- **Ask**: `git push`, `docker` commands
- **Default Mode**: `acceptEdits`

## Post-Install Configuration

After running `install.sh`:

1. **MCP Servers** — Copy `config/claude.json.template` to `~/.claude.json` and fill in:
   - `FIRECRAWL_API_KEY` (or remove the firecrawl entry)
   - `YOUR_PROJECT_PATH` with your actual projects directory
   - Run `gh auth login` for GitHub Copilot MCP

2. **Docker Services** (optional, for web crawling + search):
   ```bash
   # Crawl4AI — web scraping/crawling with MCP SSE interface
   docker run -d --name crawl4ai --restart unless-stopped \
     -p 11235:11235 --shm-size=1g unclecode/crawl4ai:latest

   # SearXNG — privacy-respecting meta search engine (JSON API)
   docker run -d --name searxng --restart unless-stopped \
     -p 8888:8080 searxng/searxng:latest
   ```

   Both containers use `--restart unless-stopped` (auto-restart on crash and Docker daemon restart). They share the default Docker bridge network, so Crawl4AI can reach SearXNG via `host.docker.internal:8888`.

   **SearXNG** provides a local search API (no API key needed):
   ```bash
   curl -s "http://localhost:8888/search?q=QUERY&format=json" | jq '.results[:5]'
   ```
   Enable JSON format in SearXNG settings (`~/.config/searxng/settings.yml`): `formats: [html, json]`

3. **Plugin**:
   ```
   /install-plugin dx@ykdojo
   ```

4. **Restart** Claude Code to load all configurations.

## Customization

- **Add agents**: Create `.md` files in `agents/` with frontmatter (name, description, tools, model)
- **Add rules**: Create `.md` files in `rules/` — they're loaded into every session's system prompt
- **Add commands**: Create `.md` files in `commands/` — accessible via `/command-name`
- **Add hooks**: Edit `hooks/hooks.json` — supports PreToolUse, PostToolUse, Stop, SessionStart, SessionEnd, PreCompact, TaskCompleted, TeammateIdle
- **Add skills**: Create directories in `skills/` with a `SKILL.md` file

## Lessons Learned

Hard-won debugging insights from production use:

1. **Always confirm shutdown before TeamDelete** — skipping causes orphan agents + infinite thinking loops
2. **Stop hook stdout = decision channel** — never echo raw data to stdout in Stop hooks
3. **Context at 75%+ → /half-clone** — extended thinking fails to converge above 80%
4. **New work after Pipeline Complete = new session** — 120k+ accumulated tokens prevent convergence
5. **macOS has no flock** — use `mkdir` atomic locks instead
6. **Prevent TeammateIdle storms** — inactive teammates must exit 0 immediately
7. **PreToolUse hooks must use `exit 2` to block** — `{"decision":"block"}` JSON is silently ignored for PreToolUse
8. **cleanup-team-panes.sh is for /omc-teams only** — native teams (/team) are cleaned up by TeamDelete

## License

MIT
