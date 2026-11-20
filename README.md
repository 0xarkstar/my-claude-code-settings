# Claude Code Setup

> A sanitized mirror of one working Claude Code + Codex setup: global rules, lean lane agents, a Codex dispatch skill, Codex guidance and a permission model. It runs alongside the [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) (OMC) plugin.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Claude Code](https://img.shields.io/badge/Claude_Code-2.1.326-blue.svg)](https://docs.anthropic.com/en/docs/claude-code)
[![OMC](https://img.shields.io/badge/OMC-5.7.29-green.svg)](https://github.com/Yeachan-Heo/oh-my-claudecode)
[![Codex CLI](https://img.shields.io/badge/Codex_CLI-0.166.0-lightgrey.svg)](https://github.com/openai/codex)

The live setup is the source of truth; this repository is copied from it by hand. Addresses, home paths and project names are removed on the way.

**Sync status.** Rules, agents, skills, Codex guidance, the permission model (deny and ask rules, environment flags) and the OMC config match the live setup of 2026-11-19. `config/claude.json.template` is an older example, not a copy of the live file.

**Read before installing.** These are one person's rules. `rules/orchestration.md` tells the session to reply in Korean and to serve the owner's main project; `rules/mcp-priority.md` gives commands for a self-hosted search stack with a placeholder address and an SSH alias. Change what does not fit you, or leave those two files out.

## How the setup works

| Who | Does what |
|-----|-----------|
| **Main Claude session** | Holds the owner's intent, splits the work, accepts or rejects results. Talks to the owner. |
| **Claude subagents (lanes)** | Investigation, critique and review that need Claude. Three lean lane types load no global rules; the brief carries the rules. |
| **Codex** | Default executor for implementation, tests and debugging: one task = one branch = one git worktree = one writer, started headless with `codex exec`. |
| **OMC plugin** | Base agents and workflow skills the rules refer to (plan, execute, review, verify and others). |

The judgement rules are in `rules/orchestration.md`; the recipes are in `skills/sol-dispatch/SKILL.md`. Most rules in `orchestration.md` name who decided them and on what evidence, so a rule can be dropped when its cause is gone.

```
claude-code-setup/
├── rules/                  # 6 global rules (loaded into every session)
├── agents/                 # 3 lean lane agents
├── skills/
│   ├── sol-dispatch/       # Codex dispatch, resume, record and verification recipes + report schemas
│   └── memory-write/       # rules for writing to the file-based memory
├── codex/
│   ├── AGENTS.md           # global guidance for Codex
│   ├── profiles/           # 9 model/effort profiles (codex -p <name>)
│   └── config.example.toml # shape of the permissions profile (example, not the live file)
├── config/
│   ├── settings.json       # permission model: deny and ask rules, environment flags
│   ├── claude-omc.config.jsonc
│   └── claude.json.template
├── scripts/                # two optional helper scripts (not wired to any hook)
└── install.sh
```

## Quick Start

```bash
# 1. Clone and install (existing files are backed up; an existing settings.json is left alone)
git clone https://github.com/YOUR_USERNAME/claude-code-setup.git
cd claude-code-setup
bash install.sh --dry-run   # preview
bash install.sh

# 2. Install the OMC plugin (in a Claude Code session)
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
```

Codex files are not installed by the script. Copy `codex/AGENTS.md` and `codex/profiles/*.config.toml` to `~/.codex/` yourself, and read `codex/config.example.toml` before changing your Codex permissions.

## What's Included

### Rules (6)

| Rule | Focus |
|------|-------|
| `orchestration.md` | When a turn may end, choosing a chain (Claude alone, Claude lanes, Codex), model and effort, verification, what counts as working or stalled, safety, tool facts. |
| `engineering.md` | Think before coding, simplicity first, surgical changes, goal-driven execution, testing by code tier. |
| `coding-style.md` | File organisation, error handling, language-specific notes. |
| `git-workflow.md` | Commit format, pull requests, review before merge, deploy by known commit. |
| `security.md` | Secrets, input validation, what to do when a security issue is found. |
| `mcp-priority.md` | Search and page-reading order: the lightest tool that gets the page; a self-hosted SearXNG + Crawl4AI stack. |

### Lane agents (3)

| Agent | Model | Purpose |
|-------|-------|---------|
| `lane-read` | Sonnet | Read-only measurement, recounts, searches, documentation lookup. Writes only its report. |
| `lane-review` | Opus | Separate approval pass: adversarial verification and critique of work someone else produced. |
| `lane-lead` | Sonnet | Coordinator: fans work out to sub-lanes (and Codex when the brief gives the recipe) and returns one reconciled report. |

All three set `omitClaudeMd: true`: they start without the global instruction files, so every brief names the rules the worker must follow.

### Skills (2)

| Skill | Purpose |
|-------|---------|
| `sol-dispatch` | Written in Korean. Headless `codex exec` templates, a pre-dispatch contract check, the one-writer-per-worktree liveness check, resume, a one-line dispatch record read from the Codex thread store, and JSON schemas for the final report and for reviews. |
| `memory-write` | Rewrite-not-append rules for the file-based memory and its index. |

### Codex

- `codex/AGENTS.md`: what the executor may and may not do when no sandbox encloses it: the contract is the task, boundaries, how to change code, secrets, the final message.
- `codex/profiles/`: `luna`, `high`, `xhigh`, `astra`, `ultra`, `max`, `fast`, `terra-max`, `terra-ultra`. Headless dispatches always name a profile, so that a model switch in an interactive session does not leak into them.
- `codex/config.example.toml`: the shape of the permissions profile: no work sandbox, network on, secret stores denied by path, policy files read-only. The live table is generated from lists of secret locations on one machine and is not published.

### Permissions (`config/settings.json`)

The file holds the permission model and four environment flags, nothing else: no allow list, model, plugins or status line (those are personal choices).

- **Deny** (88 rules): destructive commands, `sudo`, key and login stores, sixteen `.env` file names (templates such as `.env.example` stay readable), Codex and OMX flags that bypass approvals, `omc setup` / `omc install` (they overwrite hand-maintained config from a stale registry file).
- **Ask** (18 rules): `git push`, `docker`, and edits of settings, hooks, rules and Codex config files: these ask for confirmation instead of being refused.
- **Environment flags**: agent teams on, quiet OMC output, and the OMC "plan a /compact soon" warning switched off by setting both of its thresholds to 100.

The deny list also blocks OMC's own setup (`omc setup`, `omc install`, the `omc-setup` skill). The cause is specific to the owner's machine. If you are setting OMC up for the first time, run its setup before you add these rules, or leave those rules out.

Read rules cover the file tools. A shell command can still read a file, so the list also denies a few known shell routes to the key stores; beyond that, the guidance in the rules is what holds.

`install.sh` copies this file only when you have no `~/.claude/settings.json`. To add the rules to an existing file (your own values win for the environment flags):

```bash
jq -s '.[0] as $mine | .[1] as $ref | $mine
  | .env = (($ref.env // {}) + ($mine.env // {}))
  | .permissions.deny = ((($mine.permissions.deny // []) + $ref.permissions.deny) | unique)
  | .permissions.ask  = ((($mine.permissions.ask  // []) + $ref.permissions.ask)  | unique)' \
  ~/.claude/settings.json config/settings.json > settings.merged.json
# read settings.merged.json, then move it over ~/.claude/settings.json
```

### Hooks in the live setup (not shipped)

The live setup runs four hooks. Their scripts belong to a private tool, so `config/settings.json` here has no hook entries; the table describes what they do.

| Event | Hook | Function |
|-------|------|----------|
| SessionStart | memory nag | Speaks only when the memory index exceeds 180 lines or an automatic curation commit awaits the owner's veto. |
| SessionStart | lane verify | Checks the Codex permissions profile, the secret-store denies, the read-only paths, the environment exclusions and model/effort drift in the Codex thread store. |
| PreToolUse (`Task\|Agent`) | sol gate | Implementation work goes to Codex; a Claude fallback needs a marker with evidence that Codex really failed or that the owner said so. |
| PreToolUse (`Bash`) | dispatch gate | A headless `codex exec` must close standard input. |

Two things that were removed after measuring them: a tool-call counter that warned the main session to delegate (586 warnings, no confirmed shift to delegation), and a five-minute scheduled run of the verify hook (its desktop notifications led to no correction that the session-start check did not also report).

### Scripts

Two optional helpers that nothing here wires up: `scripts/hooks/ensure-coauthor.sh` blocks a `git commit` without a `Co-Authored-By` trailer when you register it as a PreToolUse hook, and `scripts/cleanup-team-panes.sh` closes leftover tmux panes of OMC tmux teams.

### OMC config

`config/claude-omc.config.jsonc` installs to `~/.config/claude-omc/config.jsonc`. It turns OMC's auto-update off, caps persistent loops at 200 iterations, restricts OMC's file tools to the project root, and disables the keyword triggers for `autopilot`, `ralph`, `ultrawork` and `ultragoal`: those modes run when the owner calls them, not because a phrase in a message happened to match.

### MCP servers

The live setup uses four servers: `c4ai-sse` (Crawl4AI through a stdio launcher), `playwright`, `cloudflare-docs` and `pencil`. `config/claude.json.template` is an older, broader example, not a copy of the live file.

## Not included

- The hook scripts and the generator of the Codex permissions table (private tool).
- `pr-script`, the PR hand-off script the rules and `sol-dispatch` refer to (private tool). It pushes only a `sol/` task
  branch of a private GitHub repository and opens or updates its PR, posts the `lane/gates`, `lane/review` and
  `lane/acceptance` commit statuses and review comments, merges only when those three are success, and after the merge
  deletes the task branch and cleans up the worktree; a `sweep` removes merged branches and worktrees from a reviewed plan.
- Third-party skills used in the live setup. Install them from their upstream repositories.
- The allow list, model choice, plugins and status line of the live settings.
- Personal research and publishing skills, and the memory content itself.

## Credits

Ideas from:
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills): the basis of `rules/engineering.md`, which quotes parts of it (its README states MIT)
- [claude-code-tips](https://github.com/ykdojo/claude-code-tips): ideas only; no upstream code is redistributed here (the upstream repository is All Rights Reserved)

## License

MIT
