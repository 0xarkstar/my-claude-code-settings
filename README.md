# Claude Code Setup

> A battle-tested Claude Code configuration with 13 agents, 17 hooks, 25 commands, 30+ skills, and a multi-agent pipeline system.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude_Code-2.1+-blue.svg)](https://docs.anthropic.com/en/docs/claude-code)

## What's Included

| Component | Count | Description |
|-----------|------:|-------------|
| **Agents** | 13 | Custom agent definitions (2 Opus, 7 Sonnet, 4 Haiku) |
| **Rules** | 7 | Global behavioral rules (coding style, security, TDD, etc.) |
| **Hooks** | 17 | Event-driven automations across 8 lifecycle events |
| **Commands** | 25 | Slash commands for common workflows |
| **Skills** | 30+ | Reusable skill packages across multiple languages |
| **Scripts** | 25+ | Hook scripts, utilities, CI validators |
| **Contexts** | 3 | Reusable context files (dev, research, review) |
| **MCP Servers** | 16 | Pre-configured MCP server templates (12 global + 4 project) |

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
├── agents/                    # 13 custom agent definitions
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
| **Opus** | `architect` | System design, scalability, architecture decisions |
| **Opus** | `planner` | Implementation planning, requirements breakdown |
| **Sonnet** | `security-reviewer` | OWASP Top 10, secrets detection, vulnerability scanning |
| **Sonnet** | `build-error-resolver` | TypeScript/build error resolution with minimal diffs |
| **Sonnet** | `e2e-runner` | Playwright E2E test generation and execution |
| **Sonnet** | `tdd-guide` | Test-driven development enforcement (80%+ coverage) |
| **Sonnet** | `database-reviewer` | PostgreSQL optimization, schema review, RLS |
| **Sonnet** | `refactor-cleaner` | Dead code detection (knip, depcheck, ts-prune) |
| **Sonnet** | `go-build-resolver` | Go build/vet error resolution |
| **Haiku** | `code-reviewer` | General code review (quality, security, maintainability) |
| **Haiku** | `python-reviewer` | PEP 8, type hints, ruff/mypy/bandit checks |
| **Haiku** | `go-reviewer` | Idiomatic Go, concurrency, error handling review |
| **Haiku** | `doc-updater` | Documentation and codemap generation |

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

## Hook System

17 hooks fire across 8 lifecycle events to automate quality checks and workflow enforcement.

| Event | Hooks | Key Functions |
|-------|------:|---------------|
| **PreToolUse** | 7 | Block dev servers outside tmux, review before push, block random .md files, suggest compaction, 65% context block, team 3-member limit |
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

### Global (12 servers, configured in `~/.claude.json`)

| Server | Type | Description |
|--------|------|-------------|
| `github` | HTTP | GitHub Copilot MCP (PRs, issues, repos) |
| `firecrawl` | stdio | Web scraping (requires API key) |
| `supabase` | HTTP | Supabase database, auth, storage |
| `vercel` | HTTP | Vercel deployment |
| `railway` | stdio | Railway deployment |
| `cloudflare-*` | HTTP | Docs, Workers builds, bindings, observability |
| `clickhouse` | HTTP | ClickHouse analytics |
| `magic` | stdio | Magic UI components |
| `filesystem` | stdio | Filesystem operations |

### Project-Level (4 servers)

| Server | Description |
|--------|-------------|
| `memory` | Persistent memory across sessions |
| `sequential-thinking` | Structured reasoning chains |
| `context7` | Live documentation lookup |
| `c4ai-sse` | Crawl4AI via Docker (localhost:11235) |

Use `config/claude.json.template` as a starting point for your `~/.claude.json`.

## Agent Teams Pipeline

The `agent-teams-pipeline.md` rule enables a sophisticated multi-agent pipeline system:

```
P-1 Research → P0 Design → P0.5 Review → P1 Implementation → P1.5 Integration → P2 Verification → P3 Refactoring → P4 Documentation
```

Key features:
- Max 3 simultaneous teammates (tmux race prevention)
- Lead delegates only — never touches code directly
- `p-` prefix naming for pipeline agents
- 6-step phase transition protocol with shutdown verification
- Failure recovery with PROGRESS.md-based state
- Optional git worktree strategy for branch isolation
- Context safety: blocks heavy operations above 65%, forces clone above 75%

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

2. **Docker Services** (optional, for Crawl4AI MCP):
   ```bash
   docker run -d --name crawl4ai --restart unless-stopped \
     -p 11235:11235 --shm-size=1g unclecode/crawl4ai:latest
   ```

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
2. **Run cleanup scripts BEFORE TeamDelete** — config is needed to find tmux pane IDs
3. **Stop hook stdout = decision channel** — never echo raw data to stdout in Stop hooks
4. **Context at 75%+ → /half-clone** — extended thinking fails to converge above 80%
5. **New work after Pipeline Complete = new session** — 120k+ accumulated tokens prevent convergence
6. **macOS has no flock** — use `mkdir` atomic locks instead
7. **Prevent TeammateIdle storms** — inactive teammates must exit 0 immediately

## License

MIT
