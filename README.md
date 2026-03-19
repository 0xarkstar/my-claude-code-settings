# Claude Code Setup

> A battle-tested Claude Code configuration with custom hooks, 7 agents, 25 commands, 30+ skills — designed to work alongside [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (OMC) plugin.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude_Code-2.1.79+-blue.svg)](https://docs.anthropic.com/en/docs/claude-code)
[![OMC](https://img.shields.io/badge/OMC-4.9.0+-green.svg)](https://github.com/Yeachan-Heo/oh-my-claudecode)

Built on top of configurations and ideas from:
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Anthropic hackathon winner's complete config collection
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills) — Karpathy's coding guidelines as Claude Code skills
- [claude-code-tips](https://github.com/ykdojo/claude-code-tips) — Practical tips and the `dx` plugin

## Architecture

This repo provides **custom configurations** that complement the OMC plugin:

| Layer | Source | What It Provides |
|-------|--------|------------------|
| **OMC Plugin** | `oh-my-claudecode@omc` | 18 base agents, 27 skills (team, autopilot, ralph, ultrawork, etc.), 11 hook events, CLAUDE.md orchestration prompt |
| **This Repo** | `claude-code-setup` | 7 custom agents, 8 custom hooks, 7 rules, 25 commands, 30+ skills, MCP templates |

```
~/.claude/
├── settings.json              # Permissions, env vars, plugins (incl. OMC)
├── agents/                    # 7 custom + 18 OMC agents (merged)
├── rules/                     # 7 global rules (loaded into system prompt)
├── hooks/
│   └── hooks.json             # 8 custom hooks (2 events) — OMC hooks are separate
├── commands/                  # 25 slash commands
├── scripts/
│   ├── hooks/ensure-coauthor.sh  # Git commit Co-Authored-By enforcement
│   ├── *.sh                      # Utility scripts
│   └── ci/                       # 5 CI validation scripts
└── skills/                    # 30+ skill packages (merged with OMC plugin skills)
```

## Quick Start

```bash
# 1. Clone and install custom config
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git
cd claude-code-setup
bash install.sh

# 2. Install OMC plugin (in a Claude Code session)
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode

# 3. Install OMC CLI
npm install -g oh-my-claude-sisyphus@latest
omc install
```

Use `--dry-run` to preview changes without modifying anything:

```bash
bash install.sh --dry-run
```

## What's Included

### Custom Agents (7)

Language/tool specialists that have no OMC equivalent:

| Model | Agent | Purpose |
|-------|-------|---------|
| **Sonnet** | `e2e-runner` | Playwright E2E test generation and execution |
| **Sonnet** | `refactor-cleaner` | Dead code detection (knip, depcheck, ts-prune) |
| **Sonnet** | `python-reviewer` | PEP 8, type hints, ruff/mypy/bandit checks |
| **Haiku** | `database-reviewer` | PostgreSQL optimization, schema review, RLS |
| **Haiku** | `doc-updater` | Documentation and codemap generation |
| **Haiku** | `go-reviewer` | Idiomatic Go, concurrency, error handling review |
| **Haiku** | `go-build-resolver` | Go build/vet error resolution |

> OMC provides 18 base agents (architect, planner, executor, code-reviewer, etc.) via the plugin.

### Custom Hooks (8 hooks, 2 events)

These are custom workflow hooks that complement OMC's orchestration hooks:

| Event | Hook | Function |
|-------|------|----------|
| **PreToolUse** | dev server block | Block `npm run dev` etc. outside tmux (exit 1) |
| **PreToolUse** | tmux reminder | Warn when long-running commands run outside tmux |
| **PreToolUse** | ensure-coauthor | Block git commit without `Co-Authored-By` trailer (exit 2) |
| **PreToolUse** | git push review | Reminder before git push |
| **PreToolUse** | md file block | Block creation of random .md/.txt files |
| **PostToolUse** | PR URL logger | Log PR URL after `gh pr create` |
| **PostToolUse** | Prettier format | Auto-format JS/TS files after edits (async) |
| **PostToolUse** | TypeScript check | Run `tsc --noEmit` after TS edits (async) |

> OMC provides orchestration hooks (keyword detection, context safety, session management, etc.) via the plugin — no overlap with these custom hooks.

### Rules (7)

| Rule | Focus |
|------|-------|
| `coding-style.md` | Immutability, file organization (<800 lines), error handling |
| `git-workflow.md` | Conventional commits, PR workflow, feature implementation |
| `karpathy-guidelines.md` | Think before coding, simplicity first, surgical changes |
| `performance.md` | Model selection strategy, context window management |
| `security.md` | Secret management, input validation, OWASP checklist |
| `testing.md` | 80% coverage minimum, TDD workflow, test types |
| `mcp-priority.md` | SearXNG + Crawl4AI local stack preferred over cloud APIs |

### Commands (25)

| Command | Description |
|---------|-------------|
| `/plan` | Requirements analysis and implementation plan |
| `/tdd` | Enforce TDD (RED, GREEN, REFACTOR) |
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
| `/evolve` | Evolve instincts into skills |
| `/python-review` | Python code review |
| `/go-review` / `/go-build` / `/go-test` | Go workflows |
| `/update-codemaps` / `/update-docs` | Documentation |
| `/eval` | Session evaluation |
| `/setup-pm` | Package manager detection |
| `/instinct-*` | Instinct management (status, export, import) |

### Skills (30+)

**Web**: `frontend-patterns`, `backend-patterns`, `coding-standards`

**Python**: `python-patterns`, `python-testing`, `django-patterns`, `django-security`, `django-tdd`, `django-verification`

**Go**: `golang-patterns`, `golang-testing`

**Java/Spring**: `springboot-patterns`, `springboot-security`, `springboot-tdd`, `jpa-patterns`, `java-coding-standards`

**Database**: `postgres-patterns`, `clickhouse-io`

**Security**: `security-review` (includes cloud infrastructure security)

**Workflow**: `tdd-workflow`, `verification-loop`, `eval-harness`, `iterative-retrieval`, `strategic-compact`

**Learning**: `continuous-learning-v2` (instinct-based system with observer agent and CLI)

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
| `playwright` | stdio | Playwright browser automation |

### MCP Priority: Local Stack First

The `mcp-priority.md` rule enforces a **SearXNG + Crawl4AI** local workflow over cloud APIs:

```
Search  ->  SearXNG (curl localhost:8888)     free, unlimited, local
Scrape  ->  Crawl4AI (c4ai-sse MCP)           free, unlimited, local
Fallback -> WebSearch (built-in) / Firecrawl   rate-limited, costs money
```

Use `config/claude.json.template` as a starting point for your `~/.claude.json`.

## Permissions

The `settings.json` includes a carefully tuned permission model:

- **Allow**: Read, Edit, Write, Glob, Grep, WebFetch, WebSearch, and common CLI tools (git, npm, python, etc.)
- **Deny**: `rm -rf /`, `rm -rf ~`, `sudo`, reading `.env` files (12 variants)
- **Ask**: `git push`, `docker` commands
- **Default Mode**: `acceptEdits`

## Plugins

| Plugin | Source | Purpose |
|--------|--------|---------|
| `oh-my-claudecode@omc` | [GitHub](https://github.com/Yeachan-Heo/oh-my-claudecode) | Multi-agent orchestration (team, autopilot, ralph, ultrawork) |
| `dx@ykdojo` | [GitHub](https://github.com/ykdojo/claude-code-tips) | Developer experience (clone, half-clone, handoff, gha) |
| `clangd-lsp` | claude-plugins-official | C/C++ language server |

## Customization

- **Add agents**: Create `.md` files in `agents/` with frontmatter (name, description, tools, model)
- **Add rules**: Create `.md` files in `rules/` — they're loaded into every session's system prompt
- **Add commands**: Create `.md` files in `commands/` — accessible via `/command-name`
- **Add hooks**: Edit `hooks/hooks.json` — custom hooks run alongside OMC plugin hooks
- **Add skills**: Create directories in `skills/` with a `SKILL.md` file

## License

MIT
