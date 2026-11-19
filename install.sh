#!/usr/bin/env bash
set -euo pipefail

# Claude Code Setup Installer
# Copies configuration files to ~/.claude/ with backup support
# Works alongside the OMC (oh-my-claudecode) plugin. The Codex files in codex/ are not installed:
# copy them by hand (see README).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"
DRY_RUN=false
FORCE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --dry-run    Show what would be done without making changes"
  echo "  --force      Overwrite existing files without prompting"
  echo "  -h, --help   Show this help message"
  echo ""
  echo "This script installs Claude Code configuration files to ~/.claude/"
  echo "Existing files are backed up with a .backup.TIMESTAMP extension."
  echo "An existing settings.json is left as it is (see README, Permissions, for a merge command)."
  echo ""
  echo "For OMC (oh-my-claudecode) orchestration, install the plugin separately:"
  echo "  /plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode"
  echo "  /plugin install oh-my-claudecode"
}

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local backup="${file}.backup.${ts}"
    if $DRY_RUN; then
      info "Would backup: $file -> $backup"
    else
      cp "$file" "$backup"
      info "Backed up: $file -> $backup"
    fi
  fi
}

backup_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    local ts
    ts=$(date +%Y%m%d_%H%M%S)
    local backup="${dir}.backup.${ts}"
    if $DRY_RUN; then
      info "Would backup dir: $dir -> $backup"
    else
      cp -r "$dir" "$backup"
      info "Backed up dir: $dir -> $backup"
    fi
  fi
}

copy_dir() {
  local src="$1"
  local dest="$2"
  local name="$3"

  if $DRY_RUN; then
    local count
    count=$(find "$src" -type f | wc -l | tr -d ' ')
    log "Would copy $name ($count files): $src -> $dest"
    return
  fi

  mkdir -p "$dest"
  cp -r "$src"/* "$dest"/ 2>/dev/null || true
  local count
  count=$(find "$dest" -type f | wc -l | tr -d ' ')
  log "Copied $name ($count files)"
}

copy_file() {
  local src="$1"
  local dest="$2"
  local name="$3"

  if $DRY_RUN; then
    log "Would copy: $name -> $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  log "Copied $name"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

echo ""
echo "╔══════════════════════════════════════╗"
echo "║    Claude Code Setup Installer       ║"
echo "║    + OMC Plugin Integration          ║"
echo "╚══════════════════════════════════════╝"
echo ""

if $DRY_RUN; then
  warn "DRY RUN MODE — no changes will be made"
  echo ""
fi

# Check prerequisites
if ! command -v npx &>/dev/null; then
  warn "npx not found. MCP servers require npx."
fi

# Confirm installation
if ! $DRY_RUN && ! $FORCE; then
  echo "This will install Claude Code configuration to: $CLAUDE_DIR"
  echo "Existing files will be backed up; an existing settings.json is not replaced."
  echo ""
  read -rp "Continue? [y/N] " confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
fi

# Create base directory
if ! $DRY_RUN; then
  mkdir -p "$CLAUDE_DIR"
fi

# Step 1: Settings
log "Step 1/5: Core settings"
if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
  warn "settings.json exists: left as it is. To add the deny and ask rules, see README (Permissions)."
else
  copy_file "$SCRIPT_DIR/config/settings.json" "$CLAUDE_DIR/settings.json" "settings.json"
fi

# Step 1b: OMC granular security config
OMC_CONFIG_DIR="$HOME/.config/claude-omc"
backup_file "$OMC_CONFIG_DIR/config.jsonc"
if ! $DRY_RUN; then
  mkdir -p "$OMC_CONFIG_DIR"
fi
copy_file "$SCRIPT_DIR/config/claude-omc.config.jsonc" "$OMC_CONFIG_DIR/config.jsonc" "claude-omc config.jsonc"

# Step 2: Agents (lean lane agents; OMC provides its own agents via the plugin)
log "Step 2/5: Lane agent definitions"
if [[ -d "$CLAUDE_DIR/agents" ]]; then
  info "Existing agents dir found — merging custom agents only"
fi
if ! $DRY_RUN; then
  mkdir -p "$CLAUDE_DIR/agents"
fi
for agent_file in "$SCRIPT_DIR/agents"/*.md; do
  [[ -f "$agent_file" ]] || continue
  agent_name=$(basename "$agent_file")
  if [[ -f "$CLAUDE_DIR/agents/$agent_name" ]] && ! cmp -s "$agent_file" "$CLAUDE_DIR/agents/$agent_name"; then
    backup_file "$CLAUDE_DIR/agents/$agent_name"
  fi
  copy_file "$agent_file" "$CLAUDE_DIR/agents/$agent_name" "agent: $agent_name"
done

# Step 3: Rules
log "Step 3/5: Global rules"
backup_dir "$CLAUDE_DIR/rules"
copy_dir "$SCRIPT_DIR/rules" "$CLAUDE_DIR/rules" "rules"

# Step 4: Scripts
log "Step 4/5: Scripts"
backup_dir "$CLAUDE_DIR/scripts"
copy_dir "$SCRIPT_DIR/scripts" "$CLAUDE_DIR/scripts" "scripts"

# Set executable permissions on shell scripts
if ! $DRY_RUN; then
  find "$CLAUDE_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
  log "Set executable permissions on .sh files"
fi

# Step 5: Skills
log "Step 5/5: Skills"
if [[ -d "$CLAUDE_DIR/skills" ]]; then
  info "Existing skills dir found — merging custom skills only"
fi
if ! $DRY_RUN; then
  mkdir -p "$CLAUDE_DIR/skills"
fi
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name=$(basename "$skill_dir")
  if [[ -d "$CLAUDE_DIR/skills/$skill_name" ]] && ! diff -rq "$skill_dir" "$CLAUDE_DIR/skills/$skill_name" >/dev/null 2>&1; then
    # The old copy goes outside skills/: a folder left there would load as a second skill.
    skill_backup="$CLAUDE_DIR/skills.backup.$(date +%Y%m%d_%H%M%S)"
    if $DRY_RUN; then
      info "Would backup skill: $skill_name -> $skill_backup/"
    else
      mkdir -p "$skill_backup"
      cp -r "$CLAUDE_DIR/skills/$skill_name" "$skill_backup/"
      info "Backed up skill: $skill_name -> $skill_backup/"
    fi
  fi
  if ! $DRY_RUN; then
    mkdir -p "$CLAUDE_DIR/skills/$skill_name"
    cp -r "$skill_dir"* "$CLAUDE_DIR/skills/$skill_name/" 2>/dev/null || true
  fi
  log "Installed skill: $skill_name"
done

echo ""
echo "════════════════════════════════════════"
echo ""
log "Installation complete!"
echo ""

# Summary
if ! $DRY_RUN; then
  echo "Installed to: $CLAUDE_DIR"
  echo ""
  echo "  Agents:    $(find "$CLAUDE_DIR/agents" -name "*.md" | wc -l | tr -d ' ') files"
  echo "  Rules:     $(find "$CLAUDE_DIR/rules" -name "*.md" | wc -l | tr -d ' ') files"
  echo "  OMC config: $OMC_CONFIG_DIR/config.jsonc"
  echo "  Scripts:   $(find "$CLAUDE_DIR/scripts" -type f | wc -l | tr -d ' ') files"
  echo "  Skills:    $(find "$CLAUDE_DIR/skills" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ') packages"
fi

echo ""
warn "Post-install checklist:"
echo ""
echo "  0. The rules were written for one owner. Read ~/.claude/rules/orchestration.md and"
echo "     mcp-priority.md and change what does not fit you: the reply language, the project"
echo "     line, and the search host (the placeholder <tailscale-ip>, the ssh alias)."
echo ""
echo "  1. OMC Plugin (base agents and skills the rules refer to):"
echo "     In a Claude Code session, run:"
echo "       /plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode"
echo "       /plugin install oh-my-claudecode"
echo ""
echo "  2. MCP Servers — Edit ~/.claude.json using config/claude.json.template"
echo "     - Set FIRECRAWL_API_KEY (or remove firecrawl server)"
echo "     - Set filesystem path to your projects directory"
echo "     - Run: gh auth login (for GitHub Copilot MCP)"
echo ""
echo "  3. Docker services (optional):"
echo "     docker run -d --name crawl4ai --restart unless-stopped -p 127.0.0.1:11235:11235 --shm-size=1g unclecode/crawl4ai:latest"
echo "     docker run -d --name searxng --restart unless-stopped -p 127.0.0.1:8888:8080 searxng/searxng:latest"
echo ""
echo "  4. Codex (optional): copy codex/AGENTS.md and codex/profiles/*.config.toml to ~/.codex/,"
echo "     and use codex/config.example.toml as a guide for the permissions profile."
echo ""
echo "  5. Restart Claude Code to load all configurations"
echo ""
